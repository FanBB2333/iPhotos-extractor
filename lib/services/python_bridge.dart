import 'dart:convert';
import 'dart:io';
import 'dart:async';

import '../models/album.dart';
import '../models/photo.dart';
import '../models/folder.dart';
import '../models/library_info.dart';

/// Bridge service for communicating with Python backend via subprocess.
class PythonBridge {
  Process? _process;
  int _requestId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Start the Python subprocess.
  Future<void> start() async {
    String? backendPath;
    
    // 1. Try finding in bundle resources (bundled app)
    // Path: .../Contents/Frameworks/App.framework/Resources/flutter_assets/backend/photos_bridge.py
    try {
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent; // Contents/MacOS
      final bundleDir = exeDir.parent; // Contents
      final assetsPath = '${bundleDir.path}/Frameworks/App.framework/Resources/flutter_assets/backend/photos_bridge.py';
      
      if (File(assetsPath).existsSync()) {
        backendPath = assetsPath;
      }
    } catch (e) {
      print('Error checking bundle path: $e');
    }

    // 2. Fallback to local source path (development)
    if (backendPath == null) {
      final currentDir = Directory.current.path;
      final localPath = '$currentDir/backend/photos_bridge.py';
      if (File(localPath).existsSync()) {
        backendPath = localPath;
      }
    }

    if (backendPath == null) {
      throw Exception('Backend script not found. Checked bundle and local paths.');
    }

    print('Starting Python backend from: $backendPath');

    _process = await Process.start(
      'python3',
      [backendPath],
      workingDirectory: File(backendPath).parent.path,
    );

    // Listen for responses
    _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleResponse);

    // Log stderr for debugging
    _process!.stderr
        .transform(utf8.decoder)
        .listen((data) => print('Python stderr: $data'));

    // Handle process exit
    _process!.exitCode.then((code) {
      print('Python process exited with code: $code');
      _isInitialized = false;
    });
  }

  void _handleResponse(String line) {
    try {
      final response = jsonDecode(line) as Map<String, dynamic>;
      final id = response['id'] as int?;
      if (id != null && _pending.containsKey(id)) {
        _pending[id]!.complete(response);
        _pending.remove(id);
      } else {
        print('Received unexpected Python response: $line');
      }
    } catch (e) {
      print('Error parsing Python response: $e, line: $line');
    }
  }

  /// Send a JSON-RPC request to Python backend.
  Future<Map<String, dynamic>> call(String method, [Map<String, dynamic>? params, Duration? timeout]) async {
    if (_process == null) {
      throw Exception('Python process not started. Call start() first.');
    }

    final id = _requestId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    final request = jsonEncode({
      'id': id,
      'method': method,
      'params': params ?? {},
    });

    _process!.stdin.writeln(request);
    
    // Add timeout to prevent hanging
    return completer.future.timeout(
      timeout ?? const Duration(seconds: 60),
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('Request timed out: $method');
      },
    );
  }

  /// Initialize the Photos library connection.
  Future<Map<String, dynamic>> initialize() async {
    // Initialization can take a long time for large libraries
    final response = await call('initialize', null, const Duration(minutes: 5));
    if (response['result'] != null && response['result']['status'] == 'ok') {
      _isInitialized = true;
    }
    return response;
  }

  /// Get library information.
  Future<LibraryInfo?> getLibraryInfo() async {
    final response = await call('get_library_info');
    if (response.containsKey('result') && response['result'] != null) {
      return LibraryInfo.fromJson(response['result'] as Map<String, dynamic>);
    }
    return null;
  }

  /// Get library statistics.
  Future<LibraryStats> getStatistics() async {
    final response = await call('get_statistics');
    if (response.containsKey('result') && response['result'] != null) {
      return LibraryStats.fromJson(response['result'] as Map<String, dynamic>);
    }
    return LibraryStats();
  }

  /// Get all albums.
  Future<List<Album>> getAlbums() async {
    final response = await call('get_albums');
    if (response.containsKey('result') && response['result'] is List) {
      return (response['result'] as List)
          .map((e) => Album.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get all folders.
  Future<List<Folder>> getFolders() async {
    final response = await call('get_folders');
    if (response.containsKey('result') && response['result'] is List) {
      return (response['result'] as List)
          .map((e) => Folder.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get photos with optional filters.
  Future<List<Photo>> getPhotos({
    String? albumUuid,
    bool favoritesOnly = false,
    int? recentDays,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await call('get_photos', {
      'album_uuid': albumUuid,
      'favorites_only': favoritesOnly,
      'recent_days': recentDays,
      'limit': limit,
      'offset': offset,
    });
    if (response.containsKey('result') && response['result'] is List) {
      return (response['result'] as List)
          .map((e) => Photo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get detailed metadata for a specific photo.
  Future<PhotoMetadata?> getPhotoMetadata(String uuid) async {
    final response = await call('get_photo_metadata', {'uuid': uuid});
    if (response.containsKey('result') && response['result'] != null) {
      return PhotoMetadata.fromJson(response['result'] as Map<String, dynamic>);
    }
    return null;
  }

  /// Dispose of the Python process.
  void dispose() {
    _process?.kill();
    _process = null;
    _isInitialized = false;
  }
}
