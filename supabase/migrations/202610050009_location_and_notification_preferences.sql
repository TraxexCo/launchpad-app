-- Nearby business discovery and durable notification preferences.

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  jobs boolean not null default true,
  proposals boolean not null default true,
  messages boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.notification_preferences enable row level security;
revoke all on public.notification_preferences from anon, authenticated;
grant select, insert, update(jobs, proposals, messages, updated_at)
  on public.notification_preferences to authenticated;

drop policy if exists notification_preferences_read on public.notification_preferences;
create policy notification_preferences_read on public.notification_preferences
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists notification_preferences_insert on public.notification_preferences;
create policy notification_preferences_insert on public.notification_preferences
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists notification_preferences_update on public.notification_preferences;
create policy notification_preferences_update on public.notification_preferences
  for update to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

alter table public.notifications
  add column if not exists kind text not null default 'general';
alter table public.notifications drop constraint if exists notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check
  check (kind in ('general', 'jobs', 'proposals', 'messages'));

update public.notifications
set kind = case
  when lower(title) like '%message%' or lower(title) like '%chat%' then 'messages'
  when lower(title) like '%proposal%' or lower(title) like '%contract%'
    or lower(title) like '%completion%' or lower(title) like '%project completed%'
    or lower(title) like '%changes requested%' or lower(title) like '%review%'
    then 'proposals'
  when lower(title) like '%job%' or lower(title) like '%opportunit%' then 'jobs'
  else 'general'
end
where kind = 'general';

create or replace function private.apply_notification_preferences()
returns trigger language plpgsql security definer set search_path = '' as $$
declare prefs public.notification_preferences%rowtype;
declare normalized_title text := lower(new.title);
begin
  if new.kind = 'general' then
    if normalized_title like '%message%' or normalized_title like '%chat%' then
      new.kind := 'messages';
    elsif normalized_title like '%proposal%' or normalized_title like '%contract%'
       or normalized_title like '%completion%' or normalized_title like '%project completed%'
       or normalized_title like '%changes requested%' or normalized_title like '%review%' then
      new.kind := 'proposals';
    elsif normalized_title like '%job%' or normalized_title like '%opportunit%' then
      new.kind := 'jobs';
    end if;
  end if;

  select * into prefs from public.notification_preferences p
    where p.user_id = new.user_id;
  if found and (
    (new.kind = 'jobs' and not prefs.jobs) or
    (new.kind = 'proposals' and not prefs.proposals) or
    (new.kind = 'messages' and not prefs.messages)
  ) then
    return null;
  end if;
  return new;
end; $$;

drop trigger if exists apply_notification_preferences on public.notifications;
create trigger apply_notification_preferences
  before insert on public.notifications
  for each row execute function private.apply_notification_preferences();

create or replace function public.nearby_businesses(
  user_latitude double precision,
  user_longitude double precision,
  radius_km double precision default 25
) returns table (
  user_id uuid,
  business_name text,
  description text,
  category text,
  address text,
  phone text,
  latitude double precision,
  longitude double precision,
  verification_status public.verification_status,
  distance_km double precision
) language sql stable security invoker set search_path = '' as $$
  select
    b.user_id,
    b.business_name,
    b.description,
    b.category,
    b.address,
    b.phone,
    b.latitude,
    b.longitude,
    b.verification_status,
    6371.0 * acos(
      least(1.0, greatest(-1.0,
        cos(radians(user_latitude)) * cos(radians(b.latitude)) *
        cos(radians(b.longitude) - radians(user_longitude)) +
        sin(radians(user_latitude)) * sin(radians(b.latitude))
      ))
    ) as distance_km
  from public.business_profiles b
  where b.latitude is not null and b.longitude is not null
    and user_latitude between -90 and 90
    and user_longitude between -180 and 180
    and radius_km between 1 and 200
    and 6371.0 * acos(
      least(1.0, greatest(-1.0,
        cos(radians(user_latitude)) * cos(radians(b.latitude)) *
        cos(radians(b.longitude) - radians(user_longitude)) +
        sin(radians(user_latitude)) * sin(radians(b.latitude))
      ))
    ) <= radius_km
  order by distance_km, b.business_name;
$$;

revoke execute on function public.nearby_businesses(double precision,double precision,double precision)
  from public, anon;
grant execute on function public.nearby_businesses(double precision,double precision,double precision)
  to authenticated;

create index if not exists business_profiles_coordinates_idx
  on public.business_profiles(latitude, longitude)
  where latitude is not null and longitude is not null;
