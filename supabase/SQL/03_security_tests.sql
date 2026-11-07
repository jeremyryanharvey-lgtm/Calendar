-- Security checks. Fill in the <PLACEHOLDERS> (Authentication -> Users shows user IDs), run each block, compare with the comment.
-- Each block runs inside a transaction that is rolled back, so nothing is changed.

-- 1. A signed-in stranger (not in any household) must see nothing. Expect 0 rows.
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<STRANGER_USER_ID>","role":"authenticated"}', true);
select count(*) from public.items;
select count(*) from public.payouts;
rollback;

-- 2. A 'device' account must NOT be able to record a pay-out. Expect an error: row-level security policy.
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<DEVICE_USER_ID>","role":"authenticated"}', true);
insert into public.payouts(household_id, id, who, amount) values ('<HOUSEHOLD_ID>', 'test', 'p1', 1);
rollback;

-- 3. Nobody signed in as a family account can read the saved Apple link. Expect: permission denied.
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<PARENT_USER_ID>","role":"authenticated"}', true);
select * from public.integrations;
rollback;

-- 4. A parent can see whether a link is saved, but only as yes/no. Expect: connected true/false, no URL.
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<PARENT_USER_ID>","role":"authenticated"}', true);
select * from public.apple_feed_status('<HOUSEHOLD_ID>');
rollback;

-- 5. A device must not be able to save an Apple link. Expect error: parents only.
begin;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"<DEVICE_USER_ID>","role":"authenticated"}', true);
select public.set_apple_feed('<HOUSEHOLD_ID>', 'https://p01-caldav.icloud.com/published/2/example');
rollback;

-- 6. The signed-out (anon) key must see nothing. Expect: permission denied.
begin;
set local role anon;
select count(*) from public.items;
rollback;
