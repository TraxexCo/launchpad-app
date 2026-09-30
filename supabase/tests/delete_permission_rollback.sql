-- Explicit permission error and cascade check without persistent test data.
begin;
do $$
declare
  business_user uuid;
  student_user uuid;
  test_job bigint;
  test_proposal bigint;
  was_denied boolean := false;
begin
  select id into business_user from public.profiles where role = 'business' limit 1;
  select id into student_user from public.profiles where role = 'student' limit 1;
  if business_user is null or student_user is null then
    raise exception 'A business and student profile are required';
  end if;
  insert into public.jobs(
    business_id, title, description, budget, category, urgency, timeline, location
  ) values (
    business_user, 'Audit delete test',
    'Temporary database assertion for guarded deletion.',
    25000, 'Mobile App', 'Open', '3 weeks', 'Test only'
  ) returning id into test_job;
  insert into public.proposals(
    job_id, student_id, pitch_text, proposed_budget, estimated_timeline_weeks
  ) values (
    test_job, student_user, 'Temporary pending proposal.', 18000, 3
  ) returning id into test_proposal;

  perform set_config('request.jwt.claim.sub', student_user::text, true);
  begin
    perform public.delete_job(test_job);
  exception when insufficient_privilege then
    was_denied := sqlerrm = 'Not authorized to delete this job';
  end;
  if not was_denied then raise exception 'Foreign owner deletion was not denied'; end if;
  if not exists (select 1 from public.jobs where id = test_job) then
    raise exception 'Foreign owner deletion removed the job';
  end if;

  perform set_config('request.jwt.claim.sub', business_user::text, true);
  perform public.delete_job(test_job);
  if exists (select 1 from public.jobs where id = test_job) or
     exists (select 1 from public.proposals where id = test_proposal) then
    raise exception 'Owned open job or related proposal was not deleted';
  end if;
end $$;
rollback;
select 'guarded deletion assertions passed; test rows rolled back' as result;
