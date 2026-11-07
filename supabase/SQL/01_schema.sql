-- Our Family Calendar: tables. Supabase -> SQL Editor -> paste -> Run. Run once, on a new project.

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Our Family',
  created_at timestamptz not null default now()
);

-- 'parent' = full control. 'device' = a household-signed-in tablet/phone (can view, tick things off, add/edit items).
create table public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('parent','device')),
  created_at timestamptz not null default now(),
  primary key (household_id, user_id)
);
create index on public.household_members (user_id);

create table public.invites (
  code text primary key default substr(replace(gen_random_uuid()::text,'-',''),1,8),
  household_id uuid not null references public.households(id) on delete cascade,
  role text not null check (role in ('parent','device')),
  expires_at timestamptz not null default now() + interval '2 days',
  created_by uuid not null default auth.uid()
);

create table public.people (
  household_id uuid not null references public.households(id) on delete cascade,
  id text not null,
  name text not null,
  color text not null default '#7c5cff',
  primary key (household_id, id)
);

create table public.items (
  household_id uuid not null references public.households(id) on delete cascade,
  id text not null,
  title text not null,
  type text not null check (type in ('event','homework','chore')),
  who text[] not null default '{all}',
  date date not null,
  time text not null default '',
  repeat text not null default 'none' check (repeat in ('none','daily','weekdays','weekly')),
  notes text not null default '',
  color text not null default '#7c5cff',
  pay numeric(8,2) not null default 0 check (pay >= 0),
  skip date[] not null default '{}',
  until date,
  source text not null default 'app' check (source in ('app','apple')),
  updated_at timestamptz not null default now(),
  primary key (household_id, id)
);

create table public.completions (
  household_id uuid not null,
  item_id text not null,
  day date not null,
  done_at timestamptz not null default now(),
  done_by uuid default auth.uid(),
  primary key (household_id, item_id, day),
  foreign key (household_id, item_id) references public.items(household_id, id) on delete cascade
);

create table public.payouts (
  household_id uuid not null references public.households(id) on delete cascade,
  id text not null,
  who text not null,
  amount numeric(8,2) not null check (amount > 0),
  paid_at timestamptz not null default now(),
  paid_by uuid default auth.uid(),
  primary key (household_id, id)
);

create table public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  person_id text,
  endpoint text not null unique,
  p256dh text not null,
  auth text not null,
  detail text not null default 'generic' check (detail in ('generic','full')),
  created_at timestamptz not null default now(),
  last_ok_at timestamptz
);

-- Secrets live here (the iCloud calendar link). RLS on, no policies, no grants: only Edge Functions (service role) can read it.
create table public.integrations (
  household_id uuid primary key references public.households(id) on delete cascade,
  apple_feed_url text,
  apple_last_sync timestamptz,
  apple_last_error text
);

create function public.touch_updated_at() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;
create trigger items_touch before update on public.items for each row execute function public.touch_updated_at();

alter publication supabase_realtime add table public.items, public.completions, public.people, public.payouts;
