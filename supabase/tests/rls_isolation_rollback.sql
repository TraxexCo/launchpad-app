-- Direct authenticated-role RLS assertions. All setup rows are rolled back.
begin;

create temporary table rls_test_ids (
  business_id uuid,
  student_id uuid,
  job_id bigint,
  contract_id bigint
) on commit drop;

do $$
declare
  business_user uuid;
  student_user uuid;
  test_job bigint;
  test_proposal bigint;
  test_contract bigint;
begin
  select id into business_user from public.profiles where role = 'business' limit 1;
  select id into student_user from public.profiles where role = 'student' limit 1;
  if business_user is null or student_user is null then
    raise exception 'A business and student profile are required';
  end if;

  insert into public.jobs(
    business_id, title, description, budget, category, urgency, timeline, location
  ) values (
    business_user, 'RLS isolation test',
    'Temporary job used to verify direct authenticated table policies.',
    25000, 'Mobile App', 'Open', '3 weeks', 'Test only'
  ) returning id into test_job;
  insert into public.proposals(
    job_id, student_id, pitch_text, proposed_budget, estimated_timeline_weeks
  ) values (
    test_job, student_user, 'Temporary proposal for RLS isolation.', 18000, 3
  ) returning id into test_proposal;

  perform set_config('request.jwt.claim.sub', business_user::text, true);
  select public.accept_proposal(test_proposal) into test_contract;
  insert into public.messages(contract_id, sender_id, body)
    values (test_contract, business_user, 'Private RLS test message');

  insert into rls_test_ids values (
    business_user, student_user, test_job, test_contract
  );
end $$;

grant select on rls_test_ids to authenticated;
set local role authenticated;

do $$
declare
  ids rls_test_ids%rowtype;
  was_denied boolean;
  affected bigint;
  visible_messages bigint;
  unrelated_user uuid := gen_random_uuid();
begin
  select * into ids from rls_test_ids;

  perform set_config('request.jwt.claim.sub', ids.student_id::text, true);
  was_denied := false;
  begin
    insert into public.jobs(
      business_id, title, description, budget, category, urgency, timeline, location
    ) values (
      ids.student_id, 'Forbidden student job',
      'A student must never be able to create a business job directly.',
      1000, 'Other', 'Open', '1 week', 'Test only'
    );
  exception when insufficient_privilege then
    was_denied := true;
  end;
  if not was_denied then raise exception 'Student job insert was allowed'; end if;

  delete from public.jobs where id = ids.job_id;
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'Foreign job deletion was allowed'; end if;

  perform set_config('request.jwt.claim.sub', unrelated_user::text, true);
  select count(*) into visible_messages
  from public.messages where contract_id = ids.contract_id;
  if visible_messages <> 0 then
    raise exception 'Unrelated user could read a private chat message';
  end if;

  perform set_config('request.jwt.claim.sub', ids.business_id::text, true);
  was_denied := false;
  begin
    insert into public.portfolio_projects(student_id, title, description)
    values (
      ids.business_id, 'Forbidden business portfolio',
      'A business must never create a student portfolio project.'
    );
  exception when insufficient_privilege then
    was_denied := true;
  end;
  if not was_denied then raise exception 'Business portfolio insert was allowed'; end if;
end $$;

rollback;
select 'RLS isolation assertions passed; test rows rolled back' as result;
