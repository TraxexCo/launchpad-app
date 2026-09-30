-- Disposable database assertions. Run as project owner in SQL Editor.
-- The inserted job, proposal, contract, and conversation are rolled back.
begin;
do $$
declare
  business_user uuid;
  student_user uuid;
  test_job bigint;
  test_proposal bigint;
  test_contract bigint;
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
    business_user, 'Audit contract test',
    'Temporary database assertion for the acceptance transaction.',
    25000, 'Mobile App', 'Open', '3 weeks', 'Test only'
  ) returning id into test_job;

  insert into public.proposals(
    job_id, student_id, pitch_text, proposed_budget, estimated_timeline_weeks
  ) values (
    test_job, student_user, 'Temporary proposal for transaction test.', 18000, 3
  ) returning id into test_proposal;

  perform set_config('request.jwt.claim.sub', business_user::text, true);
  select public.accept_proposal(test_proposal) into test_contract;

  if not exists (select 1 from public.jobs
      where id = test_job and status = 'in_progress') then
    raise exception 'Job status did not become in_progress';
  end if;
  if not exists (select 1 from public.proposals
      where id = test_proposal and status = 'accepted') then
    raise exception 'Proposal was not accepted';
  end if;
  if not exists (select 1 from public.contracts
      where id = test_contract and job_id = test_job
        and business_id = business_user and student_id = student_user
        and agreed_budget = 18000 and agreed_timeline_weeks = 3) then
    raise exception 'Contract snapshot is incomplete';
  end if;
  if not exists (select 1 from public.conversations
      where contract_id = test_contract) then
    raise exception 'Contract conversation is missing';
  end if;

  begin
    perform public.accept_proposal(test_proposal);
  exception when others then
    failed_as_expected := sqlerrm = 'Job is no longer open for acceptance';
  end;
  if not failed_as_expected then
    raise exception 'Already awarded job was accepted again or wrong error returned';
  end if;
end $$;
rollback;
select 'contract acceptance assertions passed; test rows rolled back' as result;
