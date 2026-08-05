/// Compile-time Supabase credentials — passed via `--dart-define` at build
/// time (same placeholder-until-configured pattern as the AdMob test ad unit
/// IDs), never hardcoded into source. The anon key is safe to ship in a
/// client binary (Postgres RLS is the real access boundary, see
/// `supabase/schema.sql` in the `eyegames.net` repo), but it still shouldn't
/// be committed as a literal.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
