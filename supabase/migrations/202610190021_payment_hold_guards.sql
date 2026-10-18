-- Make the classroom payment hold explicit and prevent a funded contract from
-- reaching a terminal state without either release or refund.

comment on column public.payments.status is
  'paid means confirmed and held for the project; released means business-approved completion; refunded means an administrator approved return of the held test payment.';

create or replace function public.respond_contract_completion(
  contract_key bigint, approve_completion boolean, revision_note text default null
) returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
declare project_title text;
declare current_payment_status text;
begin
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found then raise exception 'Contract not found'; end if;
  if target.business_id is distinct from (select auth.uid()) then
    raise insufficient_privilege using message = 'Only the hiring business can review the submission';
  end if;
  if target.status <> 'submitted' then
    raise exception 'This contract has no submission awaiting review';
  end if;
  select j.title into project_title from public.jobs j where j.id = target.job_id;

  if approve_completion then
    select p.status into current_payment_status
      from public.payments p where p.contract_id = contract_key for update;
    if not found or current_payment_status <> 'paid' then
      raise exception 'Confirmed held funds are required before completion approval';
    end if;

    update public.payments
      set status = 'released', released_at = now(), updated_at = now()
      where contract_id = contract_key and status = 'paid';
    if not found then raise exception 'Held funds could not be released'; end if;

    update public.contracts
      set status = 'completed', completed_at = now(), revision_message = null
      where id = contract_key;
    update public.jobs set status = 'closed' where id = target.job_id;
    insert into public.contract_events(contract_id, actor_id, event_type, message)
      values (contract_key, (select auth.uid()), 'completed',
        'Business approved the final submission and released the held payment.');
    insert into public.notifications(user_id, title, body, route, kind)
      values (target.student_id, 'Project Completed & Payment Released',
        coalesce(project_title,'Your project') || ' was approved and its held payment was released.',
        '/contract/' || contract_key, 'proposals');
  else
    if char_length(trim(coalesce(revision_note,''))) < 5 then
      raise exception 'Explain the requested revision';
    end if;
    update public.contracts
      set status = 'revision_requested', revision_message = trim(revision_note)
      where id = contract_key;
    insert into public.contract_events(contract_id, actor_id, event_type, message)
      values (contract_key, (select auth.uid()), 'revision_requested', trim(revision_note));
    insert into public.notifications(user_id, title, body, route, kind)
      values (target.student_id, 'Revision Requested', trim(revision_note),
        '/contract/' || contract_key, 'proposals');
  end if;
end; $$;

revoke execute on function public.respond_contract_completion(bigint,boolean,text)
  from public, anon;
grant execute on function public.respond_contract_completion(bigint,boolean,text)
  to authenticated;

create or replace function public.admin_resolve_dispute(
  contract_key bigint, decision text, note_text text
) returns void language plpgsql security definer set search_path = '' as $$
declare target public.contracts%rowtype;
declare current_payment_status text;
begin
  if not private.is_admin() then
    raise insufficient_privilege using message = 'Administrator access required';
  end if;
  select * into target from public.contracts c where c.id = contract_key for update;
  if not found or target.status <> 'disputed' then raise exception 'Open dispute not found'; end if;
  if decision not in ('resume','cancel','refund') then raise exception 'Invalid dispute decision'; end if;
  if char_length(trim(coalesce(note_text,''))) < 10 then raise exception 'Add a resolution note'; end if;

  select p.status into current_payment_status
    from public.payments p where p.contract_id = contract_key for update;
  if decision = 'cancel' and current_payment_status = 'paid' then
    raise exception 'A funded dispute must be resumed or refunded; held funds cannot be abandoned';
  end if;
  if decision = 'refund' and coalesce(current_payment_status, '') <> 'paid' then
    raise exception 'Only confirmed held funds can be refunded';
  end if;

  update public.contracts set
    status = case when decision = 'resume' then 'in_progress'::public.contract_status else 'cancelled'::public.contract_status end,
    cancelled_at = case when decision in ('cancel','refund') then now() else cancelled_at end,
    cancellation_reason = case when decision in ('cancel','refund') then trim(note_text) else cancellation_reason end,
    dispute_resolved_at = now(),
    dispute_resolved_by = (select auth.uid()),
    dispute_resolution = trim(note_text)
    where id = contract_key;

  if decision = 'refund' then
    update public.payments set status = 'refunded', updated_at = now()
      where contract_id = contract_key and status = 'paid';
    if not found then raise exception 'Held funds could not be marked refunded'; end if;
  end if;

  insert into public.contract_events(contract_id, actor_id, event_type, message)
    values (contract_key, (select auth.uid()),
      case when decision = 'resume' then 'started' else 'cancelled' end,
      'Administrator decision: ' || decision || '. ' || trim(note_text));
  insert into public.notifications(user_id,title,body,route,kind) values
    (target.student_id, 'Dispute Resolved', trim(note_text), '/contract/' || contract_key, 'proposals'),
    (target.business_id, 'Dispute Resolved', trim(note_text), '/contract/' || contract_key, 'proposals');
end; $$;

revoke execute on function public.admin_resolve_dispute(bigint,text,text)
  from public, anon;
grant execute on function public.admin_resolve_dispute(bigint,text,text)
  to authenticated;
