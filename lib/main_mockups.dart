import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mockups/mockup_hub.dart';


/// Mockup gallery entry point:
///   flutter run -t lib/main_mockups.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MockupHubV2());
}