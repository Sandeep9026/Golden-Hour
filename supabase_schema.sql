create extension if not exists pgcrypto;
create extension if not exists cube;
create extension if not exists earthdistance;

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role text not null default 'driver' check (role in ('driver', 'first_aider', 'dispatcher')),
  is_trained boolean not null default false,
  latitude double precision,
  longitude double precision,
  vehicle_number text,
  created_at timestamptz not null default now()
);

create table if not exists accident_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references profiles(id) on delete set null,
  assigned_responder_id uuid references profiles(id) on delete set null,
  latitude double precision not null,
  longitude double precision not null,
  severity text not null check (severity in ('low', 'medium', 'high')),
  confidence_score double precision not null default 0,
  g_force double precision not null default 0,
  camera_summary text,
  status text not null default 'reported' check (status in ('reported', 'acknowledged', 'closed')),
  created_at timestamptz not null default now()
);

create table if not exists driver_notifications (
  id bigint generated always as identity primary key,
  user_id uuid references profiles(id) on delete set null,
  latitude double precision not null,
  longitude double precision not null,
  severity text not null,
  message text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists emergency_call_logs (
  id bigint generated always as identity primary key,
  created_by uuid references profiles(id) on delete set null,
  message text not null,
  created_at timestamptz not null default now()
);

create table if not exists incident_updates (
  id bigint generated always as identity primary key,
  accident_report_id uuid not null references accident_reports(id) on delete cascade,
  update_type text not null check (update_type in ('reported', 'acknowledged', 'assigned', 'closed', 'note')),
  message text not null,
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists user_settings (
  user_id uuid primary key references profiles(id) on delete cascade,
  alerts_enabled boolean not null default true,
  auto_call_enabled boolean not null default true,
  sound_enabled boolean not null default true,
  vibration_enabled boolean not null default true,
  preferred_radius_meters integer not null default 500 check (preferred_radius_meters between 100 and 5000),
  onboarding_completed boolean not null default false,
  safety_disclaimer_accepted boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists device_registrations (
  id bigint generated always as identity primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'web')),
  device_name text,
  push_token text,
  app_version text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists emergency_contacts (
  id bigint generated always as identity primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  contact_name text not null,
  phone text not null,
  relation text not null,
  notify_on_sos boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists support_requests (
  id bigint generated always as identity primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  category text not null check (category in ('bug', 'feedback', 'feature', 'safety', 'account')),
  subject text not null,
  message text not null,
  status text not null default 'open' check (status in ('open', 'in_review', 'resolved')),
  created_at timestamptz not null default now()
);

create index if not exists idx_profiles_role_training on profiles(role, is_trained);
create index if not exists idx_profiles_location on profiles(latitude, longitude);
create index if not exists idx_accident_reports_status_created_at on accident_reports(status, created_at desc);
create index if not exists idx_accident_reports_location on accident_reports(latitude, longitude);
create index if not exists idx_incident_updates_report_created_at on incident_updates(accident_report_id, created_at desc);
create index if not exists idx_device_registrations_user_id on device_registrations(user_id, last_seen_at desc);
create index if not exists idx_driver_notifications_user_created_at on driver_notifications(user_id, created_at desc);
create index if not exists idx_emergency_contacts_user_id on emergency_contacts(user_id, created_at desc);
create index if not exists idx_support_requests_user_created_at on support_requests(user_id, created_at desc);

create or replace function nearest_first_aider(user_lat double precision, user_lng double precision)
returns table (
  id uuid,
  full_name text,
  phone text,
  distance_meters double precision
)
language sql
as $$
  select
    p.id,
    p.full_name,
    p.phone,
    earth_distance(
      ll_to_earth(user_lat, user_lng),
      ll_to_earth(p.latitude, p.longitude)
    ) as distance_meters
  from profiles p
  where p.role = 'first_aider'
    and p.is_trained = true
    and p.latitude is not null
    and p.longitude is not null
  order by distance_meters asc
  limit 1;
$$;

create or replace function nearby_accident_alerts(
  user_lat double precision,
  user_lng double precision,
  radius_meters double precision default 500
)
returns table (
  id uuid,
  latitude double precision,
  longitude double precision,
  severity text,
  distance_meters double precision,
  created_at timestamptz
)
language sql
as $$
  select
    a.id,
    a.latitude,
    a.longitude,
    a.severity,
    earth_distance(
      ll_to_earth(user_lat, user_lng),
      ll_to_earth(a.latitude, a.longitude)
    ) as distance_meters,
    a.created_at
  from accident_reports a
  where a.status <> 'closed'
    and earth_distance(
      ll_to_earth(user_lat, user_lng),
      ll_to_earth(a.latitude, a.longitude)
    ) <= radius_meters
  order by created_at desc;
$$;

alter table profiles enable row level security;
alter table accident_reports enable row level security;
alter table driver_notifications enable row level security;
alter table emergency_call_logs enable row level security;
alter table incident_updates enable row level security;
alter table user_settings enable row level security;
alter table device_registrations enable row level security;
alter table emergency_contacts enable row level security;
alter table support_requests enable row level security;

drop policy if exists "profiles read own and responders" on profiles;
drop policy if exists "profiles insert own" on profiles;
drop policy if exists "profiles update own" on profiles;
drop policy if exists "accident reports insert authenticated" on accident_reports;
drop policy if exists "accident reports read authenticated" on accident_reports;
drop policy if exists "driver notifications read authenticated" on driver_notifications;
drop policy if exists "driver notifications insert authenticated" on driver_notifications;
drop policy if exists "call logs insert authenticated" on emergency_call_logs;
drop policy if exists "incident updates read authenticated" on incident_updates;
drop policy if exists "incident updates insert authenticated" on incident_updates;
drop policy if exists "user settings read own" on user_settings;
drop policy if exists "user settings upsert own" on user_settings;
drop policy if exists "device registrations read own" on device_registrations;
drop policy if exists "device registrations write own" on device_registrations;
drop policy if exists "emergency contacts read own" on emergency_contacts;
drop policy if exists "emergency contacts write own" on emergency_contacts;
drop policy if exists "support requests read own" on support_requests;
drop policy if exists "support requests write own" on support_requests;

create policy "profiles read own and responders"
on profiles
for select
using (auth.uid() = id or role in ('first_aider', 'dispatcher'));

create policy "profiles insert own"
on profiles
for insert
with check (auth.uid() = id);

create policy "profiles update own"
on profiles
for update
using (auth.uid() = id);

create policy "accident reports insert authenticated"
on accident_reports
for insert
to authenticated
with check (true);

create policy "accident reports read authenticated"
on accident_reports
for select
to authenticated
using (true);

create policy "driver notifications read authenticated"
on driver_notifications
for select
to authenticated
using (true);

create policy "driver notifications insert authenticated"
on driver_notifications
for insert
to authenticated
with check (true);

create policy "call logs insert authenticated"
on emergency_call_logs
for insert
to authenticated
with check (true);

create policy "incident updates read authenticated"
on incident_updates
for select
to authenticated
using (true);

create policy "incident updates insert authenticated"
on incident_updates
for insert
to authenticated
with check (true);

create policy "user settings read own"
on user_settings
for select
to authenticated
using (auth.uid() = user_id);

create policy "user settings upsert own"
on user_settings
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "device registrations read own"
on device_registrations
for select
to authenticated
using (auth.uid() = user_id);

create policy "device registrations write own"
on device_registrations
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "emergency contacts read own"
on emergency_contacts
for select
to authenticated
using (auth.uid() = user_id);

create policy "emergency contacts write own"
on emergency_contacts
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "support requests read own"
on support_requests
for select
to authenticated
using (auth.uid() = user_id);

create policy "support requests write own"
on support_requests
for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.profiles (id, full_name, role, is_trained)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''), 'driver', false)
  on conflict (id) do nothing;

  insert into public.user_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function handle_new_user();
