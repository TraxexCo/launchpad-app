-- Complete the web administrator console with auditable job moderation.
-- Apply after 202610120014_fcm_delivery.sql.

alter table public.jobs
  add column if not exists moderated_at timestamptz,
  add column if not exists moderated_by uuid references auth.users(id),
  add column if not exists moderation_note text;

create or replace function public.admin_moderate_job(
  job_key bigint,
  close_job boolean,
  note_text text
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target public.jobs%rowtype;
begin
  if not private.is_admin() then
    raise insufficient_privilege using message = 'Administrator access required';
  end if;
  if char_length(trim(coalesce(note_text, ''))) < 10 then
    raise exception 'Add a moderation note of at least 10 characters';
  end if;

  select * into target
  from public.jobs
  where id = job_key
  for update;

  if not found then raise exception 'Job not found'; end if;
  if target.status = 'contracted' then
    raise exception 'A contracted job must be handled through its contract dispute';
  end if;

  update public.jobs
  set
    status = case
      when close_job then 'closed'::public.job_status
      else 'open'::public.job_status
    end,
    moderated_at = now(),
    moderated_by = (select auth.uid()),
    moderation_note = trim(note_text),
    updated_at = now()
  where id = job_key;

  insert into public.notifications(user_id, title, body, route, kind)
  values (
    target.business_id,
    case when close_job then 'Job Closed by Administrator'
         else 'Job Reopened by Administrator' end,
    trim(note_text),
    '/business',
    'general'
  );
end;
$$;

revoke execute on function public.admin_moderate_job(bigint, boolean, text)
  from public, anon;
grant execute on function public.admin_moderate_job(bigint, boolean, text)
  to authenticated;
