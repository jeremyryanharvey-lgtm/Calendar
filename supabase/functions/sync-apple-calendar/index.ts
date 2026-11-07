// PLACEHOLDER - built in stage 3. Deploy via Supabase dashboard -> Edge Functions.
// Contract:
//  - Called by Supabase Cron (shared secret header) or by a parent (valid JWT, role = parent). Anyone else: 401.
//  - Reads public.integrations with the service role key (kept in Edge Function secrets, never in the repo).
//  - Fetches ONLY https://pNN-caldav.icloud.com/published/... links (already validated when saved).
//  - Parses events with a calendar library (ical.js), writes them to public.items with source = 'apple', read-only.
//  - Never logs the link. Records apple_last_sync / apple_last_error.
Deno.serve(() => new Response('not built yet', { status: 501 }));
