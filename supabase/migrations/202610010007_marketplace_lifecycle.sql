-- Complete the student-to-business project lifecycle and tighten backend access.
-- Apply after 202610010006_reports.sql.

-- Notification tables created after the foundation migration need explicit grants.
revoke all on public.notifications from anon, authenticated;
grant select, update(is_read), delete on public.notifications to authenticated;

-- Harden trigger functions and notify every student whose pending proposal is rejected.
create or replace function public.trigger_proposal_notification()
returns trigger language plpgsql security definer set search_path = '' as $$
declare job_owner uuid;
declare student_name text;
begin
  select j.business_id into job_owner from public.jobs j where j.id = new.job_id;
  select p.full_name into student_name from public.profiles p where p.id = new.student_id;
  if job_owner is not null then
    insert into public.notifications(user_id, title, body, route)
    values (job_owner, 'New Proposal Received',
      coalesce(student_name, 'A student') || ' submitted a proposal for your job.',
      '/business/proposals/' || new.id);
  end if;
  return new;
end; $$;

create or replace function public.trigger_contract_notification()
returns trigger language plpgsql security definer set search_path = '' as $$
declare biz_name text;
begin
  select b.business_name into biz_name
    from public.business_profiles b where b.user_id = new.business_id;
  insert into public.notifications(user_id, title, body, route)
  values (new.student_id, 'Proposal Accepted!',
    coalesce(biz_name, 'A business') || ' accepted your proposal. Your project workspace is ready.',
    '/chat/' || new.proposal_id);
  return new;
end; $$;

create or replace function public.trigger_rejected_proposal_notification()
returns trigger language plpgsql security definer set search_path = '' as $$
declare job_title text;
begin
  if old.status = 'pending' and new.status = 'rejected' then
    select j.title into job_title from public.jobs j where j.id = new.job_id;
    insert into public.notifications(user_id, title, body, route)
    values (new.student_id, 'Proposal Update',
      'Your proposal for ' || coalesce(job_title, 'a job') || ' was not selected.',
      '/student/proposals');
  end if;
  return new;
end; $$;
drop trigger if exists on_proposal_rejected on public.proposals;
create trigger on_proposal_rejected after update of status on public.proposals
  for each row execute function public.trigger_rejected_proposal_notification();

create or replace function public.trigger_message_notification()
returns trigger language plpgsql security definer set search_path = '' as $$
declare recipient uuid;
declare proposal_key bigint;
declare sender_name text;
begin
  select case when c.student_id = new.sender_id then c.business_id else c.student_id end,
         c.proposal_id into recipient, proposal_key
    from public.contracts c where c.id = new.contract_id;
  select p.full_name into sender_name from public.profiles p where p.id = new.sender_id;
  if recipient is not null and recipient <> new.sender_id then
    insert into public.notifications(user_id, title, body, route)
    values (recipient, 'New Message',
      coalesce(sender_name, 'Your project partner') || ' sent a project message.',
      '/chat/' || proposal_key);
  end if;
  return new;
end; $$;
drop trigger if exists on_message_sent on public.messages;
create trigger on_message_sent after insert on public.messages
  for each row execute function public.trigger_message_notification();

