import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'firebase_options.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
await dotenv.load(fileName: ".env");


  await Supabase.initialize(
    url: 'https://qyoekviwnybtvfjgcide.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF5b2Vrdml3bnlidHZmamdjaWRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwODYyMzMsImV4cCI6MjA2ODY2MjIzM30.FpF2TeCkPIYBxgR2N73jwESEuvzt9vPogTDNAhIG_SU',
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}
