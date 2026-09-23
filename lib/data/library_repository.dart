import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/video_item.dart';

enum LibraryStatus { ok, permissionRequired, permissionDenied, failure }

class LibraryResult {
  final LibraryStatus status;
  final List<VideoItem> videos;
  final String? message;
  final bool limited;
  const LibraryResult(this.status, this.videos, [this.message, this.limited = false]);
}

/// Efficient MediaStore discovery via photo_manager.
/// Never loads full video bytes; thumbnails are fetched low-res on demand.
class LibraryRepository {
  void _log(String m) {
    if (kDebugMode) debugPrint('LIB: $m');
  }

  /// Check the system grant WITHOUT prompting. Never loops the dialog:
  /// granted (or limited) status always proceeds to a real scan.
  Future<LibraryResult> load({bool prompt = false}) async {
    try {
      // permission_handler: cheap OS-level check; also detects permanent deny.
      final hs = await Permission.videos.status;
      _log('status=${hs.name} granted=${hs.isGranted} '
          'limited=${hs.isLimited} permaDenied=${hs.isPermanentlyDenied}');

      if (hs.isPermanentlyDenied) {
        return const LibraryResult(LibraryStatus.permissionDenied, []);
      }

      // photo_manager is the authority here: it understands Android 14+
      // partial access (READ_MEDIA_VISUAL_USER_SELECTED -> limited), which
      // permission_handler reports as plain "denied". A limited grant is
      // enough to scan: MediaStore returns exactly the user-picked items.
      var pm = await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.video,
            mediaLocation: false,
          ),
        ),
      );
      _log('getPermissionState -> ${pm.name} isAuth=${pm.isAuth}');
      final usable =
          pm.isAuth || pm == PermissionState.limited;
      if (!usable) {
        if (!prompt) {
          return const LibraryResult(
              LibraryStatus.permissionRequired, []);
        }
        // Ask once, via photo_manager for the best native sheet.
        pm = await PhotoManager.requestPermissionExtend();
        _log('requestPermissionExtend -> ${pm.name} isAuth=${pm.isAuth}');
        if (!pm.isAuth && pm != PermissionState.limited) {
          if (pm == PermissionState.denied) {
            return const LibraryResult(
                LibraryStatus.permissionDenied, []);
          }
          return const LibraryResult(
              LibraryStatus.permissionRequired, []);
        }
      }
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        hasAll: true,
      );
      _log('paths=${paths.length}');
      final List<VideoItem> out = [];
      final seen = <String>{};
      for (final p in paths) {
        // Skip virtual albums: same assets repeat in Recent/Favorites.
        if (p.isAll) continue;
        final count = await p.assetCountAsync;
        final assets = await p.getAssetListRange(start: 0, end: count);
        for (final a in assets) {
          if (!seen.add(a.id)) continue;
          final file = await a.file;
          final title = a.title ?? 'Video';
          out.add(VideoItem(
            id: a.id,
            title: title,
            path: file?.path ?? '',
            entityId: a.id,
            durationMs: (a.duration * 1000).toInt(),
            sizeBytes: 0,
            width: a.width,
            height: a.height,
            dateModifiedMs:
                a.modifiedDateTime.millisecondsSinceEpoch,
            folder: p.name,
          ));
        }
      }
      out.sort((a, b) => b.dateModifiedMs.compareTo(a.dateModifiedMs));
      _log('videos=${out.length}');
      return LibraryResult(LibraryStatus.ok, out, null,
          pm == PermissionState.limited);
    } catch (e) {
      _log('ERROR: $e');
      return LibraryResult(LibraryStatus.failure, [], e.toString());
    }
  }

  Future<void> openSettings() => openAppSettings();

  /// Low-res thumbnail bytes for lists; keeps memory small.
  Future<List<int>?> thumbBytes(String entityId, {int size = 320}) async {
    try {
      final a = await AssetEntity.fromId(entityId);
      final d = await a?.thumbnailDataWithSize(
        ThumbnailSize(size, (size * 9 / 16).toInt()),
        quality: 70,
      );
      return d;
    } catch (_) {
      return null;
    }
  }
}
