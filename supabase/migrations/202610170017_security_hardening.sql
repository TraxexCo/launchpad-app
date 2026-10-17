-- API throttling and serialized PayMongo checkout claims.

create table if not exists private.api_rate_limits (
  scope text not null,
  actor_key text not null,
  window_started_at timestamptz not null,
  attempts integer not null check (attempts > 0),
  primary key (scope, actor_key)
);

alter table private.api_rate_limits enable row level security;

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
  on conflict (scope, actor_key) do update set
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

revoke execute on function public.consume_api_rate_limit(text,text,integer,integer)
  from public, anon, authenticated;
grant execute on function public.consume_api_rate_limit(text,text,integer,integer)
  to service_role;

alter table public.payments drop constraint if exists payments_status_check;
alter table public.payments add constraint payments_status_check check (
  status in (
    'unpaid', 'creating', 'checkout_created', 'paid', 'released',
    'failed', 'expired', 'refunded'
  )
);

create or replace function public.claim_payment_checkout(
  contract_key bigint,
  business_key uuid,
  student_key uuid,
  amount_value numeric,
  reference_value text
) returns table (
  payment_id bigint,
  claimed boolean,
  payment_status text,
  checkout_url text,
  reference_number text
)
language plpgsql
security definer
set search_path = ''
as $$
declare target public.payments%rowtype;
begin
  if (select auth.role()) <> 'service_role' then
    raise insufficient_privilege using message = 'Service role required';
  end if;
  perform pg_advisory_xact_lock(contract_key);

  insert into public.payments(
    contract_id, business_id, student_id, amount, status, reference_number
  ) values (
    contract_key, business_key, student_key, amount_value, 'creating', reference_value
  )
  on conflict (contract_id) do nothing
  returning * into target;

  if found then
    return query select target.id, true, target.status, target.checkout_url,
      target.reference_number;
    return;
  end if;

  select * into target from public.payments p
    where p.contract_id = contract_key for update;
  if target.status in ('failed', 'expired', 'unpaid') then
    update public.payments p set status = 'creating', updated_at = now()
      where p.id = target.id returning * into target;
    return query select target.id, true, target.status, target.checkout_url,
      target.reference_number;
    return;
  end if;

  return query select target.id, false, target.status, target.checkout_url,
    target.reference_number;
end;
$$;

revoke execute on function public.claim_payment_checkout(bigint,uuid,uuid,numeric,text)
  from public, anon, authenticated;
grant execute on function public.claim_payment_checkout(bigint,uuid,uuid,numeric,text)
  to service_role;
