-- Real report submission. Apply after 202609220005_contract_lifecycle.sql.
create table public.reports (
  id bigint generated always as identity primary key,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('student', 'business', 'job', 'proposal')),
  target_label text not null check (char_length(trim(target_label)) between 1 and 200),
  reason text not null check (char_length(trim(reason)) between 3 and 100),
  details text check (details is null or char_length(trim(details)) between 1 and 2000),
  status text not null default 'open' check (status in ('open', 'reviewing', 'resolved', 'dismissed')),
  created_at timestamptz not null default now()
);

alter table public.reports enable row level security;
revoke all on public.reports from anon, authenticated;
grant insert, select on public.reports to authenticated;
grant usage, select on sequence public.reports_id_seq to authenticated;

create policy reports_insert_own on public.reports for insert to authenticated
  with check (reporter_id = (select auth.uid()) and status = 'open');
create policy reports_read_own on public.reports for select to authenticated
  using (reporter_id = (select auth.uid()));
