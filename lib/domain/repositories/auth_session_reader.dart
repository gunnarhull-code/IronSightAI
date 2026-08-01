/// Narrow session identity boundary — presentation never imports Supabase.
abstract class AuthSessionReader {
  String? get currentUserId;
}
