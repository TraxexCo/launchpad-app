-- Disposable PayMongo lifecycle assertions. Run after migration 010.
begin;
do $$
declare
  business_user uuid;
  student_user uuid;
  test_job bigint;
  test_proposal bigint;
  test_contract bigint;
  test_payment bigint;
  blocked_unfunded boolean := false;
begin
  select id into business_user from public.profiles where role = 'business' limit 1;
  select id into student_user from public.profiles where role = 'student' limit 1;
  if business_user is null or student_user is null then
    raise exception 'A business and student profile are required for this test';
  end if;
  insert into public.jobs(
    business_id, title, description, budget, category, urgency, timeline, location
  ) values (
    business_user, 'PayMongo lifecycle test',
    'Temporary project used to verify the funded completion gate.',
    15000, 'Mobile App', 'Open', '2 weeks', 'Test only'
  ) returning id into test_job;
  insert into public.proposals(
    job_id, student_id, pitch_text, proposed_budget, estimated_timeline_weeks
  ) values (
    test_job, student_user, 'Temporary funded proposal for payment testing.', 12000, 2
  ) returning id into test_proposal;
  perform set_config('request.jwt.claim.sub', business_user::text, true);
  select public.accept_proposal(test_proposal) into test_contract;
  perform set_config('request.jwt.claim.sub', student_user::text, true);
  begin
    perform public.request_contract_completion(test_contract);
  exception when others then
    blocked_unfunded := sqlerrm = 'The project must be funded before work can be submitted';
  end;
  if not blocked_unfunded then raise exception 'Unfunded completion was not blocked'; end if;
  insert into public.payments(
    contract_id, business_id, student_id, amount, status, reference_number, paid_at
  ) values (
    test_contract, business_user, student_user, 12000, 'paid',
    'LP-ROLLBACK-' || test_contract, now()
  ) returning id into test_payment;
  perform public.request_contract_completion(test_contract);
  perform set_config('request.jwt.claim.sub', business_user::text, true);
  perform public.respond_contract_completion(test_contract, true);
  if not exists (
    select 1 from public.payments
    where id = test_payment and status = 'released' and released_at is not null
  ) then
    raise exception 'Approval did not release the classroom payment';
  end if;
end; $$;
select 'payment lifecycle assertions passed; test rows rolled back' as result;
rollback;
