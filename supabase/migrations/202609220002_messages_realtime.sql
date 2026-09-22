-- Deliver database-backed chat updates to subscribed participants.
alter publication supabase_realtime add table public.messages;
