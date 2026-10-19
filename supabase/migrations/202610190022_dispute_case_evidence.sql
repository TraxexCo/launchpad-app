-- Give administrators one auditable, read-only case file for contract disputes.
-- The function deliberately returns evidence, not an automated verdict.

create policy messages_admin_read on public.messages for select to authenticated
  using (private.is_admin());

create policy contract_files_admin_read on storage.objects for select to authenticated
  using (bucket_id = 'contract-deliverables' and private.is_admin());

create or replace function public.admin_get_dispute_case(contract_key bigint)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  if not private.is_admin() then
    raise insufficient_privilege using message = 'Administrator access required';
  end if;
  if not exists (select 1 from public.contracts c where c.id = contract_key) then
    raise exception 'Contract not found';
  end if;

  select jsonb_build_object(
    'contract', jsonb_build_object(
      'id', c.id, 'status', c.status, 'agreed_at', c.agreed_at,
      'funded_at', c.funded_at, 'started_at', c.started_at,
      'completed_at', c.completed_at, 'disputed_at', c.disputed_at,
      'disputed_by', c.disputed_by, 'dispute_reason', c.dispute_reason,
      'revision_message', c.revision_message
    ),
    'job', jsonb_build_object(
      'id', j.id, 'title', j.title, 'description', j.description,
      'budget', j.budget, 'timeline', j.timeline, 'location', j.location
    ),
    'proposal', jsonb_build_object(
      'id', p.id, 'pitch_text', p.pitch_text,
      'proposed_budget', p.proposed_budget,
      'estimated_timeline_weeks', p.estimated_timeline_weeks,
      'created_at', p.created_at
    ),
    'student', jsonb_build_object(
      'id', student.id, 'full_name', student.full_name
    ),
    'business', jsonb_build_object(
      'id', business.id, 'full_name', business.full_name,
      'business_name', bp.business_name
    ),
    'payment', coalesce((
      select jsonb_build_object(
        'status', pay.status, 'amount', pay.amount,
        'reference_number', pay.reference_number,
        'payment_method', pay.payment_method, 'paid_at', pay.paid_at,
        'released_at', pay.released_at
      ) from public.payments pay where pay.contract_id = c.id
    ), '{}'::jsonb),
    'messages', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', m.id, 'sender_id', m.sender_id,
        'sender_name', mp.full_name, 'body', m.body,
        'created_at', m.created_at
      ) order by m.created_at)
      from public.messages m
      join public.profiles mp on mp.id = m.sender_id
      where m.contract_id = c.id
    ), '[]'::jsonb),
    'deliverables', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', d.id, 'submission_number', d.submission_number,
        'title', d.title, 'summary', d.summary, 'link_url', d.link_url,
        'storage_path', d.storage_path,
        'original_file_name', d.original_file_name,
        'submitted_by', d.submitted_by, 'created_at', d.created_at
      ) order by d.submission_number)
      from public.contract_deliverables d where d.contract_id = c.id
    ), '[]'::jsonb),
    'events', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', e.id, 'event_type', e.event_type, 'message', e.message,
        'actor_id', e.actor_id, 'actor_name', ep.full_name,
        'created_at', e.created_at
      ) order by e.created_at)
      from public.contract_events e
      left join public.profiles ep on ep.id = e.actor_id
      where e.contract_id = c.id
    ), '[]'::jsonb)
  ) into result
  from public.contracts c
  join public.jobs j on j.id = c.job_id
  join public.proposals p on p.id = c.proposal_id
  join public.profiles student on student.id = c.student_id
  join public.profiles business on business.id = c.business_id
  left join public.business_profiles bp on bp.user_id = c.business_id
  where c.id = contract_key;

  return result;
end; $$;

revoke execute on function public.admin_get_dispute_case(bigint) from public, anon;
grant execute on function public.admin_get_dispute_case(bigint) to authenticated;
