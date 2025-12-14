import 'package:flutter/material.dart';
import 'package:bibli_app/core/app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/core/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.ensureSupabaseConfig();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const BibliApp());
}
