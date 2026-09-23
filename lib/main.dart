import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/providers.dart';

void main() {
  // Route every uncaught error to logcat with a full stack so on-device
  // failures (e.g. "No active player") leave a trail we can diagnose
  // without seeing the screen. The zone wraps initialization AND runApp so
  // binding + app share the same zone.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Portrait-first; landscape allowed only in player fullscreen.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    final prefs = await SharedPreferences.getInstance();
    FlutterError.onError = (details) {
      debugPrint('FATAL-FLUTTER: ${details.exception}\n${details.stack}');
      FlutterError.presentError(details);
    };
    runApp(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: const NovaPlayApp(),
      ),
    );
  }, (Object e, StackTrace st) {
    debugPrint('FATAL-ZONE: $e\n$st');
  });
}