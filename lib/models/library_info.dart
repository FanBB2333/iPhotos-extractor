/// Library information and statistics.
class LibraryInfo {
  final String libraryPath;
  final String dbPath;
  final String dbVersion;
  final String photosVersion;
  final int totalPhotos;
  final int totalAlbums;
  final int totalFolders;
  final List<String> keywords;
  final List<String> persons;
  final List<String> labels;

  LibraryInfo({
    required this.libraryPath,
    required this.dbPath,
    required this.dbVersion,
    required this.photosVersion,
    required this.totalPhotos,
    required this.totalAlbums,
    required this.totalFolders,
    this.keywords = const [],
    this.persons = const [],
    this.labels = const [],
  });

  factory LibraryInfo.fromJson(Map<String, dynamic> json) {
    return LibraryInfo(
      libraryPath: json['library_path'] as String? ?? '',
      dbPath: json['db_path'] as String? ?? '',
      dbVersion: json['db_version'] as String? ?? '',
      photosVersion: json['photos_version'] as String? ?? '',
      totalPhotos: json['total_photos'] as int? ?? 0,
      totalAlbums: json['total_albums'] as int? ?? 0,
      totalFolders: json['total_folders'] as int? ?? 0,
      keywords: (json['keywords'] as List?)?.cast<String>() ?? [],
      persons: (json['persons'] as List?)?.cast<String>() ?? [],
      labels: (json['labels'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Photo library statistics.
class LibraryStats {
  final int total;
  final int favorites;
  final int hidden;
  final int screenshots;
  final int videos;
  final int livePhotos;
  final int recent30Days;
  final int albums;
  final int folders;

  LibraryStats({
    this.total = 0,
    this.favorites = 0,
    this.hidden = 0,
    this.screenshots = 0,
    this.videos = 0,
    this.livePhotos = 0,
    this.recent30Days = 0,
    this.albums = 0,
    this.folders = 0,
  });

  factory LibraryStats.fromJson(Map<String, dynamic> json) {
    return LibraryStats(
      total: json['total'] as int? ?? 0,
      favorites: json['favorites'] as int? ?? 0,
      hidden: json['hidden'] as int? ?? 0,
      screenshots: json['screenshots'] as int? ?? 0,
      videos: json['videos'] as int? ?? 0,
      livePhotos: json['live_photos'] as int? ?? 0,
      recent30Days: json['recent_30_days'] as int? ?? 0,
      albums: json['albums'] as int? ?? 0,
      folders: json['folders'] as int? ?? 0,
    );
  }
}
