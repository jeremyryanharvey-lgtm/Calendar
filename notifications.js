// Stage 4 placeholder (push reminders). Not loaded yet.
// Plan: ask permission only after a tap, only when installed to the Home Screen (iOS requirement),
// save the subscription to public.push_subscriptions (own rows only), and let the send-reminders
// Edge Function deliver generic text by default ("You have a reminder").
window.FC_PUSH = { enable: async function () { throw new Error('Push is built in stage 4'); } };
