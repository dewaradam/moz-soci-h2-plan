-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Profiles table (user roles)
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  email text unique,
  full_name text,
  role text default 'pending',
  created_at timestamp default now()
);

-- Plan state (singleton JSONB document)
create table if not exists plan_state (
  id int primary key default 1,
  data jsonb not null,
  last_edit_at timestamp default now(),
  last_edit_by uuid references profiles(id)
);

-- Comments on cards
create table if not exists comments (
  id uuid primary key default uuid_generate_v4(),
  card_id text not null,
  author_id uuid references profiles(id) on delete cascade,
  author_name text,
  author_role text,
  text text not null,
  created_at timestamp default now()
);

-- RLS: Enable on all tables
alter table profiles enable row level security;
alter table plan_state enable row level security;
alter table comments enable row level security;

-- RLS Policies: profiles
create policy "Users can view their own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "Editors can view all profiles"
  on profiles for select
  using ((select role from profiles where id = auth.uid()) = 'editor');

create policy "Editors can update roles"
  on profiles for update
  using ((select role from profiles where id = auth.uid()) = 'editor')
  with check ((select role from profiles where id = auth.uid()) = 'editor');

-- RLS Policies: plan_state
create policy "Authenticated users can read"
  on plan_state for select
  using ((select role from profiles where id = auth.uid()) in ('viewer', 'editor'));

create policy "Editors can update"
  on plan_state for update
  using ((select role from profiles where id = auth.uid()) = 'editor')
  with check ((select role from profiles where id = auth.uid()) = 'editor');

-- RLS Policies: comments
create policy "Authenticated users can read"
  on comments for select
  using ((select role from profiles where id = auth.uid()) in ('viewer', 'editor'));

create policy "Authenticated users can insert"
  on comments for insert
  with check ((select role from profiles where id = auth.uid()) in ('viewer', 'editor'));

create policy "Users can delete own comments"
  on comments for delete
  using (auth.uid() = author_id);

create policy "Editors can delete any comment"
  on comments for delete
  using ((select role from profiles where id = auth.uid()) = 'editor');

-- Auto-create profile on signup
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (new.id, new.email, new.user_metadata->>'full_name', 'pending');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
