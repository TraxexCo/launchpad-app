-- Structured responses and private evidence for both sides of a dispute.
alter table public.contracts add column if not exists dispute_deadline timestamptz;

create table public.dispute_evidence (
  id bigint generated always as identity primary key,
  contract_id bigint not null references public.contracts(id) on delete cascade,
  submitted_by uuid not null references public.profiles(id),
  statement text not null check (char_length(trim(statement)) between 20 and 5000),
  storage_path text, original_file_name text,
  created_at timestamptz not null default now()
);
create index dispute_evidence_case_idx on public.dispute_evidence(contract_id,created_at);
alter table public.dispute_evidence enable row level security;
revoke all on public.dispute_evidence from anon,authenticated;
grant select on public.dispute_evidence to authenticated;
create policy dispute_evidence_participant_read on public.dispute_evidence for select to authenticated using (private.participates_in_contract(contract_id));
create policy dispute_evidence_admin_read on public.dispute_evidence for select to authenticated using (private.is_admin());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('dispute-evidence','dispute-evidence',false,10485760,array['application/pdf','application/zip','image/jpeg','image/png','text/plain'])
on conflict(id) do update set public=false,file_size_limit=10485760,allowed_mime_types=excluded.allowed_mime_types;
create policy dispute_files_participant_read on storage.objects for select to authenticated using (
  bucket_id='dispute-evidence' and (storage.foldername(name))[1] ~ '^[0-9]+$'
  and private.participates_in_contract(((storage.foldername(name))[1])::bigint));
create policy dispute_files_admin_read on storage.objects for select to authenticated using (bucket_id='dispute-evidence' and private.is_admin());
create policy dispute_files_participant_upload on storage.objects for insert to authenticated with check (
  bucket_id='dispute-evidence' and (storage.foldername(name))[1] ~ '^[0-9]+$'
  and (storage.foldername(name))[2]=(select auth.uid())::text
  and exists(select 1 from public.contracts c where c.id=((storage.foldername(name))[1])::bigint
    and (select auth.uid()) in(c.student_id,c.business_id) and c.status='disputed'
    and now()<=coalesce(c.dispute_deadline,now()+interval '1 minute')));

create or replace function public.submit_dispute_evidence(contract_key bigint,statement_text text,evidence_storage_path text default null,evidence_file_name text default null)
returns bigint language plpgsql security definer set search_path='' as $$
declare target public.contracts%rowtype; declare result_id bigint;
begin
 select * into target from public.contracts c where c.id=contract_key for update;
 if not found then raise exception 'Contract not found'; end if;
 if (select auth.uid()) not in(target.student_id,target.business_id) then raise insufficient_privilege using message='Only project participants can submit dispute evidence'; end if;
 if target.status<>'disputed' then raise exception 'This contract is not under dispute'; end if;
 if target.dispute_deadline is not null and now()>target.dispute_deadline then raise exception 'The evidence response window has closed'; end if;
 if char_length(trim(coalesce(statement_text,'')))<20 then raise exception 'Explain your position in at least 20 characters'; end if;
 if evidence_storage_path is not null and evidence_storage_path not like (contract_key::text||'/'||(select auth.uid())::text||'/%') then raise insufficient_privilege using message='Invalid dispute evidence path'; end if;
 insert into public.dispute_evidence(contract_id,submitted_by,statement,storage_path,original_file_name)
 values(contract_key,(select auth.uid()),trim(statement_text),nullif(trim(coalesce(evidence_storage_path,'')),''),nullif(trim(coalesce(evidence_file_name,'')),'')) returning id into result_id;
 insert into public.notifications(user_id,title,body,route,kind) values(case when (select auth.uid())=target.student_id then target.business_id else target.student_id end,'New Dispute Evidence','The other party added a statement or file to the dispute.','/contract/'||contract_key,'proposals');
 return result_id;
end; $$;
revoke execute on function public.submit_dispute_evidence(bigint,text,text,text) from public,anon;
grant execute on function public.submit_dispute_evidence(bigint,text,text,text) to authenticated;

create or replace function public.open_contract_dispute(contract_key bigint,reason_text text)
returns void language plpgsql security definer set search_path='' as $$
declare target public.contracts%rowtype; declare recipient uuid;
begin
 select * into target from public.contracts c where c.id=contract_key for update;
 if not found then raise exception 'Contract not found'; end if;
 if (select auth.uid()) not in(target.student_id,target.business_id) then raise insufficient_privilege using message='Only project participants can open a dispute'; end if;
 if target.status in('completed','cancelled','disputed') then raise exception 'This contract cannot be disputed'; end if;
 if char_length(trim(coalesce(reason_text,'')))<20 then raise exception 'Describe the dispute in at least 20 characters'; end if;
 recipient:=case when (select auth.uid())=target.student_id then target.business_id else target.student_id end;
 update public.contracts set status='disputed',disputed_at=now(),disputed_by=(select auth.uid()),dispute_reason=trim(reason_text),dispute_deadline=now()+interval '48 hours' where id=contract_key;
 insert into public.contract_events(contract_id,actor_id,event_type,message) values(contract_key,(select auth.uid()),'disputed',trim(reason_text));
 insert into public.dispute_evidence(contract_id,submitted_by,statement) values(contract_key,(select auth.uid()),trim(reason_text));
 insert into public.notifications(user_id,title,body,route,kind) values(recipient,'Contract Disputed','Respond with your statement and evidence within 48 hours.','/contract/'||contract_key,'proposals');
end; $$;
revoke execute on function public.open_contract_dispute(bigint,text) from public,anon;
grant execute on function public.open_contract_dispute(bigint,text) to authenticated;
