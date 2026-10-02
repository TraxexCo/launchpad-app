-- Keep every selectable app skill available to profile, portfolio, and job links.
insert into public.skills (name)
values
  ('Flutter'), ('Dart'), ('React'), ('Vue.js'), ('Next.js'), ('Angular'),
  ('PHP'), ('Laravel'), ('Node.js'), ('Python'), ('FastAPI'),
  ('MySQL'), ('PostgreSQL'), ('MongoDB'), ('Firebase'), ('Supabase'),
  ('Figma'), ('UI/UX'), ('REST API'), ('GraphQL'),
  ('Android'), ('iOS'), ('React Native'), ('Kotlin'), ('Swift'),
  ('Docker'), ('Git'), ('AWS')
on conflict (name) do nothing;
