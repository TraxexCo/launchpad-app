do $$
declare
  expected text[] := array[
    'Flutter', 'Dart', 'React', 'Vue.js', 'Next.js', 'Angular',
    'PHP', 'Laravel', 'Node.js', 'Python', 'FastAPI',
    'MySQL', 'PostgreSQL', 'MongoDB', 'Firebase', 'Supabase',
    'Figma', 'UI/UX', 'REST API', 'GraphQL',
    'Android', 'iOS', 'React Native', 'Kotlin', 'Swift',
    'Docker', 'Git', 'AWS'
  ];
  missing text[];
begin
  select array_agg(name order by name)
  into missing
  from unnest(expected) as name
  where not exists (select 1 from public.skills s where s.name = name);

  if missing is not null then
    raise exception 'Missing skills: %', array_to_string(missing, ', ');
  end if;

  if (select count(*) from public.skills where name = any(expected))
     <> cardinality(expected) then
    raise exception 'Skill catalog contains duplicates';
  end if;

  raise notice 'skill catalog assertions passed';
end $$;
