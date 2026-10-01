-- Disposable lifecycle assertions. Run as project owner after migration 007.
-- All test rows and notifications are rolled back.
begin;
do $$
declare
  business_user uuid;
  student_user uuid;
  test_job bigint;
  test_proposal bigint;
  test_contract bigint;
  business_review bigint;
  student_review bigint;
  withdrawal_job bigint;
  withdrawal_proposal bigint;
  test_project bigint;
  failed_as_expected boolean := false;
begin
  select id into business_user from public.profiles where role = 'business' limit 1;
  select id into student_user from public.profiles where role = 'student' limit 1;
  if business_user is null or student_user is null then
    raise exception 'A business and student profile are required for this test';
  end if;

  insert into public.jobs(
    business_id, title, description, budget, category, urgency, timeline, location
  ) values (
    business_user, 'Lifecycle transaction test',
    'Temporary project used to verify completion and reviews.',
    25000, 'Mobile App', 'Open', '3 weeks', 'Test only'
  ) returning id into test_job;

  insert into public.proposals(
    job_id, student_id, pitch_text, proposed_budget, estimated_timeline_weeks
  ) values (
    test_job, student_user, 'Temporary proposal for lifecycle testing.', 18000, 3
  ) returning id into test_proposal;

  perform set_config('request.jwt.claim.sub', business_user::text, true);
  select public.accept_proposal(test_proposal) into test_contract;

  perform set_config('request.jwt.claim.sub', student_user::text, true);
  perform public.request_contract_completion(test_contract);
  if not exists (select 1 from public.contracts
      where id = test_contract and status = 'completion_requested'
        and completion_requested_by = student_user) then
    raise exception 'Student completion request was not stored';
  end if;

  perform set_config('request.jwt.claim.sub', business_user::text, true);
  perform public.respond_contract_completion(test_contract, false);
  if not exists (select 1 from public.contracts
      where id = test_contract and status = 'in_progress'
        and completion_requested_at is null) then
    raise exception 'Request changes did not restore in-progress state';
  end if;

  perform set_config('request.jwt.claim.sub', student_user::text, true);
  perform public.request_contract_completion(test_contract);
  perform set_config('request.jwt.claim.sub', business_user::text, true);
  perform public.respond_contract_completion(test_contract, true);
  if not exists (select 1 from public.contracts
      where id = test_contract and status = 'completed'
        and completed_at is not null) then
    raise exception 'Contract did not become completed';
  end if;
  if not exists (select 1 from public.jobs
      where id = test_job and status = 'closed') then
    raise exception 'Completed contract did not close its job';
  end if;

  select public.submit_contract_review(
    test_contract, 5, 'The student communicated clearly and delivered the project.'
  ) into business_review;
  perform set_config('request.jwt.claim.sub', student_user::text, true);
  select public.submit_contract_review(
    test_contract, 5, 'The business provided clear requirements and timely feedback.'
  ) into student_review;
  if business_review is null or student_review is null or
      (select count(*) from public.reviews where contract_id = test_contract) <> 2 then
    raise exception 'Both participant reviews were not stored';
  end if;

  begin
    perform public.submit_contract_review(
      test_contract, 4, 'A duplicate review must never be accepted.'
    );
  exception when others then
    failed_as_expected := sqlerrm = 'You have already reviewed this contract';
  end;
  if not failed_as_expected then
    raise exception 'Duplicate review was accepted or returned the wrong error';
  end if;

  insert into public.jobs(
    business_id, title, description, budget, category, urgency, timeline, location
  ) values (
    business_user, 'Withdrawal transaction test',
    'Temporary project used to verify proposal withdrawal ownership.',
    12000, 'Web App', 'Open', '2 weeks', 'Test only'
  ) returning id into withdrawal_job;
  insert into public.proposals(
    job_id, student_id, pitch_text, proposed_budget, estimated_timeline_weeks
  ) values (
    withdrawal_job, student_user, 'Temporary proposal for withdrawal testing.', 10000, 2
  ) returning id into withdrawal_proposal;

  failed_as_expected := false;
  perform set_config('request.jwt.claim.sub', business_user::text, true);
  begin
    perform public.withdraw_proposal(withdrawal_proposal);
  exception when insufficient_privilege then
    failed_as_expected := true;
  end;
  if not failed_as_expected then
    raise exception 'A business could withdraw a student proposal';
  end if;
  perform set_config('request.jwt.claim.sub', student_user::text, true);
  perform public.withdraw_proposal(withdrawal_proposal);
  if exists (select 1 from public.proposals where id = withdrawal_proposal) then
    raise exception 'Student proposal was not withdrawn';
  end if;

  insert into public.portfolio_projects(student_id, title, description)
    values (student_user, 'Portfolio skill test', 'Temporary project for skill replacement testing.')
    returning id into test_project;
  perform public.replace_portfolio_project_skills(test_project, array['Flutter']);
  if not exists (
    select 1 from public.portfolio_project_skills link
    join public.skills s on s.id = link.skill_id
    where link.project_id = test_project and s.name = 'Flutter'
  ) then
    raise exception 'Portfolio skill replacement did not store the selected skill';
  end if;
  perform set_config('request.jwt.claim.sub', business_user::text, true);
  failed_as_expected := false;
  begin
    perform public.replace_portfolio_project_skills(test_project, array['Dart']);
  exception when insufficient_privilege then
    failed_as_expected := true;
  end;
  if not failed_as_expected then
    raise exception 'A business could edit a student portfolio project';
  end if;
end $$;
rollback;
select 'marketplace lifecycle assertions passed; test rows rolled back' as result;
