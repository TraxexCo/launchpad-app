begin;
do $$
declare
  business_user uuid;
  student_user uuid;
  result_distance double precision;
  before_count bigint;
  after_count bigint;
begin
  select id into business_user from public.profiles where role = 'business' limit 1;
  select id into student_user from public.profiles where role = 'student' limit 1;
  if business_user is null or student_user is null then
    raise exception 'A business and student profile are required';
  end if;

  update public.business_profiles set latitude = 14.5995, longitude = 120.9842
    where user_id = business_user;
  select n.distance_km into result_distance
    from public.nearby_businesses(14.5995, 120.9842, 10) n
    where n.user_id = business_user;
  if result_distance is null or result_distance > 0.01 then
    raise exception 'Nearby business distance was not calculated correctly';
  end if;

  insert into public.notification_preferences(user_id, messages)
    values (student_user, false)
    on conflict (user_id) do update set messages = false;
  select count(*) into before_count from public.notifications
    where user_id = student_user;
  insert into public.notifications(user_id, title, body, route)
    values (student_user, 'New Message', 'Preference suppression test', null);
  select count(*) into after_count from public.notifications
    where user_id = student_user;
  if before_count <> after_count then
    raise exception 'Disabled message notification was inserted';
  end if;
end $$;
rollback;
select 'location and notification preference assertions passed; test rows rolled back' as result;
