import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    // publishableKey is the current name for the project's anon/public key.
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const IronSightApp());
}
