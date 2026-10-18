-- Keep a contracted job visible to the two people who own its workspace.
-- This lets completed contracts retain their real project title and category.

drop policy if exists jobs_read on public.jobs;
create policy jobs_read on public.jobs
for select to authenticated
using (
  status = 'open'
  or business_id = (select auth.uid())
  or exists (
    select 1
    from public.proposals p
    where p.job_id = jobs.id
      and p.student_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.contracts c
    where c.job_id = jobs.id
      and (
        c.student_id = (select auth.uid())
        or c.business_id = (select auth.uid())
      )
  )
);
