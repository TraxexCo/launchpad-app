-- Let trusted dashboard and admin API workflows create an auth identity before
-- assigning its application role. Public registrations still supply a valid
-- student or business role and receive their profile rows atomically.
create or replace function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare selected_role public.user_role;
begin
  if coalesce(new.raw_user_meta_data ->> 'role', '')
      not in ('student', 'business') then
    return new;
  end if;

  selected_role := (new.raw_user_meta_data ->> 'role')::public.user_role;
  insert into public.profiles(id, role, full_name)
  values (
    new.id,
    selected_role,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      'LaunchPad User'
    )
  );

  if selected_role = 'student' then
    insert into public.student_profiles(
      user_id,
      school,
      course,
      bio,
      github_username
    )
    values (
      new.id,
      new.raw_user_meta_data ->> 'school',
      new.raw_user_meta_data ->> 'course',
      new.raw_user_meta_data ->> 'bio',
      new.raw_user_meta_data ->> 'github_username'
    );
  else
    insert into public.business_profiles(user_id, business_name, address)
    values (
      new.id,
      coalesce(
        nullif(trim(new.raw_user_meta_data ->> 'business_name'), ''),
        'Unnamed Business'
      ),
      new.raw_user_meta_data ->> 'address'
    );
  end if;

  return new;
end;
$$;
