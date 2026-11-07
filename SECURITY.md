# Security requirements (Our Family Calendar)

1. Secret keys (Supabase service_role / secret key, VAPID private key, any iCloud link) never appear in this repo or in browser code. Only the publishable key goes in config.js.
2. The iCloud calendar link is stored only in `public.integrations` (no client access) and read only by Edge Functions. Parents can connect, check status and disconnect. Disconnecting deletes the link and the imported events.
3. Every table has row level security. Members see only their own household. Pay-outs, people, invites and the Apple link are parents only.
4. Push subscriptions are per device, visible only to their owner, and removable. Notifications default to generic lock-screen text.
5. Edge Functions reject any caller that is not Cron (shared secret) or an authorised parent.
6. The in-app PIN is only a screen lock. Real enforcement is the roles above.

## Test checklist (run before relying on it)
- [ ] supabase/sql/03_security_tests.sql: every block gives the result written in its comment
- [ ] A second family account cannot see the first household's data
- [ ] config.js and every file in the repo contain no secret key (search for "service_role" and "eyJ")
- [ ] Disconnect Apple Calendar: link deleted, imported events gone, no further syncing
- [ ] Turn notifications off: nothing arrives; remove a device: it stops receiving
- [ ] Lock screen shows only the generic message by default
