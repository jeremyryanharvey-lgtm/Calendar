// PLACEHOLDER - built in stage 4. Contract:
//  - Triggered by Supabase Cron only (shared secret header); no public trigger.
//  - Finds reminders due, checks household membership and each person's notification settings.
//  - Sends Web Push (VAPID private key stored in Edge Function secrets) to that person's own devices only.
//  - Default text is generic ("You have a reminder"); full details only if the person opted in.
//  - Deletes subscriptions the push service reports as expired. Skips duplicates; rate limited.
Deno.serve(() => new Response('not built yet', { status: 501 }));
