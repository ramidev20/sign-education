-- Sign Education: RLS policies for lesson_strategies visibility/persistence
-- Generated on 2026-04-18
-- Target: PostgreSQL (Supabase)

begin;

alter table public.lesson_strategies enable row level security;

-- Teachers can manage strategies for their own lessons.
drop policy if exists lesson_strategies_teacher_select on public.lesson_strategies;
create policy lesson_strategies_teacher_select
on public.lesson_strategies
for select
to authenticated
using (
  exists (
    select 1
    from public.lessons l
    where l.lesson_id = lesson_strategies.lesson_id
      and l.teacher_id = auth.uid()
  )
);

drop policy if exists lesson_strategies_teacher_insert on public.lesson_strategies;
create policy lesson_strategies_teacher_insert
on public.lesson_strategies
for insert
to authenticated
with check (
  exists (
    select 1
    from public.lessons l
    where l.lesson_id = lesson_strategies.lesson_id
      and l.teacher_id = auth.uid()
  )
);

drop policy if exists lesson_strategies_teacher_update on public.lesson_strategies;
create policy lesson_strategies_teacher_update
on public.lesson_strategies
for update
to authenticated
using (
  exists (
    select 1
    from public.lessons l
    where l.lesson_id = lesson_strategies.lesson_id
      and l.teacher_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.lessons l
    where l.lesson_id = lesson_strategies.lesson_id
      and l.teacher_id = auth.uid()
  )
);

drop policy if exists lesson_strategies_teacher_delete on public.lesson_strategies;
create policy lesson_strategies_teacher_delete
on public.lesson_strategies
for delete
to authenticated
using (
  exists (
    select 1
    from public.lessons l
    where l.lesson_id = lesson_strategies.lesson_id
      and l.teacher_id = auth.uid()
  )
);

-- Students can view strategies only for lessons in groups they belong to.
drop policy if exists lesson_strategies_student_select on public.lesson_strategies;
create policy lesson_strategies_student_select
on public.lesson_strategies
for select
to authenticated
using (
  exists (
    select 1
    from public.lessons l
    join public.class_group_members m
      on m.class_group_id = l.class_group_id
    where l.lesson_id = lesson_strategies.lesson_id
      and m.user_id = auth.uid()
      and m.role = 'student'
  )
);

commit;

