-- Complete contract workspace: lifecycle, deliverables, revision history and disputes.
-- Apply after 202610110010_paymongo_payments.sql.

-- Rebuild the enum in one migration so the new values can be used immediately.
alter table public.contracts alter column status drop default;
alter table public.contracts alter column status type text using status::text;
update public.contracts set status = 'submitted' where status = 'completion_requested';
drop type public.contract_status;
create type public.contract_status as enum (
  'funded', 'in_progress', 'submitted', 'revision_requested',
  'completed', 'cancelled', 'disputed'
);
alter table public.contracts alter column status type public.contract_status
  using status::public.contract_status;
alter table public.contracts alter column status set default 'in_progress';

alter table public.contracts
  add column funded_at timestamptz,
  add column started_at timestamptz,
  add column cancelled_at timestamptz,
  add column cancelled_by uuid references public.profiles(id),
  add column cancellation_reason text,
  add column disputed_at timestamptz,
  add column disputed_by uuid references public.profiles(id),
  add column dispute_reason text,
  add column revision_message text;

-- Existing paid projects are already active; unpaid projects keep their old state
-- until PayMongo confirms funding.
update public.contracts c set funded_at = coalesce(p.paid_at, p.created_at),
  started_at = c.agreed_at
from public.payments p
where p.contract_id = c.id and p.status in ('paid', 'released');

create table public.contract_deliverables (
  id bigint generated always as identity primary key,
  contract_id bigint not null references public.contracts(id) on delete cascade,
  submitted_by uuid not null references public.profiles(id),
  submission_number integer not null check (submission_number > 0),
  title text not null check (char_length(trim(title)) between 2 and 120),
  summary text not null check (char_length(trim(summary)) between 10 and 2000),
  link_url text,
  storage_path text,
  original_file_name text,
  created_at timestamptz not null default now(),
  unique(contract_id, submission_number),
  check (link_url is not null or storage_path is not null)
);

create table public.contract_events (
  id bigint generated always as identity primary key,
  contract_id bigint not null references public.contracts(id) on delete cascade,
  actor_id uuid references public.profiles(id),
  event_type text not null check (event_type in (
    'funded', 'started', 'submitted', 'revision_requested',
    'completed', 'cancelled', 'disputed'
  )),
  message text,
  created_at timestamptz not null default now()
);

create index contract_deliverables_history_idx
  on public.contract_deliverables(contract_id, submission_number desc);
create index contract_events_history_idx
  on public.contract_events(contract_id, created_at desc);

alter table public.contract_deliverables enable row level security;
alter table public.contract_events enable row level security;
revoke all on public.contract_deliverables, public.contract_events from anon, authenticated;
grant select on public.contract_deliverables, public.contract_events to authenticated;
create policy contract_deliverables_participant_read on public.contract_deliverables
  for select to authenticated using (private.participates_in_contract(contract_id));
create policy contract_events_participant_read on public.contract_events
  for select to authenticated using (private.participates_in_contract(contract_id));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('contract-deliverables', 'contract-deliverables', false, 10485760,
  array['application/pdf','application/zip','image/jpeg','image/png','text/plain'])
on conflict (id) do update set public = false, file_size_limit = 10485760,
  allowed_mime_types = excluded.allowed_mime_types;

create policy contract_files_participant_read on storage.objects
  for select to authenticated using (
    bucket_id = 'contract-deliverables'
    and (storage.foldername(name))[1] ~ '^[0-9]+$'
    and private.participates_in_contract(((storage.foldername(name))[1])::bigint)
  );
create policy contract_files_student_upload on storage.objects
  for insert to authenticated with check (
    bucket_id = 'contract-deliverables'
    and (storage.foldername(name))[1] ~ '^[0-9]+$'
    and (storage.foldername(name))[2] = (select auth.uid())::text
    and exists (
      select 1 from public.contracts c
      where c.id = ((storage.foldername(name))[1])::bigint
        and c.student_id = (select auth.uid())
        and c.status in ('in_progress', 'revision_requested')
    )
  );

