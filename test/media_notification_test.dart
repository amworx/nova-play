import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_play/state/media_notification.dart';
import 'package:nova_play/state/player_controller.dart';

void main() {
  group('notification controls', () {
    test('play/pause swaps, prev/next appear when available', () {
      var c = NovaAudioHandler.controlsFor(
          playing: true, hasPrev: true, hasNext: true);
      expect(c, [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ]);

      c = NovaAudioHandler.controlsFor(
          playing: false, hasPrev: false, hasNext: false);
      expect(c, [MediaControl.play]);
    });

    test('single-item queue shows only the play/pause toggle', () {
      final c = NovaAudioHandler.controlsFor(
          playing: false, hasPrev: false, hasNext: true);
      expect(c, [MediaControl.play, MediaControl.skipToNext]);
    });
  });

  group('processing state mapping', () {
    test('mirrors player status', () {
      expect(
          NovaAudioHandler.processingStateFor(PlayerStatus.loading),
          AudioProcessingState.loading);
      expect(
          NovaAudioHandler.processingStateFor(PlayerStatus.ready),
          AudioProcessingState.ready);
      expect(
          NovaAudioHandler.processingStateFor(PlayerStatus.error),
          AudioProcessingState.error);
      expect(
          NovaAudioHandler.processingStateFor(PlayerStatus.idle),
          AudioProcessingState.idle);
    });
  });
}
