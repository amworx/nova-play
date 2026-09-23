import 'package:flutter_test/flutter_test.dart';
import 'package:nova_play/data/subtitle_parser.dart';
import 'package:nova_play/utils/format.dart';

void main() {
  test('formats durations', () {
    expect(formatDuration(const Duration(seconds: 65)), '1:05');
    expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03');
  });

  test('parses SRT subtitles without crashing', () {
    const srt = '''
1
00:00:01,000 --> 00:00:02,000
Hello

2
00:00:03.000 --> 00:00:04.000
World
''';
    final cues = parseSubtitles(srt);
    expect(cues.length, 2);
    expect(cueAt(cues, 1500), 'Hello');
    expect(cueAt(cues, 2500), isNull);
  });

  test('bad subtitle input returns empty, never throws', () {
    expect(parseSubtitles('garbage'), isEmpty);
  });
}
