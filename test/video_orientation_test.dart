import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_play/state/player_controller.dart';

void main() {
  group('fullscreen orientation follows the video', () {
    test('vertical video stays portrait', () {
      expect(
        preferredFullscreenOrientations(const Size(1080, 1920)),
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
      );
      expect(
        preferredFullscreenOrientations(const Size(720, 1280)),
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
      );
    });

    test('landscape video rotates to landscape', () {
      expect(
        preferredFullscreenOrientations(const Size(1920, 1080)),
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
      );
    });

    test('square or unknown video keeps the old landscape behavior', () {
      expect(
        preferredFullscreenOrientations(const Size(1080, 1080)),
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
      );
      expect(
        preferredFullscreenOrientations(Size.zero),
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
      );
    });
  });
}
