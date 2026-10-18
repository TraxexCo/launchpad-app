-- Disposable assertions for migration 021. All records are rolled back.
begin;
do $$
declare
  business_user uuid;
  student_user uuid;
  test_job bigint;
  test_proposal bigint;
  test_contract bigint;
  test_payment bigint;
  blocked_without_hold boolean := false;
begin
  select id into business_user from public.profiles where role = 'business' limit 1;
  select id into student_user from public.profiles where role = 'student' limit 1;
  if business_user is null or student_user is null then
    raise exception 'A business and student profile are required for this test';
  end if;

  insert into public.jobs(
    business_id, title, description, budget, category, urgency, timeline, location
  ) values (
    business_user, 'Held payment guard test',
    'Temporary project used to verify payment release protection.',
    5000, 'Mobile App', 'Open', '1 week', 'Test only'
  ) returning id into test_job;
  insert into public.proposals(
    job_id, student_id, pitch_text, proposed_budget, estimated_timeline_weeks
  ) values (
    test_job, student_user, 'Temporary proposal for held payment testing.', 5000, 1
  ) returning id into test_proposal;

  perform set_config('request.jwt.claim.sub', business_user::text, true);
  select public.accept_proposal(test_proposal) into test_contract;
  update public.contracts set status = 'submitted' where id = test_contract;

  begin
    perform public.respond_contract_completion(test_contract, true, null);
  exception when others then
    blocked_without_hold := sqlerrm = 'Confirmed held funds are required before completion approval';
  end;
  if not blocked_without_hold then
    raise exception 'Completion was not blocked when held funds were absent';
  end if;

  insert into public.payments(
    contract_id, business_id, student_id, amount, status, reference_number, paid_at
  ) values (
    test_contract, business_user, student_user, 5000, 'paid',
    'LP-HOLD-' || test_contract, now()
  ) returning id into test_payment;

  perform public.respond_contract_completion(test_contract, true, null);
  if not exists (
    select 1 from public.payments
      where id = test_payment and status = 'released' and released_at is not null
  ) then
    raise exception 'Business approval did not release the held payment';
  end if;
end; $$;
select 'payment hold assertions passed; test rows rolled back' as result;
rollback;
