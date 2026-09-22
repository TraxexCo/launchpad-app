-- LaunchPad foundation. Apply once in a new Supabase project via SQL Editor.
-- Normalized entities keep credentials in auth.users, role-specific attributes in
-- subtype tables, and many-to-many skills in junction tables.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create type public.user_role as enum ('student', 'business');
create type public.verification_status as enum ('unverified', 'pending', 'verified', 'rejected');
create type public.job_status as enum ('open', 'contracted', 'closed');
create type public.proposal_status as enum ('pending', 'accepted', 'rejected');
create type public.contract_status as enum ('in_progress', 'completion_requested', 'completed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null,
  full_name text not null check (char_length(trim(full_name)) between 2 and 100),
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.student_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  school text, course text, year_level text, bio text,
  github_username text, linkedin_url text
);
create table public.business_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  business_name text not null check (char_length(trim(business_name)) > 0),
  description text, category text, address text,
  latitude double precision check (latitude between -90 and 90),
  longitude double precision check (longitude between -180 and 180),
  phone text,
  verification_status public.verification_status not null default 'unverified',
  check ((latitude is null) = (longitude is null))
);
create table public.skills (
  id bigint generated always as identity primary key,
  name text not null unique check (char_length(trim(name)) > 0)
);
insert into public.skills(name) values
  ('Flutter'), ('Dart'), ('React'), ('Next.js'), ('Vue.js'),
  ('Angular'), ('Laravel'), ('PHP'), ('Node.js'), ('MySQL'),
  ('Firebase'), ('MongoDB'), ('Figma'), ('Python'), ('Swift'), ('Kotlin');
