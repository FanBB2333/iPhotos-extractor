import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo.dart';

/// Grid view for displaying photos.
class PhotoGrid extends StatelessWidget {
  final List<Photo> photos;
  final String? selectedPhotoUuid;
  final void Function(Photo photo) onPhotoTap;
  final void Function(Photo photo)? onPhotoDoubleTap;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.selectedPhotoUuid,
    required this.onPhotoTap,
    this.onPhotoDoubleTap,
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

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
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
              if (photo.path != null && File(photo.path!).existsSync())
                Image.file(
                  File(photo.path!),
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
