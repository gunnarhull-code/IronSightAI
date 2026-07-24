import 'package:flutter/widgets.dart';

import 'app.dart';

/// Performs one-time application startup work, then launches [IronSightApp].
///
/// Anything that must be ready before the widget tree is built belongs here,
/// in dependency order.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Future initialization goes here, in order -----------------------
  // TODO(sprint-2): Initialize the Supabase client (docs/03-technical-architecture.md).
  // TODO(sprint-1): Initialize the SQLCipher-encrypted local (drift) database
  //   (docs/08-security-compliance.md §3, Founder Decision #2).
  // -----------------------------------------------------------------------

  runApp(const IronSightApp());
}
