import 'package:flutter/material.dart';
import '../models/album.dart';
import '../models/photo.dart';
import '../models/folder.dart';
import '../models/library_info.dart';
import '../services/python_bridge.dart';

/// Navigation view types
enum NavView {
  dashboard,
  library,
  albums,
  favorites,
  recent,
  folders,
}

/// State provider for the photos app.
class PhotosProvider extends ChangeNotifier {
  final PythonBridge _bridge;
  
  // Current navigation state
  NavView _currentView = NavView.dashboard;
  String? _selectedAlbumUuid;
  String? _selectedPhotoUuid;
  
  // Data
  LibraryInfo? _libraryInfo;
  LibraryStats _stats = LibraryStats();
  List<Album> _albums = [];
  List<Folder> _folders = [];
  List<Photo> _photos = [];
  PhotoMetadata? _selectedPhotoMetadata;
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isInitialized = false;
  String? _error;
  
  // Pagination state
  int _currentOffset = 0;
  bool _hasMore = true;
  static const int _pageSize = 100;

  PhotosProvider(this._bridge);

  // Getters
  NavView get currentView => _currentView;
  String? get selectedAlbumUuid => _selectedAlbumUuid;
  String? get selectedPhotoUuid => _selectedPhotoUuid;
  LibraryInfo? get libraryInfo => _libraryInfo;
  LibraryStats get stats => _stats;
  List<Album> get albums => _albums;
  List<Folder> get folders => _folders;
  List<Photo> get photos => _photos;
  PhotoMetadata? get selectedPhotoMetadata => _selectedPhotoMetadata;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isInitialized => _isInitialized;
  bool get hasMore => _hasMore;
  String? get error => _error;

  /// Initialize the provider and load initial data.
  Future<void> initialize() async {
    _setLoading(true);
    _error = null;
    
    try {
      await _bridge.start();
      final result = await _bridge.initialize();
      
      if (result['result']?['status'] == 'ok') {
        _isInitialized = true;
        
        // Load initial data
        await Future.wait([
          _loadLibraryInfo(),
          _loadAlbums(),
          _loadFolders(),
          _loadStatistics(),
        ]);
        
        // Initial data loaded
      } else {
        _error = result['result']?['message'] ?? result['error'] ?? 'Failed to initialize';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _loadLibraryInfo() async {
    _libraryInfo = await _bridge.getLibraryInfo();
  }

  Future<void> _loadAlbums() async {
    _albums = await _bridge.getAlbums();
  }

  Future<void> _loadFolders() async {
    _folders = await _bridge.getFolders();
  }

  Future<void> _loadStatistics() async {
    _stats = await _bridge.getStatistics();
  }

  /// Navigate to a specific view.
  void navigateTo(NavView view) {
    if (_currentView == view && view != NavView.albums) return;
    
    _currentView = view;
    _selectedAlbumUuid = null;
    _selectedPhotoUuid = null;
    _selectedPhotoMetadata = null;
    notifyListeners();
    
    switch (view) {
      case NavView.dashboard:
        // Dashboard uses stats data already loaded
        _photos = [];
        notifyListeners();
        break;
      case NavView.library:
        loadLibraryPhotos();
        break;
      case NavView.albums:
        // Albums view shows album list, no photos to load
        _photos = [];
        notifyListeners();
        break;
      case NavView.favorites:
        loadFavoritePhotos();
        break;
      case NavView.recent:
        loadRecentPhotos();
        break;
      case NavView.folders:
        // Folders view shows folder structure
        _photos = [];
        notifyListeners();
        break;
    }
  }

  /// Load all library photos.
  Future<void> loadLibraryPhotos() async {
    _setLoading(true);
    _currentOffset = 0;
    _hasMore = true;
    try {
      _photos = await _bridge.getPhotos(limit: _pageSize, offset: 0);
      _currentOffset = _photos.length;
      _hasMore = _photos.length >= _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Load more library photos (pagination).
  Future<void> loadMorePhotos() async {
    if (_isLoadingMore || !_hasMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      List<Photo> morePhotos;
      switch (_currentView) {
        case NavView.library:
          morePhotos = await _bridge.getPhotos(limit: _pageSize, offset: _currentOffset);
          break;
        case NavView.favorites:
          morePhotos = await _bridge.getPhotos(favoritesOnly: true, limit: _pageSize, offset: _currentOffset);
          break;
        case NavView.recent:
          morePhotos = await _bridge.getPhotos(recentDays: 30, limit: _pageSize, offset: _currentOffset);
          break;
        case NavView.albums:
          if (_selectedAlbumUuid != null) {
            morePhotos = await _bridge.getPhotos(albumUuid: _selectedAlbumUuid, limit: _pageSize, offset: _currentOffset);
          } else {
            morePhotos = [];
          }
          break;
        default:
          morePhotos = [];
      }
      
      if (morePhotos.isNotEmpty) {
        _photos = [..._photos, ...morePhotos];
        _currentOffset += morePhotos.length;
        _hasMore = morePhotos.length >= _pageSize;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load favorite photos.
  Future<void> loadFavoritePhotos() async {
    _setLoading(true);
    _currentOffset = 0;
    _hasMore = true;
    try {
      _photos = await _bridge.getPhotos(favoritesOnly: true, limit: _pageSize, offset: 0);
      _currentOffset = _photos.length;
      _hasMore = _photos.length >= _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Load recent photos (last 30 days).
  Future<void> loadRecentPhotos() async {
    _setLoading(true);
    _currentOffset = 0;
    _hasMore = true;
    try {
      _photos = await _bridge.getPhotos(recentDays: 30, limit: _pageSize, offset: 0);
      _currentOffset = _photos.length;
      _hasMore = _photos.length >= _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Load photos from a specific album.
  Future<void> loadAlbumPhotos(String albumUuid) async {
    _selectedAlbumUuid = albumUuid;
    _setLoading(true);
    _currentOffset = 0;
    _hasMore = true;
    try {
      _photos = await _bridge.getPhotos(albumUuid: albumUuid, limit: _pageSize, offset: 0);
      _currentOffset = _photos.length;
      _hasMore = _photos.length >= _pageSize;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Select a photo and load its metadata.
  Future<void> selectPhoto(String uuid) async {
    _selectedPhotoUuid = uuid;
    _selectedPhotoMetadata = null;
    notifyListeners();
    
    try {
      _selectedPhotoMetadata = await _bridge.getPhotoMetadata(uuid);
      notifyListeners();
    } catch (e) {
      print('Error loading photo metadata: $e');
    }
  }

  /// Clear photo selection.
  void clearPhotoSelection() {
    _selectedPhotoUuid = null;
    _selectedPhotoMetadata = null;
    notifyListeners();
  }

  /// Get the title for the current view.
  String get currentViewTitle {
    switch (_currentView) {
      case NavView.dashboard:
        return 'Dashboard';
      case NavView.library:
        return 'Library';
      case NavView.albums:
        if (_selectedAlbumUuid != null) {
          final album = _albums.firstWhere(
            (a) => a.uuid == _selectedAlbumUuid,
            orElse: () => Album(uuid: '', title: 'Album', count: 0),
          );
          return album.title;
        }
        return 'Albums';
      case NavView.favorites:
        return 'Favorites';
      case NavView.recent:
        return 'Recent';
      case NavView.folders:
        return 'Folders';
    }
  }

  @override
  void dispose() {
    _bridge.dispose();
    super.dispose();
  }
}
