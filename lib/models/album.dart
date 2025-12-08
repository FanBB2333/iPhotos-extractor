/// Album model representing a Photos.app album.
class Album {
  final String uuid;
  final String title;
  final int count;
  final String? creationDate;
  final String? coverPath;

  Album({
    required this.uuid,
    required this.title,
    required this.count,
    this.creationDate,
    this.coverPath,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      uuid: json['uuid'] as String,
      title: json['title'] as String? ?? 'Untitled',
      count: json['count'] as int? ?? 0,
      creationDate: json['creation_date'] as String?,
      coverPath: json['cover_path'] as String?,
    );
  }
}
