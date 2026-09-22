-- 202609220002_notifications.sql
-- Run this in your Supabase SQL Editor to enable Phase 3 features.

create table public.notifications (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  route text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;

create policy notifications_read on public.notifications
  for select to authenticated using (user_id = (select auth.uid()));

create policy notifications_update on public.notifications
  for update to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy notifications_delete on public.notifications
  for delete to authenticated using (user_id = (select auth.uid()));

-- Add to Realtime
alter publication supabase_realtime add table public.notifications;

-- Trigger: Notify business when a student submits a proposal
create or replace function public.trigger_proposal_notification()
returns trigger language plpgsql security definer as $$
declare
  job_owner uuid;
  student_name text;
begin
  select business_id into job_owner from public.jobs where id = new.job_id;
  select full_name into student_name from public.profiles where id = new.student_id;
  
  if job_owner is not null then
    insert into public.notifications (user_id, title, body, route)
    values (
      job_owner, 
      'New Proposal Received', 
      student_name || ' submitted a proposal for your job.', 
      '/business/proposals/' || new.id
    );
  end if;
  return new;
end;
$$;

create trigger on_proposal_submitted
  after insert on public.proposals
  for each row execute function public.trigger_proposal_notification();

-- Trigger: Notify student when proposal is accepted
create or replace function public.trigger_contract_notification()
returns trigger language plpgsql security definer as $$
declare
  student_user_id uuid;
  biz_name text;
begin
  -- Get the student ID from the accepted proposal
  select student_id into student_user_id from public.proposals where id = new.proposal_id;
  
  -- Get the business name from the job owner
  select p.full_name into biz_name 
  from public.jobs j 
  join public.profiles p on p.id = j.business_id 
  where j.id = new.job_id;

  if student_user_id is not null then
    insert into public.notifications (user_id, title, body, route)
    values (
      student_user_id, 
      'Proposal Accepted!', 
      biz_name || ' has accepted your proposal. A new workspace has been created.', 
      '/chat/' || new.proposal_id
    );
  end if;
  return new;
end;
$$;

create trigger on_contract_created
  after insert on public.contracts
  for each row execute function public.trigger_contract_notification();
