-- Disposable RPC error assertions; test data is rolled back.
begin;
do $$
declare
  business_user uuid;
  student_user uuid;
  test_job bigint;
  test_proposal bigint;
  duplicate_error boolean := false;
  closed_error boolean := false;
begin
  select id into business_user from public.profiles where role = 'business' limit 1;
  select id into student_user from public.profiles where role = 'student' limit 1;
  if business_user is null or student_user is null then
    raise exception 'A business and student profile are required';
  end if;

  insert into public.jobs(
    business_id, title, description, budget, category, urgency, timeline, location
  ) values (
    business_user, 'Audit proposal test',
    'Temporary database assertion for proposal submission.',
    25000, 'Mobile App', 'Open', '3 weeks', 'Test only'
  ) returning id into test_job;

  perform set_config('request.jwt.claim.sub', student_user::text, true);
  select public.submit_proposal(test_job, repeat('Pitch ', 20), 18000, 3, null)
    into test_proposal;
  if not exists (select 1 from public.proposals
      where id = test_proposal and status = 'pending'
        and proposed_budget = 18000 and estimated_timeline_weeks = 3) then
    raise exception 'Proposal was not saved correctly';
  end if;

  begin
    perform public.submit_proposal(test_job, repeat('Pitch ', 20), 18000, 3, null);
  exception when others then
    duplicate_error := sqlerrm = 'You have already submitted a proposal for this job';
  end;
  if not duplicate_error then raise exception 'Duplicate error mismatch'; end if;

  perform set_config('request.jwt.claim.sub', business_user::text, true);
  perform public.accept_proposal(test_proposal);
  perform set_config('request.jwt.claim.sub', student_user::text, true);
  begin
    perform public.submit_proposal(test_job, repeat('Pitch ', 20), 18000, 3, null);
  exception when others then
    closed_error := sqlerrm = 'This job is no longer accepting proposals';
  end;
  if not closed_error then raise exception 'Closed-job error mismatch'; end if;
end $$;
rollback;
select 'proposal assertions passed; test rows rolled back' as result;
