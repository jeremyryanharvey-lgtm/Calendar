-- Our Family Calendar: row level security, roles and safe functions. Run AFTER 01_schema.sql.

alter table public.households         enable row level security;
alter table public.household_members  enable row level security;
alter table public.invites            enable row level security;
alter table public.people             enable row level security;
alter table public.items              enable row level security;
alter table public.completions        enable row level security;
alter table public.payouts            enable row level security;
alter table public.push_subscriptions enable row level security;
alter table public.integrations       enable row level security;   -- no policies on purpose

revoke all on all tables in schema public from anon;
revoke all on public.integrations from authenticated;

create function public.is_member(h uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.household_members m where m.household_id = h and m.user_id = (select auth.uid()))
$$;
create function public.is_parent(h uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.household_members m where m.household_id = h and m.user_id = (select auth.uid()) and m.role = 'parent')
$$;

-- Reading: any member of the household.
create policy "read households" on public.households        for select to authenticated using (public.is_member(id));
create policy "read members"    on public.household_members for select to authenticated using (public.is_member(household_id));
create policy "read people"     on public.people            for select to authenticated using (public.is_member(household_id));
create policy "read items"      on public.items             for select to authenticated using (public.is_member(household_id));
create policy "read ticks"      on public.completions       for select to authenticated using (public.is_member(household_id));
create policy "read payouts"    on public.payouts           for select to authenticated using (public.is_member(household_id));

-- Writing: items and ticks by any member; people, pay-outs and invites by parents only.
create policy "write items"  on public.items       for all    to authenticated using (public.is_member(household_id)) with check (public.is_member(household_id));
create policy "add ticks"    on public.completions for insert to authenticated with check (public.is_member(household_id));
create policy "remove ticks" on public.completions for delete to authenticated using (public.is_member(household_id));
create policy "parents people"  on public.people  for all to authenticated using (public.is_parent(household_id)) with check (public.is_parent(household_id));
create policy "parents payouts" on public.payouts for all to authenticated using (public.is_parent(household_id)) with check (public.is_parent(household_id));
create policy "parents invites" on public.invites for all to authenticated using (public.is_parent(household_id)) with check (public.is_parent(household_id));

-- Push subscriptions: you only ever see and manage your own devices.
create policy "own devices" on public.push_subscriptions for all to authenticated
  using (user_id = (select auth.uid()) and public.is_member(household_id))
  with check (user_id = (select auth.uid()) and public.is_member(household_id));

-- Functions the app calls (they check who is asking).
create function public.create_household(p_name text) returns uuid language plpgsql security definer set search_path = '' as $$
declare h uuid;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  insert into public.households(name) values (coalesce(nullif(trim(p_name),''),'Our Family')) returning id into h;
  insert into public.household_members(household_id, user_id, role) values (h, auth.uid(), 'parent');
  insert into public.people(household_id, id, name, color) values (h, 'all', 'Everyone', '#7c5cff');
  return h;
end $$;

create function public.join_household(p_code text) returns uuid language plpgsql security definer set search_path = '' as $$
declare inv public.invites;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select * into inv from public.invites where code = p_code and expires_at > now();
  if not found then raise exception 'invalid or expired code'; end if;
  insert into public.household_members(household_id, user_id, role) values (inv.household_id, auth.uid(), inv.role) on conflict do nothing;
  delete from public.invites where code = p_code;   -- single use
  return inv.household_id;
end $$;

create function public.set_apple_feed(p_household uuid, p_url text) returns void language plpgsql security definer set search_path = '' as $$
declare u text := regexp_replace(trim(p_url), '^webcal://', 'https://', 'i');
begin
  if not public.is_parent(p_household) then raise exception 'parents only'; end if;
  -- Only iCloud public-calendar links are accepted, so the server can never be pointed at other sites.
  if u !~* '^https://p[0-9]+-caldav\.icloud\.com/published/[A-Za-z0-9_/-]+$' then
    raise exception 'that does not look like an iCloud public calendar link';
  end if;
  insert into public.integrations(household_id, apple_feed_url) values (p_household, u)
  on conflict (household_id) do update set apple_feed_url = excluded.apple_feed_url, apple_last_error = null;
end $$;

create function public.clear_apple_feed(p_household uuid) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_parent(p_household) then raise exception 'parents only'; end if;
  delete from public.integrations where household_id = p_household;
  delete from public.items where household_id = p_household and source = 'apple';
end $$;

-- Says whether a link is saved. Never returns the link itself.
create function public.apple_feed_status(p_household uuid) returns table (connected boolean, last_sync timestamptz, last_error text)
language sql stable security definer set search_path = '' as $$
  select (i.apple_feed_url is not null), i.apple_last_sync, i.apple_last_error
  from public.integrations i where i.household_id = p_household and public.is_parent(p_household)
$$;

revoke execute on all functions in schema public from public, anon;
grant execute on function public.is_member(uuid), public.is_parent(uuid), public.create_household(text), public.join_household(text),
  public.set_apple_feed(uuid, text), public.clear_apple_feed(uuid), public.apple_feed_status(uuid) to authenticated;
