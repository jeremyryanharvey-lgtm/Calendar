// Connection to Supabase (sign-in and family set-up). Syncing the calendar data is added in the next step.
// Does nothing until config.js is filled in, so the app stays local-only and safe.
(function () {
  const cfg = window.FC_CONFIG || {};
  const FC = (window.FC = { ready: false, sb: null });
  if (!(cfg.SUPABASE_URL && cfg.SUPABASE_KEY && window.supabase)) return;
  FC.sb = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_KEY, {
    auth: { persistSession: true, autoRefreshToken: true }
  });
  FC.ready = true;
  // Accounts are created in the Supabase dashboard (Authentication -> Users), so no emails are needed.
  FC.signInWithPassword = (email, password) => FC.sb.auth.signInWithPassword({ email, password });
  FC.signOut = () => FC.sb.auth.signOut();
  FC.session = async () => (await FC.sb.auth.getSession()).data.session;
  FC.createHousehold = name => FC.sb.rpc('create_household', { p_name: name });
  FC.joinHousehold = code => FC.sb.rpc('join_household', { p_code: code });
  FC.createInvite = (role, householdId) => FC.sb.from('invites').insert({ household_id: householdId, role }).select('code').single();
  // TODO (next step): pull() all tables into the app's data, push() changes, realtime subscribe, offline queue.
})();
