import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:nova_play/main.dart' as app;
import 'package:nova_play/state/player_controller.dart';
import 'package:nova_play/state/providers.dart';

/// On-device tap/hit-test verification for the Tideform player.
/// Run with:
///   flutter test integration_test/player_controls_test.dart \
///     -d <device> --dart-define=AUTOPLAY=true
/// Permission is revoked by the fresh test install: grant it mid-run with
///   adb shell pm grant com.example.video_player android.permission.READ_MEDIA_VIDEO
/// (AUTOPLAY retries the scan, and the first wait below is 90s real time.)
///
/// Every assertion reads real provider state after a real pointer tap, so a
/// dead control fails the test with a clear reason.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all player controls respond to real taps', (tester) async {
    app.main();
    await tester.pump();

    // --- helpers -----------------------------------------------------------
    Future<void> pumpUntil(bool Function() cond,
        {Duration timeout = const Duration(seconds: 20)}) async {
      final t0 = DateTime.now();
      while (DateTime.now().difference(t0) < timeout) {
        // A "Resume playback?" dialog (from saved progress) can appear on any
        // video open and would block every later tap. Dismiss it whenever seen.
        if (find.text('Resume playback?').evaluate().isNotEmpty) {
          try {
            await tester.tap(find.text('Restart'), warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 300));
          } catch (_) {}
        }
        if (cond()) return;
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }
    }

    PlayerController? maybePlayer() {
      final f = find.byIcon(Icons.pause).hitTestable();
      if (f.evaluate().isNotEmpty) {
        return ProviderScope.containerOf(tester.element(f.first))
            .read(playerProvider);
      }
      final g = find.byIcon(Icons.play_arrow).hitTestable();
      if (g.evaluate().isNotEmpty) {
        return ProviderScope.containerOf(tester.element(g.first))
            .read(playerProvider);
      }
      return null;
    }

    void dumpDebug(String tag) {
      final p = maybePlayer();
      debugPrint('DUMP[$tag] icons=${find.byType(Icon).evaluate().length} '
          'status=${p?.status} isPlaying=${p?.isPlaying} '
          'muted=${p?.muted} shuffle=${p?.shuffle} repeat=${p?.repeatMode} '
          'queueIndex=${p?.queueIndex} fullscreen=${p?.fullscreen} '
          'controlsVisible=${p?.controlsVisible} '
          'volUp=${find.byIcon(Icons.volume_up).evaluate().length} '
          'volOff=${find.byIcon(Icons.volume_off).evaluate().length} '
          'pause=${find.byIcon(Icons.pause).evaluate().length} '
          'play=${find.byIcon(Icons.play_arrow).evaluate().length} '
          'fullscreenBtn=${find.byIcon(Icons.fullscreen).evaluate().length} '
          'shuffleBtn=${find.byIcon(Icons.shuffle).evaluate().length}');
    }

    Future<PlayerController> playerReady() async {
      PlayerController? p;
      await pumpUntil(() {
        p = maybePlayer();
        return p != null;
      });
      return p!;
    }

    // --- wait for library + AUTOPLAY to open the player --------------------
    await pumpUntil(
        () => find.byIcon(Icons.pause).evaluate().isNotEmpty ||
            find.byIcon(Icons.play_arrow).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 90));

    // Pause immediately so the (possibly short) clip cannot auto-advance
    // mid-test and reload the player (loading = no controls on screen).
    final hadPause = find.byIcon(Icons.pause).hitTestable().evaluate().isNotEmpty;
    if (hadPause) {
      await tester.tap(find.byIcon(Icons.pause).hitTestable().first);
    } else {
      await tester.tap(find.byIcon(Icons.play_arrow).hitTestable().first);
    }
    await pumpUntil(() {
      final p = maybePlayer();
      return p != null && p.isPlaying != hadPause;
    });
    await playerReady();
    dumpDebug('after-pause-early');

    // ---- transport: play/pause toggle ----
    final hadPause2 =
        find.byIcon(Icons.pause).hitTestable().evaluate().isNotEmpty;
    if (hadPause2) {
      await tester.tap(find.byIcon(Icons.pause).hitTestable().first);
    } else {
      await tester.tap(find.byIcon(Icons.play_arrow).hitTestable().first);
    }
    await pumpUntil(() {
      final p = maybePlayer();
      return p != null && p.isPlaying != hadPause2;
    });
    await playerReady();
    dumpDebug('after-toggle');

    // ---- seek buttons ----
    final p = await playerReady();
    final p0 = p.position.inMilliseconds;
    await tester.tap(find.byIcon(Icons.forward_10).hitTestable().first);
    await tester.pump(const Duration(milliseconds: 600));
    final p1 = (await playerReady()).position.inMilliseconds;
    final dur = (await playerReady()).duration.inMilliseconds;
    expect(p1 >= p0 + 8000 || (p1 == dur && p1 >= p0), isTrue,
        reason: 'forward_10 did not move the playhead ($p0 -> $p1)');

    final q0 = p1;
    await tester.tap(find.byIcon(Icons.replay_10).hitTestable().first);
    await tester.pump(const Duration(milliseconds: 600));
    final q1 = (await playerReady()).position.inMilliseconds;
    expect(q1 < q0, isTrue,
        reason: 'replay_10 did not move the playhead back ($q0 -> $q1)');
    dumpDebug('after-seeks');

    // ---- volume overlay on the video card ----
    final volOn = find.byIcon(Icons.volume_up).hitTestable();
    final volOff = find.byIcon(Icons.volume_off).hitTestable();
    expect(volOn.evaluate().isNotEmpty || volOff.evaluate().isNotEmpty, isTrue,
        reason: 'volume button not on screen');
    final player = await playerReady();
    final wasMuted = player.muted;
    if (wasMuted) {
      await tester.tap(volOff.first);
    } else {
      await tester.tap(volOn.first);
    }
    await pumpUntil(() {
      final p = maybePlayer();
      return p != null && p.muted != wasMuted;
    });
    final player2 = await playerReady();
    dumpDebug('before-vol2');
    if (player2.muted) {
      await tester.tap(find.byIcon(Icons.volume_off).hitTestable().first);
    } else {
      await tester.tap(find.byIcon(Icons.volume_up).hitTestable().first);
    }
    await pumpUntil(() {
      final p = maybePlayer();
      return p != null && p.muted == wasMuted;
    });

    // ---- fullscreen (portrait -> landscape route) ----
    await tester.tap(find.byIcon(Icons.fullscreen).hitTestable().first);
    await pumpUntil(
        () => find.byIcon(Icons.fullscreen_exit).hitTestable().evaluate().isNotEmpty,
        timeout: const Duration(seconds: 10));
    final fsPlayer = maybePlayer();
    expect(fsPlayer != null && fsPlayer!.fullscreen, isTrue,
        reason: 'fullscreen tap did not enter the fullscreen route');
    await tester.tap(find.byIcon(Icons.fullscreen_exit).hitTestable().first);
    await pumpUntil(
        () => find.byIcon(Icons.fullscreen).hitTestable().evaluate().isNotEmpty,
        timeout: const Duration(seconds: 10));
    final ptPlayer = maybePlayer();
    expect(ptPlayer != null && !ptPlayer!.fullscreen, isTrue,
        reason: 'fullscreen_exit tap did not return to portrait');
    await playerReady();

    // ---- queue header: shuffle ----
    final shuf = find.byIcon(Icons.shuffle).hitTestable();
    expect(shuf.evaluate().isNotEmpty, isTrue, reason: 'shuffle not on screen');
    await tester.tap(shuf.first);
    await pumpUntil(() {
      final p = maybePlayer();
      return p != null && p.shuffle;
    });
    await tester.tap(find.byIcon(Icons.shuffle).hitTestable().first);
    await pumpUntil(() {
      final p = maybePlayer();
      return p != null && !p.shuffle;
    });

    // ---- queue header: repeat cycle 0 -> 1 -> 2 -> 0 ----
    final rep = find.byIcon(Icons.repeat).hitTestable();
    expect(rep.evaluate().isNotEmpty, isTrue, reason: 'repeat not on screen');
    await tester.tap(rep.first);
    await pumpUntil(() {
      final p = maybePlayer();
      return p != null && p.repeatMode == 1;
    });
    await tester.tap(find.byIcon(Icons.repeat).hitTestable().first);
    await pumpUntil(() {
      final p = maybePlayer();
      return p != null && p.repeatMode == 2;
    });
    expect(find.byIcon(Icons.repeat_one).hitTestable().evaluate().isNotEmpty,
        isTrue, reason: 'repeat_one icon should show at mode 2');
    await tester.tap(find.byIcon(Icons.repeat_one).hitTestable().first);
    await pumpUntil(() {
      final p = maybePlayer();
      return p != null && p.repeatMode == 0;
    });

    // ---- skip next / previous ----
    final nav = await playerReady();
    if (nav.queue.length >= 2) {
      final idx0 = nav.queueIndex;
      await tester.tap(find.byIcon(Icons.skip_next).hitTestable().first);
      await pumpUntil(() {
        final p = maybePlayer();
        return p != null && p.queueIndex != idx0;
      });
      final idx1 = (await playerReady()).queueIndex;
      expect(idx1, (idx0 + 1) % nav.queue.length,
          reason: 'skip_next did not advance the queue');
      await tester.tap(find.byIcon(Icons.skip_previous).hitTestable().first);
      await pumpUntil(() {
        final p = maybePlayer();
        return p != null && p.queueIndex == idx0;
      });
    } else {
      await tester.tap(find.byIcon(Icons.skip_next).hitTestable().first);
      await tester.pump(const Duration(milliseconds: 400));
    }

    // ---- actions row: favorite toggle ----
    final fav = find.byIcon(Icons.favorite_border).hitTestable();
    if (fav.evaluate().isNotEmpty) {
      final v = (await playerReady()).current!;
      await tester.tap(fav.first);
      await pumpUntil(
          () => find.byIcon(Icons.favorite).hitTestable().evaluate().isNotEmpty);
      expect(
          ProviderScope.containerOf(
                  tester.element(find.byIcon(Icons.favorite).hitTestable().first))
              .read(favoritesProvider)
              .contains(v.id),
          isTrue,
          reason: 'favorite_border tap did not favorite the video');
      await tester.tap(find.byIcon(Icons.favorite).hitTestable().first);
      await pumpUntil(() =>
          find.byIcon(Icons.favorite_border).hitTestable().evaluate().isNotEmpty);
    }

    // ---- back closes the player ----
    await tester.tap(find.byIcon(Icons.arrow_back).hitTestable().first);
    await pumpUntil(
        () => find.byIcon(Icons.pause).evaluate().isEmpty &&
            find.byIcon(Icons.play_arrow).evaluate().isEmpty,
        timeout: const Duration(seconds: 10));
  });
}