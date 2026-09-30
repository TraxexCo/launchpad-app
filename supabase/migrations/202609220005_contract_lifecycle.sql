-- Match the awarded-job and contract requirements without losing existing rows.
alter type public.job_status rename value 'contracted' to 'in_progress';
alter publication supabase_realtime add table public.proposals;

alter table public.contracts
  add column job_id bigint references public.jobs(id),
  add column business_id uuid references public.business_profiles(user_id),
  add column student_id uuid references public.student_profiles(user_id),
  add column agreed_budget numeric(12,2) check (agreed_budget > 0),
  add column agreed_timeline_weeks integer check (agreed_timeline_weeks > 0);

update public.contracts c set
  job_id = p.job_id,
  business_id = j.business_id,
  student_id = p.student_id,
  agreed_budget = p.proposed_budget,
  agreed_timeline_weeks = p.estimated_timeline_weeks
from public.proposals p join public.jobs j on j.id = p.job_id
where c.proposal_id = p.id;

alter table public.contracts
  alter column job_id set not null,
  alter column business_id set not null,
  alter column student_id set not null,
  alter column agreed_budget set not null,
  alter column agreed_timeline_weeks set not null;
create unique index contracts_one_per_job on public.contracts(job_id);
alter table public.proposals drop constraint proposals_job_id_fkey;
alter table public.proposals add constraint proposals_job_id_fkey
  foreign key (job_id) references public.jobs(id) on delete cascade;

-- Contract terms are a snapshot. Client roles cannot update these columns.
create table public.conversations (
  id bigint generated always as identity primary key,
  contract_id bigint not null unique references public.contracts(id) on delete cascade,
  created_at timestamptz not null default now()
);
insert into public.conversations(contract_id)
  select id from public.contracts;
alter table public.conversations enable row level security;
revoke all on public.conversations from anon, authenticated;
grant select on public.conversations to authenticated;
create policy conversations_read on public.conversations for select to authenticated
  using (private.participates_in_contract(contract_id));

-- SECURITY DEFINER is required because the client cannot update proposal/job
-- status or insert binding contracts and conversations directly.
create or replace function private.accept_proposal_impl(proposal_key bigint)
returns bigint language plpgsql security definer set search_path = '' as $$
declare target public.proposals%rowtype;
declare owner_id uuid;
declare contract_key bigint;
begin
  if not exists (select 1 from public.business_profiles
      where user_id = (select auth.uid())) then
    raise exception 'Only business accounts can accept proposals';
  end if;
  select p.* into target from public.proposals p where p.id = proposal_key;
  if not found then raise exception 'Proposal not found'; end if;
  select j.business_id into owner_id from public.jobs j
    where j.id = target.job_id for update;
  if owner_id is distinct from (select auth.uid()) then
    raise exception 'Not authorized to manage this job';
  end if;
  if target.status <> 'pending' or not exists
      (select 1 from public.jobs where id = target.job_id and status = 'open') then
    raise exception 'Job is no longer open for acceptance';
  end if;
  update public.proposals set status = 'rejected'
    where job_id = target.job_id and id <> proposal_key and status = 'pending';
  update public.proposals set status = 'accepted' where id = proposal_key;
  update public.jobs set status = 'in_progress' where id = target.job_id;
  insert into public.contracts(
    proposal_id, job_id, business_id, student_id,
    agreed_budget, agreed_timeline_weeks
  ) values (
    proposal_key, target.job_id, owner_id, target.student_id,
    target.proposed_budget, target.estimated_timeline_weeks
  ) returning id into contract_key;
  insert into public.conversations(contract_id) values (contract_key);
  return contract_key;
end; $$;

-- Return stable, human-readable errors even when a job closes while the
-- student is writing. Locking the job serializes submission with acceptance.
create or replace function public.submit_proposal(
  job_id bigint, pitch_text text, proposed_budget numeric,
  estimated_timeline_weeks integer, attached_project_id bigint default null
) returns bigint language plpgsql security definer set search_path = '' as $$
declare job_state public.job_status;
declare result_id bigint;
begin
  if not exists (select 1 from public.student_profiles
      where user_id = (select auth.uid())) then
    raise exception 'Only student accounts can submit proposals';
  end if;
  select j.status into job_state from public.jobs j where j.id = job_id for update;
  if job_state is distinct from 'open' then
    raise exception 'This job is no longer accepting proposals';
  end if;
  if attached_project_id is not null and not exists (
    select 1 from public.portfolio_projects p
    where p.id = attached_project_id and p.student_id = (select auth.uid())
  ) then
    raise exception 'Choose one of your own portfolio projects';
  end if;
  insert into public.proposals(
    job_id, student_id, pitch_text, proposed_budget,
    estimated_timeline_weeks, attached_project_id
  ) values (
    job_id, (select auth.uid()), pitch_text, proposed_budget,
    estimated_timeline_weeks, attached_project_id
  ) returning id into result_id;
  return result_id;
exception when unique_violation then
  raise exception 'You have already submitted a proposal for this job';
end; $$;
revoke execute on function public.submit_proposal(bigint,text,numeric,integer,bigint)
  from public, anon;
grant execute on function public.submit_proposal(bigint,text,numeric,integer,bigint)
  to authenticated;

-- A direct RLS-filtered DELETE affects zero rows for a foreign job. This RPC
-- gives callers the explicit permission error required by the app workflow.
create or replace function public.delete_job(job_id bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare owner_id uuid;
declare job_state public.job_status;
begin
  select business_id, status into owner_id, job_state
    from public.jobs where id = job_id for update;
  if not found then raise exception 'Job not found'; end if;
  if owner_id is distinct from (select auth.uid()) then
    raise insufficient_privilege using message = 'Not authorized to delete this job';
  end if;
  if job_state <> 'open' then
    raise exception 'Only open jobs can be deleted';
  end if;
  delete from public.jobs j where j.id = delete_job.job_id;
end; $$;
revoke execute on function public.delete_job(bigint) from public, anon;
grant execute on function public.delete_job(bigint) to authenticated;

-- Preserve the additional student fields supplied during registration.
create or replace function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare selected_role public.user_role;
begin
  if new.raw_user_meta_data ->> 'role' not in ('student', 'business') then
    raise exception 'A valid student or business role is required';
  end if;
  selected_role := (new.raw_user_meta_data ->> 'role')::public.user_role;
  insert into public.profiles(id, role, full_name)
  values (new.id, selected_role,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), 'LaunchPad User'));
  if selected_role = 'student' then
    insert into public.student_profiles(user_id, school, course, bio, github_username)
    values (new.id,
      new.raw_user_meta_data ->> 'school',
      new.raw_user_meta_data ->> 'course',
      new.raw_user_meta_data ->> 'bio',
      new.raw_user_meta_data ->> 'github_username');
  else
    insert into public.business_profiles(user_id, business_name, address)
    values (new.id,
      coalesce(nullif(trim(new.raw_user_meta_data ->> 'business_name'), ''), 'Unnamed Business'),
      new.raw_user_meta_data ->> 'address');
  end if;
  return new;
end; $$;
