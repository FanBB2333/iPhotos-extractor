import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo.dart';

/// Grid view for displaying photos with infinite scroll support.
class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;
  final String? selectedPhotoUuid;
  final void Function(Photo photo) onPhotoTap;
  final void Function(Photo photo)? onPhotoDoubleTap;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.selectedPhotoUuid,
    required this.onPhotoTap,
    this.onPhotoDoubleTap,
    this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Total items = photos + loading indicator if loading more
    final itemCount = photos.length + (isLoadingMore ? 1 : 0);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final metrics = notification.metrics;
          // Trigger load more when scrolled to 80% of the content
          if (metrics.pixels >= metrics.maxScrollExtent * 0.8) {
            if (hasMore && !isLoadingMore && onLoadMore != null) {
              onLoadMore!();
            }
          }
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index >= photos.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          final photo = photos[index];
          final isSelected = photo.uuid == selectedPhotoUuid;
          
          return _PhotoTile(
            photo: photo,
            isSelected: isSelected,
            onTap: () => onPhotoTap(photo),
            onDoubleTap: onPhotoDoubleTap != null 
                ? () => onPhotoDoubleTap!(photo) 
                : null,
          );
        },
      ),
    );
  }
}


/// Individual photo tile in the grid.
class _PhotoTile extends StatelessWidget {
  final Photo photo;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const _PhotoTile({
    required this.photo,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 3)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isSelected ? 5 : 8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo image
              if (_getImagePath(photo) != null)
                Image.file(
                  File(_getImagePath(photo)!),
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) => _PlaceholderImage(
                    icon: Icons.broken_image,
                  ),
                )
              else

                _PlaceholderImage(icon: Icons.image),
              
              // Overlay indicators
              Positioned(
                top: 4,
                right: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (photo.favorite)
                      _IndicatorBadge(
                        icon: Icons.favorite,
                        color: Colors.red,
                      ),
                    if (photo.isVideo)
                      _IndicatorBadge(
                        icon: Icons.play_circle_filled,
                        color: Colors.white,
                      ),
                    if (photo.isLivePhoto)
                      _IndicatorBadge(
                        icon: Icons.motion_photos_on,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    }

  String? _getImagePath(Photo photo) {
    if (photo.path != null && File(photo.path!).existsSync()) {
      return photo.path;
    }
    if (photo.previewPath != null && File(photo.previewPath!).existsSync()) {
      return photo.previewPath;
    }
    return null;
  }
}

/// Placeholder image for loading/error states.
class _PlaceholderImage extends StatelessWidget {
  final IconData icon;

  const _PlaceholderImage({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Small indicator badge for photo status.
class _IndicatorBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IndicatorBadge({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        size: 14,
        color: color,
      ),
    );
  }
}
