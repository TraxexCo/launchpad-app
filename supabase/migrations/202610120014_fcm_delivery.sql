-- Deliver new in-app notifications to registered Android devices.
-- This stays inert until launchpad_push_webhook_secret exists in Vault.

create extension if not exists pg_net with schema extensions;

create or replace function private.dispatch_push_notification()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  webhook_secret text;
begin
  select decrypted_secret into webhook_secret
    from vault.decrypted_secrets
   where name = 'launchpad_push_webhook_secret'
   order by created_at desc limit 1;
  if webhook_secret is null then return new; end if;

  perform net.http_post(
    url := 'https://oboyvpcziyjydyfguucs.supabase.co/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-launchpad-webhook-secret', webhook_secret
    ),
    body := jsonb_build_object(
      'type', 'INSERT', 'schema', TG_TABLE_SCHEMA,
      'table', TG_TABLE_NAME, 'record', to_jsonb(new)
    ),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;

revoke all on function private.dispatch_push_notification() from public, anon, authenticated;
create trigger notifications_send_push after insert on public.notifications
for each row execute function private.dispatch_push_notification();
