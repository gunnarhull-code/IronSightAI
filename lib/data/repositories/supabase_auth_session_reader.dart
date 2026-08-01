import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_session_reader.dart';

/// Supabase-backed [AuthSessionReader] constructed only in the composition root.
class SupabaseAuthSessionReader implements AuthSessionReader {
  SupabaseAuthSessionReader(this._client);

  final SupabaseClient _client;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;
}
