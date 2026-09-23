/// Local video discovered on device.
class VideoItem {
  final String id; // stable: entityId or path
  final String title;
  final String path; // may be empty when only MediaStore URI available
  final String? entityId; // photo_manager id for thumbnails
  final int durationMs;
  final int sizeBytes;
  final int width;
  final int height;
  final int dateModifiedMs;
  final String folder;

  const VideoItem({
    required this.id,
    required this.title,
    required this.path,
    this.entityId,
    this.durationMs = 0,
    this.sizeBytes = 0,
    this.width = 0,
    this.height = 0,
    this.dateModifiedMs = 0,
    this.folder = '',
  });

  String get resolution =>
      (width > 0 && height > 0) ? '${width}x$height' : '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'path': path,
        'entityId': entityId,
        'durationMs': durationMs,
        'sizeBytes': sizeBytes,
        'width': width,
        'height': height,
        'dateModifiedMs': dateModifiedMs,
        'folder': folder,
      };

  factory VideoItem.fromJson(Map<String, dynamic> j) => VideoItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Video',
        path: j['path'] as String? ?? '',
        entityId: j['entityId'] as String?,
        durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
        sizeBytes: (j['sizeBytes'] as num?)?.toInt() ?? 0,
        width: (j['width'] as num?)?.toInt() ?? 0,
        height: (j['height'] as num?)?.toInt() ?? 0,
        dateModifiedMs: (j['dateModifiedMs'] as num?)?.toInt() ?? 0,
        folder: j['folder'] as String? ?? '',
      );
}
