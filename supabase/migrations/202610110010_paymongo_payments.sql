-- PayMongo-backed classroom payments for accepted project contracts.
-- Apply after 202610050009_location_and_notification_preferences.sql.

create table public.payments (
  id bigint generated always as identity primary key,
  contract_id bigint not null unique references public.contracts(id) on delete cascade,
  business_id uuid not null references public.business_profiles(user_id),
  student_id uuid not null references public.student_profiles(user_id),
  provider text not null default 'paymongo' check (provider = 'paymongo'),
  amount numeric(12,2) not null check (amount > 0),
  currency text not null default 'PHP' check (currency = 'PHP'),
  status text not null default 'unpaid' check (
    status in ('unpaid', 'checkout_created', 'paid', 'released', 'failed', 'expired', 'refunded')
  ),
  checkout_session_id text unique,
  checkout_url text,
  provider_payment_id text,
  reference_number text not null unique,
  payment_method text,
  paid_at timestamptz,
  released_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index payments_business_idx on public.payments(business_id, created_at desc);
create index payments_student_idx on public.payments(student_id, created_at desc);
alter table public.payments enable row level security;
revoke all on public.payments from anon, authenticated;
grant select on public.payments to authenticated;

create policy payments_participant_read on public.payments
  for select to authenticated
  using (
    business_id = (select auth.uid()) or student_id = (select auth.uid())
  );

alter publication supabase_realtime add table public.payments;

-- Students may only submit funded work. This makes payment part of the
-- existing contract lifecycle without changing the contract status enum.
create or replace function public.request_contract_completion(contract_key bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
declare project_title text;
begin
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found then raise exception 'Contract not found'; end if;
  if target.student_id is distinct from (select auth.uid()) then
    raise insufficient_privilege using message = 'Only the assigned student can request completion';
  end if;
  if target.status <> 'in_progress' then
    raise exception 'Only an in-progress contract can be submitted for completion';
  end if;
  if not exists (
    select 1 from public.payments p
    where p.contract_id = contract_key and p.status in ('paid', 'released')
  ) then
    raise exception 'The project must be funded before work can be submitted';
  end if;
  update public.contracts set status = 'completion_requested',
    completion_requested_at = now(), completion_requested_by = (select auth.uid())
    where id = contract_key;
  select j.title into project_title from public.jobs j where j.id = target.job_id;
  insert into public.notifications(user_id, title, body, route, kind)
  values (target.business_id, 'Completion Requested',
    'The student submitted ' || coalesce(project_title, 'your project') || ' for approval.',
    '/chat/' || target.proposal_id, 'proposals');
end; $$;
revoke execute on function public.request_contract_completion(bigint) from public, anon;
grant execute on function public.request_contract_completion(bigint) to authenticated;

-- Business approval completes the contract and records the classroom payout
-- release. PayMongo processes the incoming test payment; no live payout occurs.
create or replace function public.respond_contract_completion(contract_key bigint, approve_completion boolean)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
declare project_title text;
begin
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found then raise exception 'Contract not found'; end if;
  if target.business_id is distinct from (select auth.uid()) then
    raise insufficient_privilege using message = 'Only the hiring business can review completion';
  end if;
  if target.status <> 'completion_requested' then
    raise exception 'This contract is not awaiting completion approval';
  end if;
  if approve_completion is null then raise exception 'An approval decision is required'; end if;
  select j.title into project_title from public.jobs j where j.id = target.job_id;
  if approve_completion then
    if not exists (
      select 1 from public.payments p
      where p.contract_id = contract_key and p.status in ('paid', 'released')
    ) then
      raise exception 'A paid project payment is required before completion';
    end if;
    update public.contracts set status = 'completed', completed_at = now()
      where id = contract_key;
    update public.jobs set status = 'closed' where id = target.job_id;
    update public.payments set status = 'released', released_at = now(), updated_at = now()
      where contract_id = contract_key and status = 'paid';
    insert into public.notifications(user_id, title, body, route, kind)
    values (target.student_id, 'Project Completed & Payment Released',
      coalesce(project_title, 'Your project') || ' was approved. The classroom payment is marked released.',
      '/chat/' || target.proposal_id, 'proposals');
  else
    update public.contracts set status = 'in_progress',
      completion_requested_at = null, completion_requested_by = null
      where id = contract_key;
    insert into public.notifications(user_id, title, body, route, kind)
    values (target.student_id, 'Changes Requested',
      'The business requested more work on ' || coalesce(project_title, 'your project') || '. Check the project chat.',
      '/chat/' || target.proposal_id, 'proposals');
  end if;
end; $$;
revoke execute on function public.respond_contract_completion(bigint,boolean) from public, anon;
grant execute on function public.respond_contract_completion(bigint,boolean) to authenticated;

-- Payment notifications are created by trusted Edge Functions through the
-- service role. The helper keeps their wording and routes consistent.
create or replace function public.notify_payment_change(payment_key bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.payments%rowtype;
declare proposal_key bigint;
declare project_title text;
begin
  if (select auth.role()) <> 'service_role' then
    raise insufficient_privilege using message = 'Service role required';
  end if;
  select * into target from public.payments p where p.id = payment_key;
  if not found then return; end if;
  select c.proposal_id, j.title into proposal_key, project_title
    from public.contracts c join public.jobs j on j.id = c.job_id
    where c.id = target.contract_id;
  if target.status = 'paid' then
    insert into public.notifications(user_id, title, body, route, kind) values
      (target.business_id, 'Project Payment Confirmed',
       coalesce(project_title, 'Project') || ' is funded through PayMongo test mode.',
       '/payment/' || target.contract_id, 'proposals'),
      (target.student_id, 'Project Funded',
       coalesce(project_title, 'Your project') || ' is funded. You may begin the work.',
       '/payment/' || target.contract_id, 'proposals');
  end if;
end; $$;
revoke execute on function public.notify_payment_change(bigint) from public, anon, authenticated;
grant execute on function public.notify_payment_change(bigint) to service_role;
