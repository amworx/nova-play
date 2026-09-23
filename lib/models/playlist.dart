import 'video_item.dart';

class Playlist {
  final String id;
  final String name;
  final List<VideoItem> videos;

  const Playlist({required this.id, required this.name, this.videos = const []});

  Playlist copyWith({String? name, List<VideoItem>? videos}) =>
      Playlist(id: id, name: name ?? this.name, videos: videos ?? this.videos);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'videos': videos.map((v) => v.toJson()).toList(),
      };

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Playlist',
        videos: ((j['videos'] as List?) ?? [])
            .map((e) => VideoItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
