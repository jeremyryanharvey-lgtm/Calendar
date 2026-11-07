// Stage 2 scaffold (sync with Supabase). index.html does not load this yet.
// It does nothing until config.js is filled in, so the app stays local-only and safe.
// Add to index.html later, before the main script:
//   <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.0/dist/umd/supabase.js"></script>
//   <script src="config.js"></script><script src="database.js"></script>
(function () {
  const cfg = window.FC_CONFIG || {};
  const FC = (window.FC = { ready: false, sb: null });
  if (!(cfg.SUPABASE_URL && cfg.SUPABASE_KEY && window.supabase)) return;
  FC.sb = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_KEY, {
    auth: { persistSession: true, autoRefreshToken: true }
  });
  FC.ready = true;
  FC.signInWithEmail = email => FC.sb.auth.signInWithOtp({ email, options: { emailRedirectTo: location.href.split('#')[0] } });
  FC.signOut = () => FC.sb.auth.signOut();
  FC.session = async () => (await FC.sb.auth.getSession()).data.session;
  FC.createHousehold = name => FC.sb.rpc('create_household', { p_name: name });
  FC.joinHousehold = code => FC.sb.rpc('join_household', { p_code: code });
  FC.myMembership = async () => (await FC.sb.from('household_members').select('household_id, role').limit(1)).data?.[0] || null;
  // TODO (next step): pull() all tables into the app's data, push() changes, realtime subscribe, offline queue.
})();
