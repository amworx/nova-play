/// Minimal, crash-safe SRT/VTT parser for external sidecar subtitles.
/// Kept isolated so subtitle failures can never break core playback.
class SubtitleCue {
  final int startMs;
  final int endMs;
  final String text;
  const SubtitleCue(this.startMs, this.endMs, this.text);
}

int _parseTs(String s) {
  // 00:01:02,500 or 00:01:02.500
  try {
    final t = s.trim().replaceAll(',', '.');
    final parts = t.split(':');
    double secs = 0;
    for (final p in parts) {
      secs = secs * 60 + double.parse(p);
    }
    return (secs * 1000).toInt();
  } catch (_) {
    return 0;
  }
}

List<SubtitleCue> parseSubtitles(String content) {
  try {
    final cues = <SubtitleCue>[];
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Strip WEBVTT header.
    final body = normalized.replaceFirst(RegExp(r'^\s*WEBVTT.*\n'), '');
    final blocks = body.split(RegExp(r'\n\s*\n'));
    for (final b in blocks) {
      final lines =
          b.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (lines.isEmpty) continue;
      // Find timing line.
      String? timing;
      int textStart = 0;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('-->')) {
          timing = lines[i];
          textStart = i + 1;
          break;
        }
      }
      if (timing == null) continue;
      final sides = timing.split('-->');
      if (sides.length != 2) continue;
      final start = _parseTs(sides[0].split(' ').first);
      final end = _parseTs(sides[1].trim().split(' ').first);
      final text = lines.sublist(textStart).join('\n').trim();
      if (text.isEmpty || end <= start) continue;
      cues.add(SubtitleCue(start, end, text));
      if (cues.length > 2000) break;
    }
    cues.sort((a, b) => a.startMs.compareTo(b.startMs));
    return cues;
  } catch (_) {
    return [];
  }
}

String? cueAt(List<SubtitleCue> cues, int posMs) {
  for (final c in cues) {
    if (posMs >= c.startMs && posMs <= c.endMs) return c.text;
  }
  return null;
}
