alter table public.portfolio_projects
  add column project_type text not null default 'Other';
grant update(project_type) on public.portfolio_projects to authenticated;
