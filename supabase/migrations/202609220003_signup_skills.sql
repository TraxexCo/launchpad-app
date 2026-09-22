-- Transfer student signup skills from Auth metadata into the normalized junction.
create or replace function private.handle_student_skills() returns trigger
language plpgsql security definer set search_path = '' as $$
declare supplied jsonb;
begin
  select raw_user_meta_data -> 'skills' into supplied
    from auth.users where id = new.user_id;
  if jsonb_typeof(supplied) = 'array' then
    insert into public.student_skills(student_id, skill_id)
    select new.user_id, s.id from public.skills s
    where s.name in (select jsonb_array_elements_text(supplied));
  end if;
  return new;
end; $$;
create trigger on_student_profile_created after insert on public.student_profiles
  for each row execute function private.handle_student_skills();
