-- Sign Education: lesson strategies (multiple per lesson)
-- Generated on 2026-04-18
-- Target: PostgreSQL (Supabase / PostgREST compatible)

begin;

create table if not exists public.lesson_strategies (
  lesson_strategy_id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(lesson_id) on delete cascade,
  strategy_type text not null,
  title text,
  content_json jsonb not null default '{}'::jsonb,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists lesson_strategies_lesson_id_idx
  on public.lesson_strategies (lesson_id);

create index if not exists lesson_strategies_lesson_id_created_at_idx
  on public.lesson_strategies (lesson_id, created_at);

-- updated_at automation (relies on public.set_updated_at() from 2026-04-15 script)
drop trigger if exists set_updated_at_lesson_strategies on public.lesson_strategies;
create trigger set_updated_at_lesson_strategies
before update on public.lesson_strategies
for each row execute function public.set_updated_at();

commit;

-- IMPORTANT:
-- Enable RLS + policies in Supabase dashboard as needed.
-- Suggested (high level):
-- - Teachers can manage (select/insert/update/delete) strategies for their lessons.
-- - Students can select strategies for lessons in their class groups.

