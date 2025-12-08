import 'dart:io';
import 'package:flutter/material.dart';
import '../models/album.dart';

/// Grid of album cards.
class AlbumGrid extends StatelessWidget {
  final List<Album> albums;
  final void Function(Album album) onAlbumTap;

  const AlbumGrid({
    super.key,
    required this.albums,
    required this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_album_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No albums',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return AlbumCard(
          album: album,
          onTap: () => onAlbumTap(album),
        );
      },
    );
  }
}

/// Individual album card.
class AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: album.coverPath != null && File(album.coverPath!).existsSync()
                    ? Image.file(
                        File(album.coverPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        cacheWidth: 400,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) => 
                            _AlbumPlaceholder(),
                      )
                    : _AlbumPlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Album title
          Text(
            album.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Photo count
          Text(
            '${album.count} photos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for albums without cover image.
class _AlbumPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.photo_album,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
