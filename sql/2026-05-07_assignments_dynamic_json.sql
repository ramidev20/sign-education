-- Sign Education: dynamic assignments (questions + answers as JSON)
-- Generated on 2026-05-07
-- Target: PostgreSQL (Supabase / PostgREST compatible)

begin;

alter table public.assignments
  add column if not exists assignment_content_json jsonb not null default '{}'::jsonb;

alter table public.assignments_deliveries
  add column if not exists answers_json jsonb not null default '{}'::jsonb;

commit;

