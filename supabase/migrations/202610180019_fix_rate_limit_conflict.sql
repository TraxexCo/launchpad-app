-- Disambiguate the rate-limit UPSERT from its actor_key parameter.

create or replace function public.consume_api_rate_limit(
  scope_name text,
  actor_key text,
  maximum_attempts integer,
  window_seconds integer
) returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare current_row private.api_rate_limits%rowtype;
begin
  if (select auth.role()) <> 'service_role' then
    raise insufficient_privilege using message = 'Service role required';
  end if;
  if maximum_attempts < 1 or window_seconds < 1 or
     char_length(scope_name) > 80 or char_length(actor_key) > 160 then
    raise exception 'Invalid rate limit configuration';
  end if;

  insert into private.api_rate_limits(scope, actor_key, window_started_at, attempts)
  values (scope_name, actor_key, now(), 1)
  on conflict on constraint api_rate_limits_pkey do update set
    window_started_at = case
      when private.api_rate_limits.window_started_at + make_interval(secs => window_seconds) <= now()
        then now()
      else private.api_rate_limits.window_started_at
    end,
    attempts = case
      when private.api_rate_limits.window_started_at + make_interval(secs => window_seconds) <= now()
        then 1
      else private.api_rate_limits.attempts + 1
    end
  returning * into current_row;

  return current_row.attempts <= maximum_attempts;
end;
$$;

revoke execute on function public.consume_api_rate_limit(text,text,integer,integer) from public, anon, authenticated;
grant execute on function public.consume_api_rate_limit(text,text,integer,integer) to service_role;