create or replace function public.mark_contract_funded(contract_key bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
begin
  if (select auth.role()) <> 'service_role' then
    raise insufficient_privilege using message = 'Service role required';
  end if;
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found then raise exception 'Contract not found'; end if;
  if not exists (select 1 from public.payments p where p.contract_id = contract_key and p.status in ('paid','released')) then
    raise exception 'Confirmed payment required';
  end if;
  if target.status = 'in_progress' and target.started_at is null then
    update public.contracts set status = 'funded', funded_at = coalesce(funded_at, now()) where id = contract_key;
    insert into public.contract_events(contract_id, event_type, message)
      values (contract_key, 'funded', 'PayMongo test payment confirmed.');
  elsif target.funded_at is null then
    update public.contracts set funded_at = now() where id = contract_key;
  end if;
end; $$;
revoke execute on function public.mark_contract_funded(bigint) from public, anon, authenticated;
grant execute on function public.mark_contract_funded(bigint) to service_role;

create or replace function public.start_contract_work(contract_key bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
begin
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found then raise exception 'Contract not found'; end if;
  if target.student_id is distinct from (select auth.uid()) then
    raise insufficient_privilege using message = 'Only the assigned student can start this project';
  end if;
  if target.status <> 'funded' then raise exception 'The project must be funded before work starts'; end if;
  update public.contracts set status = 'in_progress', started_at = now() where id = contract_key;
  insert into public.contract_events(contract_id, actor_id, event_type, message)
    values (contract_key, (select auth.uid()), 'started', 'Student started project work.');
  insert into public.notifications(user_id, title, body, route, kind)
    values (target.business_id, 'Project Work Started', 'The student started work on your funded project.',
      '/contract/' || contract_key, 'proposals');
end; $$;
revoke execute on function public.start_contract_work(bigint) from public, anon;
grant execute on function public.start_contract_work(bigint) to authenticated;

create or replace function public.submit_contract_deliverable(
  contract_key bigint, deliverable_title text, deliverable_summary text,
  deliverable_link text default null, deliverable_storage_path text default null,
  deliverable_file_name text default null
) returns bigint language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
declare next_number integer;
declare result_id bigint;
begin
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found then raise exception 'Contract not found'; end if;
  if target.student_id is distinct from (select auth.uid()) then
    raise insufficient_privilege using message = 'Only the assigned student can submit work';
  end if;
  if target.status not in ('in_progress','revision_requested') then
    raise exception 'Work can only be submitted while active or under revision';
  end if;
  if not exists (select 1 from public.payments p where p.contract_id = contract_key and p.status in ('paid','released')) then
    raise exception 'The project must be funded before work is submitted';
  end if;
  if char_length(trim(coalesce(deliverable_title,''))) < 2 then raise exception 'Add a deliverable title'; end if;
  if char_length(trim(coalesce(deliverable_summary,''))) < 10 then raise exception 'Describe the submitted work'; end if;
  if nullif(trim(coalesce(deliverable_link,'')), '') is null and
     nullif(trim(coalesce(deliverable_storage_path,'')), '') is null then
    raise exception 'Attach a file or add a link';
  end if;
  select coalesce(max(d.submission_number),0) + 1 into next_number
    from public.contract_deliverables d where d.contract_id = contract_key;
  insert into public.contract_deliverables(
    contract_id, submitted_by, submission_number, title, summary,
    link_url, storage_path, original_file_name
  ) values (
    contract_key, (select auth.uid()), next_number, trim(deliverable_title), trim(deliverable_summary),
    nullif(trim(coalesce(deliverable_link,'')),''), nullif(trim(coalesce(deliverable_storage_path,'')),''),
    nullif(trim(coalesce(deliverable_file_name,'')),'')
  ) returning id into result_id;
  update public.contracts set status = 'submitted', completion_requested_at = now(),
    completion_requested_by = (select auth.uid()), revision_message = null where id = contract_key;
  insert into public.contract_events(contract_id, actor_id, event_type, message)
    values (contract_key, (select auth.uid()), 'submitted', 'Submission #' || next_number || ': ' || trim(deliverable_title));
  insert into public.notifications(user_id, title, body, route, kind)
    values (target.business_id, 'Deliverable Submitted',
      'Submission #' || next_number || ' is ready for review.', '/contract/' || contract_key, 'proposals');
  return result_id;
end; $$;
revoke execute on function public.submit_contract_deliverable(bigint,text,text,text,text,text) from public, anon;
grant execute on function public.submit_contract_deliverable(bigint,text,text,text,text,text) to authenticated;

create or replace function public.respond_contract_completion(
  contract_key bigint, approve_completion boolean, revision_note text default null
) returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
declare project_title text;
begin
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found then raise exception 'Contract not found'; end if;
  if target.business_id is distinct from (select auth.uid()) then
    raise insufficient_privilege using message = 'Only the hiring business can review the submission';
  end if;
  if target.status <> 'submitted' then raise exception 'This contract has no submission awaiting review'; end if;
  select j.title into project_title from public.jobs j where j.id = target.job_id;
  if approve_completion then
    update public.contracts set status = 'completed', completed_at = now(), revision_message = null where id = contract_key;
    update public.jobs set status = 'closed' where id = target.job_id;
    update public.payments set status = 'released', released_at = now(), updated_at = now()
      where contract_id = contract_key and status = 'paid';
    insert into public.contract_events(contract_id, actor_id, event_type, message)
      values (contract_key, (select auth.uid()), 'completed', 'Business approved the final submission.');
    insert into public.notifications(user_id, title, body, route, kind)
      values (target.student_id, 'Project Completed & Payment Released',
        coalesce(project_title,'Your project') || ' was approved.', '/contract/' || contract_key, 'proposals');
  else
    if char_length(trim(coalesce(revision_note,''))) < 5 then raise exception 'Explain the requested revision'; end if;
    update public.contracts set status = 'revision_requested', revision_message = trim(revision_note) where id = contract_key;
    insert into public.contract_events(contract_id, actor_id, event_type, message)
      values (contract_key, (select auth.uid()), 'revision_requested', trim(revision_note));
    insert into public.notifications(user_id, title, body, route, kind)
      values (target.student_id, 'Revision Requested', trim(revision_note), '/contract/' || contract_key, 'proposals');
  end if;
end; $$;
revoke execute on function public.respond_contract_completion(bigint,boolean,text) from public, anon;
grant execute on function public.respond_contract_completion(bigint,boolean,text) to authenticated;

drop function if exists public.respond_contract_completion(bigint,boolean);
drop function if exists public.request_contract_completion(bigint);

create or replace function public.cancel_contract(contract_key bigint, reason_text text)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
declare recipient uuid;
begin
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found then raise exception 'Contract not found'; end if;
  if (select auth.uid()) not in (target.student_id, target.business_id) then
    raise insufficient_privilege using message = 'Only project participants can cancel';
  end if;
  if target.status in ('completed','cancelled','disputed') then raise exception 'This contract cannot be cancelled'; end if;
  if char_length(trim(coalesce(reason_text,''))) < 10 then raise exception 'Give a cancellation reason of at least 10 characters'; end if;
  if exists (select 1 from public.payments p where p.contract_id = contract_key and p.status in ('paid','released')) then
    raise exception 'A funded project must be disputed so an administrator can review the payment';
  end if;
  recipient := case when (select auth.uid()) = target.student_id then target.business_id else target.student_id end;
  update public.contracts set status = 'cancelled', cancelled_at = now(), cancelled_by = (select auth.uid()),
    cancellation_reason = trim(reason_text) where id = contract_key;
  insert into public.contract_events(contract_id, actor_id, event_type, message)
    values (contract_key, (select auth.uid()), 'cancelled', trim(reason_text));
  insert into public.notifications(user_id, title, body, route, kind)
    values (recipient, 'Contract Cancelled', trim(reason_text), '/contract/' || contract_key, 'proposals');
end; $$;
revoke execute on function public.cancel_contract(bigint,text) from public, anon;
grant execute on function public.cancel_contract(bigint,text) to authenticated;

create or replace function public.open_contract_dispute(contract_key bigint, reason_text text)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
declare recipient uuid;
begin
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found then raise exception 'Contract not found'; end if;
  if (select auth.uid()) not in (target.student_id, target.business_id) then
    raise insufficient_privilege using message = 'Only project participants can open a dispute';
  end if;
  if target.status in ('completed','cancelled','disputed') then raise exception 'This contract cannot be disputed'; end if;
  if char_length(trim(coalesce(reason_text,''))) < 20 then raise exception 'Describe the dispute in at least 20 characters'; end if;
  recipient := case when (select auth.uid()) = target.student_id then target.business_id else target.student_id end;
  update public.contracts set status = 'disputed', disputed_at = now(), disputed_by = (select auth.uid()),
    dispute_reason = trim(reason_text) where id = contract_key;
  insert into public.contract_events(contract_id, actor_id, event_type, message)
    values (contract_key, (select auth.uid()), 'disputed', trim(reason_text));
  insert into public.notifications(user_id, title, body, route, kind)
    values (recipient, 'Contract Disputed', 'A dispute was opened for this project.', '/contract/' || contract_key, 'proposals');
end; $$;
revoke execute on function public.open_contract_dispute(bigint,text) from public, anon;
grant execute on function public.open_contract_dispute(bigint,text) to authenticated;

-- Private identity documents. Users can submit and read only their own files;
-- review access will be granted to the admin role in the moderation migration.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('verification-documents', 'verification-documents', false, 5242880,
  array['application/pdf','image/jpeg','image/png'])
on conflict (id) do update set public = false, file_size_limit = 5242880,
  allowed_mime_types = excluded.allowed_mime_types;

grant select on public.verification_documents to authenticated;
create policy verification_owner_read on public.verification_documents
  for select to authenticated using (owner_id = (select auth.uid()));
create policy verification_files_owner_read on storage.objects
  for select to authenticated using (
    bucket_id = 'verification-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy verification_files_owner_upload on storage.objects
  for insert to authenticated with check (
    bucket_id = 'verification-documents'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create or replace function public.submit_verification_document(document_kind text, file_path text)
returns bigint language plpgsql security definer set search_path = '' as $$
declare selected_role public.user_role;
declare result_id bigint;
begin
  select p.role into selected_role from public.profiles p where p.id = (select auth.uid());
  if selected_role is null then raise exception 'Profile not found'; end if;
  if selected_role = 'student' and document_kind not in ('student_id','enrollment') then
    raise exception 'Choose a student identity document';
  end if;
  if selected_role = 'business' and document_kind not in ('business_permit','storefront') then
    raise exception 'Choose a business verification document';
  end if;
  if file_path not like ((select auth.uid())::text || '/%') then
    raise insufficient_privilege using message = 'Invalid verification file path';
  end if;
  update public.verification_documents set status = 'rejected'
    where owner_id = (select auth.uid()) and status = 'pending';
  insert into public.verification_documents(owner_id, document_type, storage_path)
    values ((select auth.uid()), document_kind, file_path) returning id into result_id;
  if selected_role = 'business' then
    update public.business_profiles set verification_status = 'pending'
      where user_id = (select auth.uid());
  end if;
  return result_id;
end; $$;
revoke execute on function public.submit_verification_document(text,text) from public, anon;
grant execute on function public.submit_verification_document(text,text) to authenticated;

alter publication supabase_realtime add table public.contract_deliverables;
alter publication supabase_realtime add table public.contract_events;
