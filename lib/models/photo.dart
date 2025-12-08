/// Photo model representing a photo from Photos.app.
class Photo {
  final String uuid;
  final String filename;
  final String? originalFilename;
  final String? path;
  final String? date;
  final int? width;
  final int? height;
  final bool favorite;
  final bool hidden;
  final bool isLivePhoto;
  final bool isVideo;
  final bool isScreenshot;

  Photo({
    required this.uuid,
    required this.filename,
    this.originalFilename,
    this.path,
    this.date,
    this.width,
    this.height,
    this.favorite = false,
    this.hidden = false,
    this.isLivePhoto = false,
    this.isVideo = false,
    this.isScreenshot = false,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      uuid: json['uuid'] as String,
      filename: json['filename'] as String? ?? 'Unknown',
      originalFilename: json['original_filename'] as String?,
      path: json['path'] as String?,
      date: json['date'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      favorite: json['favorite'] as bool? ?? false,
      hidden: json['hidden'] as bool? ?? false,
      isLivePhoto: json['is_live_photo'] as bool? ?? false,
      isVideo: json['is_video'] as bool? ?? false,
      isScreenshot: json['is_screenshot'] as bool? ?? false,
    );
  }
}

/// Detailed photo metadata.
class PhotoMetadata extends Photo {
  final String? dateModified;
  final String? description;
  final String? title;
  final List<String> keywords;
  final List<String> persons;
  final List<String> labels;
  final int? orientation;
  final bool isHdr;
  final bool isPortrait;
  final bool isSelfie;
  final bool isSlowMo;
  final bool isTimeLapse;
  final bool isPanorama;
  final ExifInfo? exif;
  final LocationInfo? location;

  PhotoMetadata({
    required super.uuid,
    required super.filename,
    super.originalFilename,
    super.path,
    super.date,
    super.width,
    super.height,
    super.favorite,
    super.hidden,
    super.isLivePhoto,
    super.isVideo,
    super.isScreenshot,
    this.dateModified,
    this.description,
    this.title,
    this.keywords = const [],
    this.persons = const [],
    this.labels = const [],
    this.orientation,
    this.isHdr = false,
    this.isPortrait = false,
    this.isSelfie = false,
    this.isSlowMo = false,
    this.isTimeLapse = false,
    this.isPanorama = false,
    this.exif,
    this.location,
  });

  factory PhotoMetadata.fromJson(Map<String, dynamic> json) {
    return PhotoMetadata(
      uuid: json['uuid'] as String,
      filename: json['filename'] as String? ?? 'Unknown',
      originalFilename: json['original_filename'] as String?,
      path: json['path'] as String?,
      date: json['date'] as String?,
      dateModified: json['date_modified'] as String?,
      description: json['description'] as String?,
      title: json['title'] as String?,
      keywords: (json['keywords'] as List?)?.cast<String>() ?? [],
      persons: (json['persons'] as List?)?.cast<String>() ?? [],
      labels: (json['labels'] as List?)?.cast<String>() ?? [],
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      orientation: (json['orientation'] as num?)?.toInt(),
      favorite: json['favorite'] as bool? ?? false,
      hidden: json['hidden'] as bool? ?? false,
      isHdr: json['is_hdr'] as bool? ?? false,
      isLivePhoto: json['is_live_photo'] as bool? ?? false,
      isPortrait: json['is_portrait'] as bool? ?? false,
      isSelfie: json['is_selfie'] as bool? ?? false,
      isSlowMo: json['is_slow_mo'] as bool? ?? false,
      isTimeLapse: json['is_time_lapse'] as bool? ?? false,
      isPanorama: json['is_panorama'] as bool? ?? false,
      isVideo: json['is_video'] as bool? ?? false,
      isScreenshot: json['is_screenshot'] as bool? ?? false,
      exif: json['exif'] != null ? ExifInfo.fromJson(json['exif']) : null,
      location: json['location'] != null ? LocationInfo.fromJson(json['location']) : null,
    );
  }
}

/// EXIF information for a photo.
class ExifInfo {
  final String? cameraMake;
  final String? cameraModel;
  final String? lensModel;
  final int? iso;
  final double? exposureTime;
  final double? focalLength;
  final double? aperture;

  ExifInfo({
    this.cameraMake,
    this.cameraModel,
    this.lensModel,
    this.iso,
    this.exposureTime,
    this.focalLength,
    this.aperture,
  });

  factory ExifInfo.fromJson(Map<String, dynamic> json) {
    return ExifInfo(
      cameraMake: json['camera_make'] as String?,
      cameraModel: json['camera_model'] as String?,
      lensModel: json['lens_model'] as String?,
      iso: json['iso'] as int?,
      exposureTime: (json['exposure_time'] as num?)?.toDouble(),
      focalLength: (json['focal_length'] as num?)?.toDouble(),
      aperture: (json['aperture'] as num?)?.toDouble(),
    );
  }
}

/// Location information for a photo.
class LocationInfo {
  final double latitude;
  final double longitude;

  LocationInfo({
    required this.latitude,
    required this.longitude,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
