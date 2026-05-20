-- Final profile schema update for teachers and students.
-- Run this on your Supabase/Postgres database.
-- This keeps created_at for audit/history, but removes fields no longer wanted in profile.

alter table public.users
  add column if not exists phone text,
  add column if not exists bio text,
  add column if not exists school_name text,
  add column if not exists specialization text,
  add column if not exists years_experience integer,
  add column if not exists guardian_name text,
  add column if not exists guardian_phone text,
  add column if not exists student_number text;

alter table public.users
  drop column if exists city,
  drop column if exists office_hours,
  drop column if exists points;

comment on column public.users.phone is
  'Shared profile field for teacher or student phone number.';
comment on column public.users.bio is
  'Shared short profile description.';
comment on column public.users.school_name is
  'Shared school/institution name.';
comment on column public.users.specialization is
  'Teacher-only teaching specialization.';
comment on column public.users.years_experience is
  'Teacher-only years of experience.';
comment on column public.users.guardian_name is
  'Student-only parent or guardian name.';
comment on column public.users.guardian_phone is
  'Student-only parent or guardian phone number.';
comment on column public.users.student_number is
  'Student-only school registration number.';

alter table public.users
  drop constraint if exists users_years_experience_non_negative;

alter table public.users
  add constraint users_years_experience_non_negative
  check (years_experience is null or years_experience >= 0);

-- Optional backfill examples:
-- update public.users set school_name = 'My School', phone = '+213...' where id = 'USER_ID';
-- update public.users set specialization = 'Arabic Language', years_experience = 8 where role = 'teacher';
-- update public.users set guardian_name = 'Parent Name', guardian_phone = '+213...' where role = 'student';
