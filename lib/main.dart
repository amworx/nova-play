import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/prefs_store.dart';
import 'state/media_notification.dart';
import 'state/player_controller.dart';
import 'state/providers.dart';

/// System media-notification handler. Null when AudioService failed to
/// start (e.g. test harness): playback works, just without a notification.
NovaAudioHandler? novaAudioHandler;

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
    final store = PrefsStore(prefs);
    // Single player for the whole app: the notification handler and every
    // UI consumer share this instance (recreating it kills playback).
    final player = PlayerController(store);
    try {
      novaAudioHandler = await AudioService.init(
        builder: () => NovaAudioHandler(player),
        config: const AudioServiceConfig(
          androidNotificationChannelId:
              'com.example.video_player.channel.playback',
          androidNotificationChannelName: 'Now playing',
          androidNotificationOngoing: false,
          androidStopForegroundOnPause: true,
          // Close must remove the notification (default keeps a detached
          // "resume" copy, wrong for a video player that just closed).
          androidResumeOnClick: false,
        ),
      );
    } catch (_) {
      novaAudioHandler = null;
    }
    FlutterError.onError = (details) {
      debugPrint('FATAL-FLUTTER: ${details.exception}\n${details.stack}');
      FlutterError.presentError(details);
    };
    runApp(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          playerProvider.overrideWith((_) => player),
        ],
        child: const NovaPlayApp(),
      ),
    );
  }, (Object e, StackTrace st) {
    debugPrint('FATAL-ZONE: $e\n$st');
  });
}
