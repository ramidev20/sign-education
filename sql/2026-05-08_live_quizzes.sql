-- Live collaborative quizzes for brainstorming strategy.
-- Fixed FK type mismatch: users.id is uuid, so teacher_id/student_id must be uuid.
-- Safe to re-run.

drop table if exists public.live_quiz_entries cascade;
drop table if exists public.live_quizzes cascade;

create table public.live_quizzes (
  quiz_id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.users(id) on delete cascade,
  class_group_id text not null references public.class_groups(class_group_id) on delete cascade,
  title text not null,
  prompt_text text not null,
  visual_prompt_url text,
  strategy_key text not null default 'brainstorming_visual',
  status text not null default 'active' check (status in ('active', 'closed')),
  created_at timestamptz not null default now(),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  time_limit_minutes int
);

create index live_quizzes_teacher_idx
  on public.live_quizzes (teacher_id, created_at desc);

create index live_quizzes_group_status_idx
  on public.live_quizzes (class_group_id, status, created_at desc);

create table public.live_quiz_entries (
  entry_id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.live_quizzes(quiz_id) on delete cascade,
  student_id uuid not null references public.users(id) on delete cascade,
  student_name text not null,
  entry_text text not null,
  entry_type text not null default 'text',
  created_at timestamptz not null default now()
);

create index live_quiz_entries_quiz_idx
  on public.live_quiz_entries (quiz_id, created_at asc);

alter table public.live_quizzes enable row level security;
alter table public.live_quiz_entries enable row level security;

drop policy if exists live_quizzes_select on public.live_quizzes;
create policy live_quizzes_select
on public.live_quizzes
for select
to authenticated
using (
  teacher_id = auth.uid()
  or exists (
    select 1
    from public.class_group_members cgm
    where cgm.class_group_id = live_quizzes.class_group_id
      and cgm.user_id = auth.uid()
  )
);

drop policy if exists live_quizzes_insert on public.live_quizzes;
create policy live_quizzes_insert
on public.live_quizzes
for insert
to authenticated
with check (
  teacher_id = auth.uid()
  and exists (
    select 1
    from public.class_groups cg
    where cg.class_group_id = live_quizzes.class_group_id
      and cg.teacher_id = auth.uid()
  )
);

drop policy if exists live_quizzes_update on public.live_quizzes;
create policy live_quizzes_update
on public.live_quizzes
for update
to authenticated
using (teacher_id = auth.uid())
with check (teacher_id = auth.uid());

drop policy if exists live_quiz_entries_select on public.live_quiz_entries;
create policy live_quiz_entries_select
on public.live_quiz_entries
for select
to authenticated
using (
  exists (
    select 1
    from public.live_quizzes lq
    where lq.quiz_id = live_quiz_entries.quiz_id
      and (
        lq.teacher_id = auth.uid()
        or exists (
          select 1
          from public.class_group_members cgm
          where cgm.class_group_id = lq.class_group_id
            and cgm.user_id = auth.uid()
        )
      )
  )
);

drop policy if exists live_quiz_entries_insert on public.live_quiz_entries;
create policy live_quiz_entries_insert
on public.live_quiz_entries
for insert
to authenticated
with check (
  student_id = auth.uid()
  and exists (
    select 1
    from public.live_quizzes lq
    where lq.quiz_id = live_quiz_entries.quiz_id
      and lq.status = 'active'
      and exists (
        select 1
        from public.class_group_members cgm
        where cgm.class_group_id = lq.class_group_id
          and cgm.user_id = auth.uid()
      )
  )
);
