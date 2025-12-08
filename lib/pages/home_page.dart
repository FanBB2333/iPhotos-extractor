import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/sidebar.dart';
import '../widgets/photo_grid.dart';
import '../widgets/album_card.dart';
import '../widgets/photo_viewer.dart';
import '../providers/photos_provider.dart';
import 'dashboard_page.dart';

/// Main home page with left-right layout.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotosProvider>();

    // Show full-screen photo viewer if a photo is selected
    if (provider.selectedPhotoUuid != null) {
      final photo = provider.photos.firstWhere(
        (p) => p.uuid == provider.selectedPhotoUuid,
      );
      return PhotoViewer(
        photo: photo,
        metadata: provider.selectedPhotoMetadata,
        onClose: () => provider.clearPhotoSelection(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Left sidebar
          const Sidebar(),
          
          // Right content area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _ContentHeader(provider: provider),
                
                // Main content
                Expanded(
                  child: _MainContent(provider: provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Content area header.
class _ContentHeader extends StatelessWidget {
  final PhotosProvider provider;

  const _ContentHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button for album detail view
          if (provider.currentView == NavView.albums && 
              provider.selectedAlbumUuid != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => provider.navigateTo(NavView.albums),
              tooltip: 'Back to Albums',
            ),
          
          // Title
          Expanded(
            child: Text(
              provider.currentViewTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Photo count
          if (provider.photos.isNotEmpty)
            Text(
              '${provider.photos.length} photos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Main content area based on current view.
class _MainContent extends StatelessWidget {
  final PhotosProvider provider;

  const _MainContent({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => provider.initialize(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show content based on current view
    switch (provider.currentView) {
      case NavView.dashboard:
        return const DashboardPage();
      
      case NavView.library:
      case NavView.favorites:
      case NavView.recent:
        return PhotoGrid(
          photos: provider.photos,
          selectedPhotoUuid: null,
          onPhotoTap: (photo) => provider.selectPhoto(photo.uuid),
        );
      
      case NavView.albums:
        if (provider.selectedAlbumUuid != null) {
          // Show album photos
          return PhotoGrid(
            photos: provider.photos,
            selectedPhotoUuid: null,
            onPhotoTap: (photo) => provider.selectPhoto(photo.uuid),
          );
        } else {
          // Show album grid
          return AlbumGrid(
            albums: provider.albums,
            onAlbumTap: (album) {
              provider.loadAlbumPhotos(album.uuid);
            },
          );
        }
      
      case NavView.folders:
        return _FoldersView(folders: provider.folders);
    }
  }
}

/// Simple folders view.
class _FoldersView extends StatelessWidget {
  final List<dynamic> folders;

  const _FoldersView({required this.folders});

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No folders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.folder),
            title: Text(folder.title),
            subtitle: Text(
              '${folder.subfolders.length} subfolders, ${folder.albums.length} albums',
            ),
          ),
        );
      },
    );
  }
}
