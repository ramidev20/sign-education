-- Sign Education: production + performance hardening
-- Generated on 2026-04-15
-- Target: PostgreSQL (Supabase / PostgREST compatible)

begin;

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Timestamps / audit columns (needed by the app's sync queries)
-- ---------------------------------------------------------------------------

-- assignment_shares: app filters by created_at in lib/auth.dart
alter table public.assignment_shares
  add column if not exists created_at timestamp with time zone not null default now();

alter table public.assignment_shares
  add column if not exists updated_at timestamp with time zone not null default now();

-- assignments_deliveries: app reads created_at in lib/auth.dart (teacher notifications)
alter table public.assignments_deliveries
  add column if not exists created_at timestamp with time zone;

alter table public.assignments_deliveries
  add column if not exists updated_at timestamp with time zone;

update public.assignments_deliveries
set created_at = coalesce(created_at, delivery_date, now())
where created_at is null;

alter table public.assignments_deliveries
  alter column created_at set default now(),
  alter column created_at set not null;

update public.assignments_deliveries
set updated_at = coalesce(updated_at, created_at, now())
where updated_at is null;

alter table public.assignments_deliveries
  alter column updated_at set default now(),
  alter column updated_at set not null;

-- lessons
alter table public.lessons
  add column if not exists updated_at timestamp with time zone;

update public.lessons
set created_at = coalesce(created_at, now())
where created_at is null;

alter table public.lessons
  alter column created_at set default now(),
  alter column created_at set not null;

update public.lessons
set updated_at = coalesce(updated_at, created_at, now())
where updated_at is null;

alter table public.lessons
  alter column updated_at set default now(),
  alter column updated_at set not null;

-- assignments (also used for delivery counts in the teacher UI)
alter table public.assignments
  add column if not exists updated_at timestamp with time zone;

update public.assignments
set created_at = coalesce(created_at, now())
where created_at is null;

alter table public.assignments
  alter column created_at set default now(),
  alter column created_at set not null;

update public.assignments
set complete_at = coalesce(complete_at, created_at, now())
where complete_at is null;

alter table public.assignments
  alter column complete_at set not null;

update public.assignments
set submissions_count = coalesce(submissions_count, 0)
where submissions_count is null;

alter table public.assignments
  alter column submissions_count set default 0,
  alter column submissions_count set not null;

update public.assignments
set updated_at = coalesce(updated_at, created_at, now())
where updated_at is null;

alter table public.assignments
  alter column updated_at set default now(),
  alter column updated_at set not null;

-- class_groups
alter table public.class_groups
  add column if not exists updated_at timestamp with time zone;

update public.class_groups
set created_at = coalesce(created_at, now())
where created_at is null;

alter table public.class_groups
  alter column created_at set default now(),
  alter column created_at set not null;

update public.class_groups
set updated_at = coalesce(updated_at, created_at, now())
where updated_at is null;

alter table public.class_groups
  alter column updated_at set default now(),
  alter column updated_at set not null;

-- messages
update public.messages
set created_at = coalesce(created_at, now())
where created_at is null;

alter table public.messages
  alter column created_at set default now(),
  alter column created_at set not null;

-- users: helpful for ops/debugging; safe defaults
alter table public.users
  add column if not exists created_at timestamp with time zone not null default now();

alter table public.users
  add column if not exists updated_at timestamp with time zone not null default now();

-- class_group_members: helpful for ops/debugging
alter table public.class_group_members
  add column if not exists created_at timestamp with time zone not null default now();

-- ---------------------------------------------------------------------------
-- updated_at automation
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_updated_at_assignment_shares on public.assignment_shares;
create trigger set_updated_at_assignment_shares
before update on public.assignment_shares
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_assignments_deliveries on public.assignments_deliveries;
create trigger set_updated_at_assignments_deliveries
before update on public.assignments_deliveries
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_lessons on public.lessons;
create trigger set_updated_at_lessons
before update on public.lessons
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_assignments on public.assignments;
create trigger set_updated_at_assignments
before update on public.assignments
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_class_groups on public.class_groups;
create trigger set_updated_at_class_groups
before update on public.class_groups
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_users on public.users;
create trigger set_updated_at_users
before update on public.users
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Keep assignments.submissions_count correct (avoid client-side race conditions)
-- ---------------------------------------------------------------------------
create or replace function public.sync_assignment_submissions_count()
returns trigger
language plpgsql
as $$
declare
  target_assignment_id uuid;
begin
  target_assignment_id := coalesce(new.assignment_id, old.assignment_id);

  update public.assignments a
  set submissions_count = (
    select count(*)::int
    from public.assignments_deliveries d
    where d.assignment_id = target_assignment_id
  )
  where a.assignment_id = target_assignment_id;

  return null;
end;
$$;

drop trigger if exists trg_sync_assignment_submissions_count_ins on public.assignments_deliveries;
create trigger trg_sync_assignment_submissions_count_ins
after insert on public.assignments_deliveries
for each row execute function public.sync_assignment_submissions_count();

drop trigger if exists trg_sync_assignment_submissions_count_del on public.assignments_deliveries;
create trigger trg_sync_assignment_submissions_count_del
after delete on public.assignments_deliveries
for each row execute function public.sync_assignment_submissions_count();

-- one-time backfill for existing data
update public.assignments a
set submissions_count = x.cnt
from (
  select assignment_id, count(*)::int as cnt
  from public.assignments_deliveries
  group by assignment_id
) x
where a.assignment_id = x.assignment_id;

update public.assignments
set submissions_count = 0
where submissions_count is null;

-- ---------------------------------------------------------------------------
-- Indexes (common query patterns)
-- ---------------------------------------------------------------------------

-- lessons
create index if not exists idx_lessons_class_group_created_at
  on public.lessons (class_group_id, created_at desc);

create index if not exists idx_lessons_teacher_created_at
  on public.lessons (teacher_id, created_at desc);

-- assignments
create index if not exists idx_assignments_teacher_created_at
  on public.assignments (teacher_id, created_at desc);

create index if not exists idx_assignments_complete_at
  on public.assignments (complete_at);

-- assignment_shares (student inbox)
create unique index if not exists assignment_shares_assignment_user_uniq
  on public.assignment_shares (assignment_id, user_id);

create index if not exists idx_assignment_shares_user_created_at
  on public.assignment_shares (user_id, created_at desc);

create index if not exists idx_assignment_shares_assignment
  on public.assignment_shares (assignment_id);

-- deliveries
create index if not exists idx_deliveries_assignment_delivery_date
  on public.assignments_deliveries (assignment_id, delivery_date desc);

create index if not exists idx_deliveries_user_delivery_date
  on public.assignments_deliveries (user_id, delivery_date desc);

create index if not exists idx_deliveries_created_at
  on public.assignments_deliveries (created_at desc);

-- class memberships
create index if not exists idx_class_group_members_user
  on public.class_group_members (user_id);

create index if not exists idx_class_group_members_group_role
  on public.class_group_members (class_group_id, role);

-- users
create unique index if not exists users_email_lower_uniq
  on public.users (lower(email));

-- ---------------------------------------------------------------------------
-- Data integrity (safe-by-default constraints)
-- Use NOT VALID to avoid failing if legacy data has issues.
-- You can validate later when you are sure the data is clean.
-- ---------------------------------------------------------------------------

do $$
begin
  alter table public.assignment_shares
    add constraint assignment_shares_assignment_id_nn
    check (assignment_id is not null) not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.assignment_shares
    add constraint assignment_shares_user_id_nn
    check (user_id is not null) not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.assignments_deliveries
    add constraint assignments_deliveries_assignment_id_nn
    check (assignment_id is not null) not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.assignments_deliveries
    add constraint assignments_deliveries_user_id_nn
    check (user_id is not null) not valid;
exception when duplicate_object then
  null;
end $$;

-- Foreign keys (for PostgREST embeds like select('users(*)') / select('assignments(*)'))
do $$
begin
  alter table public.assignment_shares
    add constraint assignment_shares_assignment_fk
    foreign key (assignment_id) references public.assignments (assignment_id)
    on delete cascade not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.assignment_shares
    add constraint assignment_shares_user_fk
    foreign key (user_id) references public.users (id)
    on delete cascade not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.assignments_deliveries
    add constraint assignments_deliveries_assignment_fk
    foreign key (assignment_id) references public.assignments (assignment_id)
    on delete cascade not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.assignments_deliveries
    add constraint assignments_deliveries_user_fk
    foreign key (user_id) references public.users (id)
    on delete cascade not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.class_group_members
    add constraint class_group_members_group_fk
    foreign key (class_group_id) references public.class_groups (class_group_id)
    on delete cascade not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.class_group_members
    add constraint class_group_members_user_fk
    foreign key (user_id) references public.users (id)
    on delete cascade not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.lessons
    add constraint lessons_teacher_fk
    foreign key (teacher_id) references public.users (id)
    on delete restrict not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.lessons
    add constraint lessons_class_group_fk
    foreign key (class_group_id) references public.class_groups (class_group_id)
    on delete cascade not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.class_groups
    add constraint class_groups_teacher_fk
    foreign key (teacher_id) references public.users (id)
    on delete restrict not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.messages
    add constraint messages_sender_fk
    foreign key (sender_id) references public.users (id)
    on delete restrict not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.messages
    add constraint messages_receiver_fk
    foreign key (receiver_id) references public.users (id)
    on delete restrict not valid;
exception when duplicate_object then
  null;
end $$;

do $$
begin
  alter table public.messages
    add constraint messages_class_group_fk
    foreign key (class_group_id) references public.class_groups (class_group_id)
    on delete cascade not valid;
exception when duplicate_object then
  null;
end $$;

commit;

-- Optional (run later):
-- alter table public.assignment_shares validate constraint assignment_shares_assignment_id_nn;
-- alter table public.assignment_shares validate constraint assignment_shares_user_id_nn;
-- alter table public.assignments_deliveries validate constraint assignments_deliveries_assignment_id_nn;
-- alter table public.assignments_deliveries validate constraint assignments_deliveries_user_id_nn;
-- alter table public.assignment_shares validate constraint assignment_shares_assignment_fk;
-- alter table public.assignment_shares validate constraint assignment_shares_user_fk;
-- alter table public.assignments_deliveries validate constraint assignments_deliveries_assignment_fk;
-- alter table public.assignments_deliveries validate constraint assignments_deliveries_user_fk;
-- alter table public.class_group_members validate constraint class_group_members_group_fk;
-- alter table public.class_group_members validate constraint class_group_members_user_fk;
-- alter table public.lessons validate constraint lessons_teacher_fk;
-- alter table public.lessons validate constraint lessons_class_group_fk;
-- alter table public.class_groups validate constraint class_groups_teacher_fk;
-- alter table public.messages validate constraint messages_sender_fk;
-- alter table public.messages validate constraint messages_receiver_fk;
-- alter table public.messages validate constraint messages_class_group_fk;
