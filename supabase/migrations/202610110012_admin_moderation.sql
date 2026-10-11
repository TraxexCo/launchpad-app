-- Web-only administration and moderation controls.
-- Apply after 202610110011_contract_workspace.sql.

create table public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
revoke all on public.admin_users from anon, authenticated;
grant select on public.admin_users to authenticated;
create policy admin_users_read_self on public.admin_users for select to authenticated
  using (user_id = (select auth.uid()));

create or replace function private.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.admin_users a where a.user_id = (select auth.uid()))
$$;
grant execute on function private.is_admin() to authenticated;

alter table public.profiles
  add column suspended_at timestamptz,
  add column suspension_reason text;
alter table public.verification_documents
  add column reviewed_at timestamptz,
  add column reviewed_by uuid references auth.users(id),
  add column review_note text;
alter table public.reports
  add column resolved_at timestamptz,
  add column resolved_by uuid references auth.users(id),
  add column resolution_note text;
alter table public.contracts
  add column dispute_resolved_at timestamptz,
  add column dispute_resolved_by uuid references auth.users(id),
  add column dispute_resolution text;

create policy contracts_admin_read on public.contracts for select to authenticated
  using (private.is_admin());
create policy deliverables_admin_read on public.contract_deliverables for select to authenticated
  using (private.is_admin());
create policy events_admin_read on public.contract_events for select to authenticated
  using (private.is_admin());
create policy reports_admin_read on public.reports for select to authenticated
  using (private.is_admin());
create policy verification_admin_read on public.verification_documents for select to authenticated
  using (private.is_admin());
create policy payments_admin_read on public.payments for select to authenticated
  using (private.is_admin());
create policy jobs_admin_read on public.jobs for select to authenticated
  using (private.is_admin());
create policy verification_files_admin_read on storage.objects for select to authenticated
  using (bucket_id = 'verification-documents' and private.is_admin());

create or replace function public.admin_review_verification(
  document_key bigint, approve_document boolean, note_text text default null
) returns void language plpgsql security definer set search_path = '' as $$
declare target public.verification_documents%rowtype;
declare owner_role public.user_role;
begin
  if not private.is_admin() then raise insufficient_privilege using message = 'Administrator access required'; end if;
  select * into target from public.verification_documents d where d.id = document_key for update;
  if not found then raise exception 'Verification document not found'; end if;
  update public.verification_documents set
    status = case when approve_document then 'verified'::public.verification_status else 'rejected'::public.verification_status end,
    reviewed_at = now(), reviewed_by = (select auth.uid()), review_note = nullif(trim(coalesce(note_text,'')),'')
  where id = document_key;
  select role into owner_role from public.profiles where id = target.owner_id;
  if owner_role = 'business' then
    update public.business_profiles set verification_status =
      case when approve_document then 'verified'::public.verification_status else 'rejected'::public.verification_status end
      where user_id = target.owner_id;
  end if;
  insert into public.notifications(user_id,title,body,route,kind) values (
    target.owner_id,
    case when approve_document then 'Verification Approved' else 'Verification Needs Attention' end,
    case when approve_document then 'Your identity document was approved.' else coalesce(nullif(trim(note_text),''),'Please submit a clearer or valid document.') end,
    '/verification?role=' || owner_role::text, 'general'
  );
end; $$;

create or replace function public.admin_resolve_report(
  report_key bigint, resolution_status text, note_text text
) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_admin() then raise insufficient_privilege using message = 'Administrator access required'; end if;
  if resolution_status not in ('reviewing','resolved','dismissed') then raise exception 'Invalid report decision'; end if;
  update public.reports set status = resolution_status,
    resolved_at = case when resolution_status in ('resolved','dismissed') then now() else null end,
    resolved_by = (select auth.uid()), resolution_note = nullif(trim(note_text),'')
  where id = report_key;
  if not found then raise exception 'Report not found'; end if;
end; $$;

create or replace function public.admin_set_user_suspension(
  target_user uuid, suspend_user boolean, reason_text text default null
) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_admin() then raise insufficient_privilege using message = 'Administrator access required'; end if;
  if target_user = (select auth.uid()) then raise exception 'You cannot suspend your own admin account'; end if;
  if suspend_user and char_length(trim(coalesce(reason_text,''))) < 10 then raise exception 'Add a clear suspension reason'; end if;
  update public.profiles set suspended_at = case when suspend_user then now() else null end,
    suspension_reason = case when suspend_user then trim(reason_text) else null end
  where id = target_user;
  if not found then raise exception 'User not found'; end if;
end; $$;

create or replace function public.admin_resolve_dispute(
  contract_key bigint, decision text, note_text text
) returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
begin
  if not private.is_admin() then raise insufficient_privilege using message = 'Administrator access required'; end if;
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found or target.status <> 'disputed' then raise exception 'Open dispute not found'; end if;
  if decision not in ('resume','cancel','refund') then raise exception 'Invalid dispute decision'; end if;
  if char_length(trim(coalesce(note_text,''))) < 10 then raise exception 'Add a resolution note'; end if;
  update public.contracts set
    status = case when decision = 'resume' then 'in_progress'::public.contract_status else 'cancelled'::public.contract_status end,
    cancelled_at = case when decision in ('cancel','refund') then now() else cancelled_at end,
    cancellation_reason = case when decision in ('cancel','refund') then trim(note_text) else cancellation_reason end,
    dispute_resolved_at = now(), dispute_resolved_by = (select auth.uid()), dispute_resolution = trim(note_text)
  where id = contract_key;
  if decision = 'refund' then
    update public.payments set status = 'refunded', updated_at = now() where contract_id = contract_key and status = 'paid';
  end if;
  insert into public.notifications(user_id,title,body,route,kind) values
    (target.student_id, 'Dispute Resolved', trim(note_text), '/contract/' || contract_key, 'proposals'),
    (target.business_id, 'Dispute Resolved', trim(note_text), '/contract/' || contract_key, 'proposals');
end; $$;

revoke execute on function public.admin_review_verification(bigint,boolean,text),
  public.admin_resolve_report(bigint,text,text),
  public.admin_set_user_suspension(uuid,boolean,text),
  public.admin_resolve_dispute(bigint,text,text) from public, anon;
grant execute on function public.admin_review_verification(bigint,boolean,text),
  public.admin_resolve_report(bigint,text,text),
  public.admin_set_user_suspension(uuid,boolean,text),
  public.admin_resolve_dispute(bigint,text,text) to authenticated;

-- Authentication is blocked in the app after profile lookup when suspended.
-- Add the first administrator manually with:
-- insert into public.admin_users(user_id) values ('AUTH-USER-UUID');
