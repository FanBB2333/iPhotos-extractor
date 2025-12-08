/// Folder model representing a Photos.app folder.
class Folder {
  final String uuid;
  final String title;
  final List<String> subfolders;
  final List<String> albums;

  Folder({
    required this.uuid,
    required this.title,
    this.subfolders = const [],
    this.albums = const [],
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      uuid: json['uuid'] as String,
      title: json['title'] as String? ?? 'Untitled',
      subfolders: (json['subfolders'] as List?)?.cast<String>() ?? [],
      albums: (json['albums'] as List?)?.cast<String>() ?? [],
    );
  }
}
