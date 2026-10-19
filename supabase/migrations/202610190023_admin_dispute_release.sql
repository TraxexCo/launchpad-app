-- Let an administrator release held funds when the evidence shows that the
-- student completed the agreed work despite a disputed client response.

create or replace function public.admin_resolve_dispute(
  contract_key bigint, decision text, note_text text
) returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
declare current_payment_status text;
begin
  if not private.is_admin() then raise insufficient_privilege using message = 'Administrator access required'; end if;
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found or target.status <> 'disputed' then raise exception 'Open dispute not found'; end if;
  if decision not in ('resume','cancel','refund','release') then raise exception 'Invalid dispute decision'; end if;
  if char_length(trim(coalesce(note_text,''))) < 10 then raise exception 'Add a resolution note'; end if;

  select p.status into current_payment_status from public.payments p
    where p.contract_id = contract_key for update;
  if decision = 'cancel' and current_payment_status = 'paid' then
    raise exception 'A funded dispute must be resumed, refunded, or released';
  end if;
  if decision in ('refund','release') and coalesce(current_payment_status,'') <> 'paid' then
    raise exception 'This decision requires confirmed held funds';
  end if;

  if decision = 'release' then
    update public.payments set status = 'released', released_at = now(), updated_at = now()
      where contract_id = contract_key and status = 'paid';
    if not found then raise exception 'Held funds could not be released'; end if;
    update public.contracts set status = 'completed', completed_at = now(),
      dispute_resolved_at = now(), dispute_resolved_by = (select auth.uid()),
      dispute_resolution = trim(note_text), revision_message = null
      where id = contract_key;
    update public.jobs set status = 'closed' where id = target.job_id;
  else
    update public.contracts set
      status = case when decision = 'resume' then 'in_progress'::public.contract_status else 'cancelled'::public.contract_status end,
      cancelled_at = case when decision in ('cancel','refund') then now() else cancelled_at end,
      cancellation_reason = case when decision in ('cancel','refund') then trim(note_text) else cancellation_reason end,
      dispute_resolved_at = now(), dispute_resolved_by = (select auth.uid()),
      dispute_resolution = trim(note_text)
      where id = contract_key;
    if decision = 'refund' then
      update public.payments set status = 'refunded', updated_at = now()
        where contract_id = contract_key and status = 'paid';
      if not found then raise exception 'Held funds could not be marked refunded'; end if;
    end if;
  end if;

  insert into public.contract_events(contract_id, actor_id, event_type, message)
    values (contract_key, (select auth.uid()),
      case when decision = 'resume' then 'started'
           when decision = 'release' then 'completed' else 'cancelled' end,
      'Administrator decision: ' || decision || '. ' || trim(note_text));
  insert into public.notifications(user_id,title,body,route,kind) values
    (target.student_id, 'Dispute Resolved', trim(note_text), '/contract/' || contract_key, 'proposals'),
    (target.business_id, 'Dispute Resolved', trim(note_text), '/contract/' || contract_key, 'proposals');
end; $$;

revoke execute on function public.admin_resolve_dispute(bigint,text,text) from public, anon;
grant execute on function public.admin_resolve_dispute(bigint,text,text) to authenticated;
