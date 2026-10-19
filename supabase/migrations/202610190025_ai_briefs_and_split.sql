-- Classroom-only split accounting and auditable AI case briefs.
alter table public.payments
  add column if not exists released_amount numeric(12,2) not null default 0 check(released_amount>=0),
  add column if not exists refunded_amount numeric(12,2) not null default 0 check(refunded_amount>=0);
update public.payments set released_amount=amount where status='released' and released_amount=0;
update public.payments set refunded_amount=amount where status='refunded' and refunded_amount=0;

create table public.dispute_ai_briefs(
  id bigint generated always as identity primary key,
  contract_id bigint not null references public.contracts(id) on delete cascade,
  generated_by uuid not null references public.admin_users(user_id),
  model text not null,
  brief jsonb not null,
  generated_at timestamptz not null default now()
);
alter table public.dispute_ai_briefs enable row level security;
revoke all on public.dispute_ai_briefs from anon,authenticated;
grant select on public.dispute_ai_briefs to authenticated;
create policy dispute_ai_briefs_admin_read on public.dispute_ai_briefs for select to authenticated using(private.is_admin());

create or replace function public.admin_split_dispute(contract_key bigint,student_amount numeric,note_text text)
returns void language plpgsql security definer set search_path='' as $$
declare target public.contracts%rowtype; declare payment_row public.payments%rowtype;
begin
 if not private.is_admin() then raise insufficient_privilege using message='Administrator access required'; end if;
 select * into target from public.contracts c where c.id=contract_key for update;
 if not found or target.status<>'disputed' then raise exception 'Open dispute not found'; end if;
 if char_length(trim(coalesce(note_text,'')))<10 then raise exception 'Add a resolution note'; end if;
 select * into payment_row from public.payments p where p.contract_id=contract_key for update;
 if not found or payment_row.status<>'paid' then raise exception 'Confirmed held funds are required'; end if;
 if student_amount<=0 or student_amount>=payment_row.amount then raise exception 'Student amount must be greater than zero and less than the held payment'; end if;
 update public.payments set status='released',released_at=now(),updated_at=now(),
   released_amount=round(student_amount,2),refunded_amount=round(amount-student_amount,2)
   where id=payment_row.id;
 update public.contracts set status='completed',completed_at=now(),dispute_resolved_at=now(),
   dispute_resolved_by=(select auth.uid()),dispute_resolution=trim(note_text),revision_message=null
   where id=contract_key;
 update public.jobs set status='closed' where id=target.job_id;
 insert into public.contract_events(contract_id,actor_id,event_type,message) values(contract_key,(select auth.uid()),'completed',
   'Administrator split decision: PHP '||round(student_amount,2)||' released; PHP '||round(payment_row.amount-student_amount,2)||' refunded. '||trim(note_text));
 insert into public.notifications(user_id,title,body,route,kind) values
   (target.student_id,'Dispute Resolved with Split','PHP '||round(student_amount,2)||' was recorded for release. '||trim(note_text),'/contract/'||contract_key,'proposals'),
   (target.business_id,'Dispute Resolved with Split','PHP '||round(payment_row.amount-student_amount,2)||' was recorded for refund. '||trim(note_text),'/contract/'||contract_key,'proposals');
end; $$;
revoke execute on function public.admin_split_dispute(bigint,numeric,text) from public,anon;
grant execute on function public.admin_split_dispute(bigint,numeric,text) to authenticated;
