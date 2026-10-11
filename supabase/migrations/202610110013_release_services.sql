-- Release support: crash diagnostics and device push-token registration.
-- Apply after 202610110012_admin_moderation.sql.

create table public.app_errors (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete set null,
  message text not null,
  stack_trace text,
  platform text not null,
  app_version text not null default '1.0.0',
  created_at timestamptz not null default now()
);
alter table public.app_errors enable row level security;
revoke all on public.app_errors from anon, authenticated;
create policy app_errors_admin_read on public.app_errors for select to authenticated using (private.is_admin());
grant select on public.app_errors to authenticated;

create or replace function public.record_app_error(error_message text, error_stack text, client_platform text)
returns void language plpgsql security definer set search_path = '' as $$
begin
  insert into public.app_errors(user_id,message,stack_trace,platform)
  values ((select auth.uid()), left(coalesce(error_message,'Unknown error'),2000), left(error_stack,10000), left(coalesce(client_platform,'unknown'),80));
end; $$;
revoke execute on function public.record_app_error(text,text,text) from public, anon;
grant execute on function public.record_app_error(text,text,text) to authenticated;

create table public.device_push_tokens (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android','ios','web')),
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.device_push_tokens enable row level security;
revoke all on public.device_push_tokens from anon, authenticated;
grant select, insert, update(enabled,updated_at), delete on public.device_push_tokens to authenticated;
create policy push_tokens_own_read on public.device_push_tokens for select to authenticated using (user_id = (select auth.uid()));
create policy push_tokens_own_insert on public.device_push_tokens for insert to authenticated with check (user_id = (select auth.uid()));
create policy push_tokens_own_update on public.device_push_tokens for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy push_tokens_own_delete on public.device_push_tokens for delete to authenticated using (user_id = (select auth.uid()));