create table public.student_skills (
  student_id uuid not null references public.student_profiles(user_id) on delete cascade,
  skill_id bigint not null references public.skills(id),
  primary key (student_id, skill_id)
);
create table public.jobs (
  id bigint generated always as identity primary key,
  business_id uuid not null references public.business_profiles(user_id),
  title text not null check (char_length(trim(title)) between 3 and 150),
  description text not null check (char_length(trim(description)) > 0),
  budget numeric(12,2) not null check (budget > 0),
  category text not null,
  urgency text not null check (urgency in ('Urgent', 'Open')),
  timeline text not null,
  location text not null,
  status public.job_status not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.job_skills (
  job_id bigint not null references public.jobs(id) on delete cascade,
  skill_id bigint not null references public.skills(id),
  primary key (job_id, skill_id)
);
create table public.portfolio_projects (
  id bigint generated always as identity primary key,
  student_id uuid not null references public.student_profiles(user_id) on delete cascade,
  title text not null, description text not null,
  repository_url text, demo_url text, cover_image_path text,
  created_at timestamptz not null default now()
);
create table public.portfolio_project_skills (
  project_id bigint not null references public.portfolio_projects(id) on delete cascade,
  skill_id bigint not null references public.skills(id),
  primary key (project_id, skill_id)
);
create table public.proposals (
  id bigint generated always as identity primary key,
  job_id bigint not null references public.jobs(id),
  student_id uuid not null references public.student_profiles(user_id),
  pitch_text text not null check (char_length(trim(pitch_text)) > 0),
  proposed_budget numeric(12,2) not null check (proposed_budget > 0),
  estimated_timeline_weeks integer not null check (estimated_timeline_weeks > 0),
  attached_project_id bigint references public.portfolio_projects(id) on delete set null,
  status public.proposal_status not null default 'pending',
  created_at timestamptz not null default now(),
  unique (job_id, student_id)
);
create unique index one_accepted_proposal_per_job on public.proposals(job_id)
  where status = 'accepted';
create table public.contracts (
  id bigint generated always as identity primary key,
  proposal_id bigint not null unique references public.proposals(id),
  status public.contract_status not null default 'in_progress',
  agreed_at timestamptz not null default now(),
  completed_at timestamptz
);
create table public.messages (
  id bigint generated always as identity primary key,
  contract_id bigint not null references public.contracts(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  body text not null check (char_length(trim(body)) between 1 and 10000),
  created_at timestamptz not null default now()
);
create table public.reviews (
  id bigint generated always as identity primary key,
  contract_id bigint not null unique references public.contracts(id),
  rating smallint not null check (rating between 1 and 5),
  body text not null,
  created_at timestamptz not null default now()
);
create table public.saved_jobs (
  student_id uuid not null references public.student_profiles(user_id) on delete cascade,
  job_id bigint not null references public.jobs(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (student_id, job_id)
);
create table public.verification_documents (
  id bigint generated always as identity primary key,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  document_type text not null check (document_type in ('student_id', 'enrollment', 'business_permit', 'storefront')),
  storage_path text not null unique,
  status public.verification_status not null default 'pending',
  submitted_at timestamptz not null default now()
);

create or replace function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare selected_role public.user_role;
begin
  -- Client metadata can choose only these two public signup roles. Admin is
  -- deliberately absent; future staff access must be provisioned separately.
  if new.raw_user_meta_data ->> 'role' not in ('student', 'business') then
    raise exception 'A valid student or business role is required';
  end if;
  selected_role := (new.raw_user_meta_data ->> 'role')::public.user_role;
  insert into public.profiles(id, role, full_name)
  values (new.id, selected_role,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), 'LaunchPad User'));
  if selected_role = 'student' then
    insert into public.student_profiles(user_id, bio, github_username)
    values (new.id, new.raw_user_meta_data ->> 'bio',
      new.raw_user_meta_data ->> 'github_username');
  else
    insert into public.business_profiles(user_id, business_name, address)
    values (new.id,
      coalesce(nullif(trim(new.raw_user_meta_data ->> 'business_name'), ''), 'Unnamed Business'),
      new.raw_user_meta_data ->> 'address');
  end if;
  return new;
end; $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function private.handle_new_user();

create or replace function private.is_business(owner_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select owner_id = (select auth.uid()) and exists
    (select 1 from public.business_profiles where user_id = owner_id)
$$;
create or replace function private.is_student(owner_id uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select owner_id = (select auth.uid()) and exists
    (select 1 from public.student_profiles where user_id = owner_id)
$$;
create or replace function private.owns_job(job_key bigint) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.jobs
    where id = job_key and business_id = (select auth.uid()))
$$;
create or replace function private.participates_in_contract(contract_key bigint) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.contracts c
    join public.proposals p on p.id = c.proposal_id
    join public.jobs j on j.id = p.job_id
    where c.id = contract_key
      and (p.student_id = (select auth.uid()) or j.business_id = (select auth.uid()))
  )
$$;
grant usage on schema private to authenticated;
grant execute on function private.is_business(uuid), private.is_student(uuid),
  private.owns_job(bigint), private.participates_in_contract(bigint) to authenticated;

alter table public.profiles enable row level security;
alter table public.student_profiles enable row level security;
alter table public.business_profiles enable row level security;
alter table public.skills enable row level security;
alter table public.student_skills enable row level security;
alter table public.jobs enable row level security;
alter table public.job_skills enable row level security;
alter table public.portfolio_projects enable row level security;
alter table public.portfolio_project_skills enable row level security;
alter table public.proposals enable row level security;
alter table public.contracts enable row level security;
alter table public.messages enable row level security;
alter table public.reviews enable row level security;
alter table public.saved_jobs enable row level security;
alter table public.verification_documents enable row level security;

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
grant select on public.profiles, public.student_profiles, public.business_profiles,
  public.skills, public.student_skills, public.jobs, public.job_skills,
  public.portfolio_projects, public.portfolio_project_skills,
  public.proposals, public.contracts, public.messages, public.reviews,
  public.saved_jobs to authenticated;
grant update(full_name, avatar_path) on public.profiles to authenticated;
grant update(school, course, year_level, bio, github_username, linkedin_url)
  on public.student_profiles to authenticated;
grant update(business_name, description, category, address, latitude, longitude, phone)
  on public.business_profiles to authenticated;
grant insert, delete on public.student_skills, public.job_skills,
  public.portfolio_project_skills, public.saved_jobs to authenticated;
grant insert, delete on public.portfolio_projects to authenticated;
grant update(title, description, repository_url, demo_url, cover_image_path)
  on public.portfolio_projects to authenticated;
grant insert, delete on public.jobs to authenticated;
grant update(title, description, budget, category, urgency, timeline, location)
  on public.jobs to authenticated;
grant insert on public.proposals, public.messages, public.reviews to authenticated;
grant usage, select on all sequences in schema public to authenticated;

create policy profiles_read on public.profiles for select to authenticated using (true);
create policy profiles_update on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy students_read on public.student_profiles for select to authenticated using (true);
create policy students_update on public.student_profiles for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy businesses_read on public.business_profiles for select to authenticated using (true);
create policy businesses_update on public.business_profiles for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy skills_read on public.skills for select to authenticated using (true);
create policy student_skills_read on public.student_skills for select to authenticated using (true);
create policy student_skills_insert on public.student_skills for insert to authenticated
  with check (private.is_student(student_id));
create policy student_skills_delete on public.student_skills for delete to authenticated
  using (private.is_student(student_id));
create policy jobs_read on public.jobs for select to authenticated
  using (status = 'open' or business_id = (select auth.uid()) or exists
    (select 1 from public.proposals p where p.job_id = id and p.student_id = (select auth.uid())));
create policy jobs_insert on public.jobs for insert to authenticated
  with check (private.is_business(business_id) and status = 'open');
create policy jobs_update on public.jobs for update to authenticated
  using (private.is_business(business_id) and status = 'open')
  with check (private.is_business(business_id) and status = 'open');
create policy jobs_delete on public.jobs for delete to authenticated
  using (private.is_business(business_id) and status = 'open');
create policy job_skills_read on public.job_skills for select to authenticated using (true);
create policy job_skills_insert on public.job_skills for insert to authenticated
  with check (private.owns_job(job_id));
create policy job_skills_delete on public.job_skills for delete to authenticated
  using (private.owns_job(job_id));
create policy portfolio_read on public.portfolio_projects for select to authenticated using (true);
create policy portfolio_insert on public.portfolio_projects for insert to authenticated
  with check (private.is_student(student_id));
create policy portfolio_update on public.portfolio_projects for update to authenticated
  using (private.is_student(student_id)) with check (private.is_student(student_id));
create policy portfolio_delete on public.portfolio_projects for delete to authenticated
  using (private.is_student(student_id));
create policy portfolio_skills_read on public.portfolio_project_skills for select to authenticated using (true);
create policy portfolio_skills_insert on public.portfolio_project_skills for insert to authenticated
  with check (exists (select 1 from public.portfolio_projects p where p.id = project_id and p.student_id = (select auth.uid())));
create policy portfolio_skills_delete on public.portfolio_project_skills for delete to authenticated
  using (exists (select 1 from public.portfolio_projects p where p.id = project_id and p.student_id = (select auth.uid())));
create policy proposals_read on public.proposals for select to authenticated
  using (student_id = (select auth.uid()) or private.owns_job(job_id));
create policy proposals_insert on public.proposals for insert to authenticated
  with check (private.is_student(student_id) and status = 'pending'
    and exists (select 1 from public.jobs j where j.id = job_id and j.status = 'open')
    and (attached_project_id is null or exists
      (select 1 from public.portfolio_projects p where p.id = attached_project_id and p.student_id = student_id)));
create policy contracts_read on public.contracts for select to authenticated
  using (private.participates_in_contract(id));
create policy messages_read on public.messages for select to authenticated
  using (private.participates_in_contract(contract_id));
create policy messages_insert on public.messages for insert to authenticated
  with check (sender_id = (select auth.uid()) and private.participates_in_contract(contract_id));
create policy reviews_read on public.reviews for select to authenticated using (true);
create policy reviews_insert on public.reviews for insert to authenticated
  with check (exists (
    select 1 from public.contracts c
    join public.proposals p on p.id = c.proposal_id
    join public.jobs j on j.id = p.job_id
    where c.id = contract_id and c.status = 'completed'
      and j.business_id = (select auth.uid())));
create policy saved_jobs_read on public.saved_jobs for select to authenticated
  using (student_id = (select auth.uid()));
create policy saved_jobs_insert on public.saved_jobs for insert to authenticated
  with check (private.is_student(student_id));
create policy saved_jobs_delete on public.saved_jobs for delete to authenticated
  using (private.is_student(student_id));
-- Verification documents are intentionally inaccessible from the client until
-- private Storage policies and a reviewer workflow are implemented.

create or replace function private.accept_proposal_impl(proposal_key bigint)
returns bigint language plpgsql security definer set search_path = '' as $$
declare target public.proposals%rowtype;
declare owner_id uuid;
declare contract_key bigint;
begin
  select p.* into target from public.proposals p where p.id = proposal_key;
  if not found then raise exception 'Proposal not found'; end if;
  select j.business_id into owner_id from public.jobs j where j.id = target.job_id for update;
  if owner_id is distinct from (select auth.uid()) then
    raise exception 'Only the job owner can accept a proposal';
  end if;
  select c.id into contract_key from public.contracts c where c.proposal_id = proposal_key;
  if contract_key is not null then return contract_key; end if;
  if target.status <> 'pending' or not exists
      (select 1 from public.jobs where id = target.job_id and status = 'open') then
    raise exception 'This job is no longer accepting proposals';
  end if;
  update public.proposals set status = 'rejected'
    where job_id = target.job_id and id <> proposal_key and status = 'pending';
  update public.proposals set status = 'accepted' where id = proposal_key;
  update public.jobs set status = 'contracted' where id = target.job_id;
  insert into public.contracts(proposal_id) values (proposal_key) returning id into contract_key;
  return contract_key;
end; $$;
grant execute on function private.accept_proposal_impl(bigint) to authenticated;
create or replace function public.accept_proposal(proposal_id bigint) returns bigint
language sql security invoker set search_path = '' as $$
  select private.accept_proposal_impl(proposal_id)
$$;
revoke execute on function public.accept_proposal(bigint) from public, anon;
grant execute on function public.accept_proposal(bigint) to authenticated;

create or replace function private.reject_proposal_impl(proposal_key bigint)
returns void language plpgsql security definer set search_path = '' as $$
declare target public.proposals%rowtype;
begin
  select p.* into target from public.proposals p where p.id = proposal_key for update;
  if not found then raise exception 'Proposal not found'; end if;
  if not private.owns_job(target.job_id) then
    raise exception 'Only the job owner can reject a proposal';
  end if;
  if target.status <> 'pending' then
    raise exception 'Only pending proposals can be rejected';
  end if;
  update public.proposals set status = 'rejected' where id = proposal_key;
end; $$;
grant execute on function private.reject_proposal_impl(bigint) to authenticated;
create or replace function public.reject_proposal(proposal_id bigint) returns void
language sql security invoker set search_path = '' as $$
  select private.reject_proposal_impl(proposal_id)
$$;
revoke execute on function public.reject_proposal(bigint) from public, anon;
grant execute on function public.reject_proposal(bigint) to authenticated;

create index jobs_business_idx on public.jobs(business_id, created_at desc);
create index proposals_job_idx on public.proposals(job_id, created_at desc);
create index proposals_student_idx on public.proposals(student_id, created_at desc);
create index messages_contract_idx on public.messages(contract_id, created_at desc);