-- A student may withdraw only their own proposal while it is still pending.
create or replace function public.withdraw_proposal(proposal_key bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.proposals%rowtype;
begin
  select * into target from public.proposals p where p.id = proposal_key for update;
  if not found then raise exception 'Proposal not found'; end if;
  if target.student_id is distinct from (select auth.uid()) then
    raise insufficient_privilege using message = 'Only the proposal owner can withdraw it';
  end if;
  if target.status <> 'pending' then
    raise exception 'Only a pending proposal can be withdrawn';
  end if;
  delete from public.proposals p where p.id = proposal_key;
end; $$;
revoke execute on function public.withdraw_proposal(bigint) from public, anon;
grant execute on function public.withdraw_proposal(bigint) to authenticated;

-- Replace a project's skills atomically so a failed request cannot leave a
-- partially edited portfolio. Project fields continue to use owner-only RLS.
create or replace function public.replace_portfolio_project_skills(
  project_key bigint, selected_skill_names text[]
) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not exists (
    select 1 from public.portfolio_projects p
    where p.id = project_key and p.student_id = (select auth.uid())
  ) then
    raise insufficient_privilege using message = 'Not authorized to edit this project';
  end if;
  if exists (
    select 1 from unnest(coalesce(selected_skill_names, array[]::text[])) requested(name)
    where not exists (select 1 from public.skills s where s.name = requested.name)
  ) then
    raise exception 'One or more selected skills are unavailable';
  end if;
  delete from public.portfolio_project_skills link where link.project_id = project_key;
  insert into public.portfolio_project_skills(project_id, skill_id)
    select project_key, s.id from public.skills s
    where s.name = any(coalesce(selected_skill_names, array[]::text[]));
end; $$;
revoke execute on function public.replace_portfolio_project_skills(bigint,text[]) from public, anon;
grant execute on function public.replace_portfolio_project_skills(bigint,text[]) to authenticated;

-- A student submits completed work; the business approves or requests changes.
alter table public.contracts
  add column completion_requested_at timestamptz,
  add column completion_requested_by uuid references public.profiles(id);

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
  update public.contracts set status = 'completion_requested',
    completion_requested_at = now(), completion_requested_by = (select auth.uid())
    where id = contract_key;
  select j.title into project_title from public.jobs j where j.id = target.job_id;
  insert into public.notifications(user_id, title, body, route)
  values (target.business_id, 'Completion Requested',
    'The student submitted ' || coalesce(project_title, 'your project') || ' for approval.',
    '/chat/' || target.proposal_id);
end; $$;
revoke execute on function public.request_contract_completion(bigint) from public, anon;
grant execute on function public.request_contract_completion(bigint) to authenticated;

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
  if approve_completion is null then
    raise exception 'An approval decision is required';
  end if;
  select j.title into project_title from public.jobs j where j.id = target.job_id;
  if approve_completion then
    update public.contracts set status = 'completed', completed_at = now()
      where id = contract_key;
    update public.jobs set status = 'closed' where id = target.job_id;
    insert into public.notifications(user_id, title, body, route)
    values (target.student_id, 'Project Completed',
      coalesce(project_title, 'Your project') || ' was approved as completed.',
      '/chat/' || target.proposal_id);
  else
    update public.contracts set status = 'in_progress',
      completion_requested_at = null, completion_requested_by = null
      where id = contract_key;
    insert into public.notifications(user_id, title, body, route)
    values (target.student_id, 'Changes Requested',
      'The business requested more work on ' || coalesce(project_title, 'your project') || '. Check the project chat.',
      '/chat/' || target.proposal_id);
  end if;
end; $$;
revoke execute on function public.respond_contract_completion(bigint,boolean) from public, anon;
grant execute on function public.respond_contract_completion(bigint,boolean) to authenticated;

-- Both participants may review each other once after completion.
alter table public.reviews
  add column reviewer_id uuid references public.profiles(id),
  add column reviewee_id uuid references public.profiles(id);
update public.reviews r set reviewer_id = c.business_id, reviewee_id = c.student_id
  from public.contracts c where c.id = r.contract_id;
alter table public.reviews alter column reviewer_id set not null;
alter table public.reviews alter column reviewee_id set not null;
alter table public.reviews drop constraint if exists reviews_contract_id_key;
alter table public.reviews add constraint reviews_one_per_participant
  unique(contract_id, reviewer_id);
alter table public.reviews add constraint reviews_not_self
  check (reviewer_id <> reviewee_id);
drop policy if exists reviews_insert on public.reviews;
revoke insert on public.reviews from authenticated;

create or replace function public.submit_contract_review(
  contract_key bigint, rating_value integer, review_body text
) returns bigint language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
declare reviewee uuid;
declare result_id bigint;
begin
  select * into target from public.contracts c where c.id = contract_key;
  if not found then raise exception 'Contract not found'; end if;
  if target.status <> 'completed' then raise exception 'Reviews are available after project completion'; end if;
  if (select auth.uid()) = target.student_id then reviewee := target.business_id;
  elsif (select auth.uid()) = target.business_id then reviewee := target.student_id;
  else raise insufficient_privilege using message = 'Only contract participants can leave a review';
  end if;
  if rating_value is null or rating_value not between 1 and 5 then
    raise exception 'Rating must be from 1 to 5';
  end if;
  if review_body is null or char_length(trim(review_body)) < 10 then
    raise exception 'Review must be at least 10 characters';
  end if;
  insert into public.reviews(contract_id, reviewer_id, reviewee_id, rating, body)
    values (contract_key, (select auth.uid()), reviewee, rating_value, trim(review_body))
    returning id into result_id;
  insert into public.notifications(user_id, title, body, route)
    values (reviewee, 'New Review', 'Your project partner left you a review.', null);
  return result_id;
exception when unique_violation then
  raise exception 'You have already reviewed this contract';
end; $$;
revoke execute on function public.submit_contract_review(bigint,integer,text) from public, anon;
grant execute on function public.submit_contract_review(bigint,integer,text) to authenticated;

create index reviews_reviewee_idx on public.reviews(reviewee_id, created_at desc);
