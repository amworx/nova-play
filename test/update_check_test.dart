import 'package:flutter_test/flutter_test.dart';
import 'package:nova_play/data/update_service.dart';

void main() {
  group('version comparison', () {
    test('newer patch/minor/major wins', () {
      expect(isUpdateAvailable('1.0.0+1', 'v1.0.1'), isTrue);
      expect(isUpdateAvailable('1.0.0+1', 'v1.1.0'), isTrue);
      expect(isUpdateAvailable('1.0.0+1', 'v2.0.0'), isTrue);
    });

    test('same or older is not an update', () {
      expect(isUpdateAvailable('1.0.1+1', 'v1.0.1'), isFalse);
      expect(isUpdateAvailable('1.0.1+9', 'v1.0.0'), isFalse);
      expect(isUpdateAvailable('2.0.0+1', 'v1.9.9'), isFalse);
    });

    test('higher build number counts when version is equal', () {
      expect(isUpdateAvailable('1.0.1+1', 'v1.0.1'), isFalse);
    });

    test('malformed input never throws and never claims an update', () {
      expect(isUpdateAvailable('garbage', 'also-garbage'), isFalse);
      expect(isUpdateAvailable('', ''), isFalse);
      expect(isUpdateAvailable('1.0.0', ''), isFalse);
    });
  });

  group('release parsing', () {
    Map<String, dynamic> releaseJson(String tag, List<Object?> assets) => {
          'tag_name': tag,
          'body': 'Bug fixes',
          'assets': assets,
        };

    Map<String, dynamic> apk(String name) => {
          'name': name,
          'browser_download_url': 'https://example.com/$name',
        };

    test('picks the release APK asset', () {
      final rel = parseLatestRelease(releaseJson('v1.0.1', [
        {'name': 'notes.txt', 'browser_download_url': 'https://x/notes.txt'},
        apk('nova-play-v1.0.1.apk'),
      ]));
      expect(rel, isNotNull);
      expect(rel!.tag, 'v1.0.1');
      expect(rel.version, '1.0.1');
      expect(rel.apkUrl, 'https://example.com/nova-play-v1.0.1.apk');
      expect(rel.notes, 'Bug fixes');
    });

    test('null when no tag or no apk asset', () {
      expect(parseLatestRelease({'tag_name': '', 'assets': []}), isNull);
      expect(parseLatestRelease(releaseJson('v1.0.1', [])), isNull);
      expect(
          parseLatestRelease(releaseJson('v1.0.1', [
            {
              'name': 'notes.txt',
              'browser_download_url': 'https://x/notes.txt'
            },
          ])),
          isNull);
    });

    test('garbage json never throws', () {
      expect(parseLatestRelease({}), isNull);
      expect(parseLatestRelease({'tag_name': 'v1', 'assets': 'nope'}), isNull);
    });
  });
}
