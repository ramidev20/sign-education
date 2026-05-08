-- Sign Education: replace lesson PDF workflow with text content
-- Generated on 2026-05-07
-- Target: PostgreSQL (Supabase / PostgREST compatible)

begin;

-- The app now uses `description` as the lesson's main text content.
-- This migration only removes the legacy PDF storage URL column.
alter table public.lessons
  drop column if exists file_url;

commit;
