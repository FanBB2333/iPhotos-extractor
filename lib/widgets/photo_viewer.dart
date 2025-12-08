import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo.dart';

/// Full-size photo viewer with metadata panel.
class PhotoViewer extends StatelessWidget {
  final Photo photo;
  final PhotoMetadata? metadata;
  final VoidCallback onClose;

  const PhotoViewer({
    super.key,
    required this.photo,
    this.metadata,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Toolbar
          _ViewerToolbar(
            photo: photo,
            onClose: onClose,
          ),
          
          // Main content area
          Expanded(
            child: Row(
              children: [
                // Photo display
                Expanded(
                  flex: 3,
                  child: _PhotoDisplay(photo: photo),
                ),
                
                // Metadata panel
                if (metadata != null)
                  SizedBox(
                    width: 280,
                    child: _MetadataPanel(metadata: metadata!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Toolbar for photo viewer.
class _ViewerToolbar extends StatelessWidget {
  final Photo photo;
  final VoidCallback onClose;

  const _ViewerToolbar({
    required this.photo,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
            tooltip: 'Close',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              photo.filename,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (photo.favorite)
            const Icon(Icons.favorite, color: Colors.red, size: 20),
        ],
      ),
    );
  }
}

/// Main photo display area.
class _PhotoDisplay extends StatelessWidget {
  final Photo photo;

  const _PhotoDisplay({required this.photo});

  @override
  Widget build(BuildContext context) {
    if (photo.path == null || !File(photo.path!).existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              'Image not available',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          File(photo.path!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}

/// Metadata panel showing photo details.
class _MetadataPanel extends StatelessWidget {
  final PhotoMetadata metadata;

  const _MetadataPanel({required this.metadata});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title section
          Text(
            'Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // File info
          _MetadataSection(
            title: 'File',
            items: [
              _MetadataItem(label: 'Filename', value: metadata.filename),
              if (metadata.title != null && metadata.title!.isNotEmpty)
                _MetadataItem(label: 'Title', value: metadata.title!),
              if (metadata.width != null && metadata.height != null)
                _MetadataItem(
                  label: 'Size',
                  value: '${metadata.width} x ${metadata.height}',
                ),
              if (metadata.date != null)
                _MetadataItem(label: 'Date', value: _formatDate(metadata.date!)),
            ],
          ),
          
          // Description
          if (metadata.description != null && metadata.description!.isNotEmpty)
            _MetadataSection(
              title: 'Description',
              items: [
                _MetadataItem(label: '', value: metadata.description!),
              ],
            ),
          
          // Camera info
          if (metadata.exif != null)
            _MetadataSection(
              title: 'Camera',
              items: [
                if (metadata.exif!.cameraMake != null)
                  _MetadataItem(label: 'Make', value: metadata.exif!.cameraMake!),
                if (metadata.exif!.cameraModel != null)
                  _MetadataItem(label: 'Model', value: metadata.exif!.cameraModel!),
                if (metadata.exif!.lensModel != null)
                  _MetadataItem(label: 'Lens', value: metadata.exif!.lensModel!),
                if (metadata.exif!.iso != null)
                  _MetadataItem(label: 'ISO', value: metadata.exif!.iso.toString()),
                if (metadata.exif!.focalLength != null)
                  _MetadataItem(label: 'Focal Length', value: '${metadata.exif!.focalLength}mm'),
                if (metadata.exif!.aperture != null)
                  _MetadataItem(label: 'Aperture', value: 'f/${metadata.exif!.aperture}'),
              ],
            ),
          
          // Location
          if (metadata.location != null)
            _MetadataSection(
              title: 'Location',
              items: [
                _MetadataItem(
                  label: 'Coordinates',
                  value: '${metadata.location!.latitude.toStringAsFixed(6)}, '
                      '${metadata.location!.longitude.toStringAsFixed(6)}',
                ),
              ],
            ),
          
          // Keywords
          if (metadata.keywords.isNotEmpty)
            _MetadataSection(
              title: 'Keywords',
              items: [
                _MetadataItem(label: '', value: metadata.keywords.join(', ')),
              ],
            ),
          
          // People
          if (metadata.persons.isNotEmpty)
            _MetadataSection(
              title: 'People',
              items: [
                _MetadataItem(label: '', value: metadata.persons.join(', ')),
              ],
            ),
          
          // Photo type badges
          _PhotoTypeBadges(metadata: metadata),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}

/// Section in metadata panel.
class _MetadataSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _MetadataSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }
}

/// Single metadata item.
class _MetadataItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo type indicator badges.
class _PhotoTypeBadges extends StatelessWidget {
  final PhotoMetadata metadata;

  const _PhotoTypeBadges({required this.metadata});

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];
    
    if (metadata.isHdr) badges.add(_Badge(label: 'HDR'));
    if (metadata.isLivePhoto) badges.add(_Badge(label: 'Live'));
    if (metadata.isPortrait) badges.add(_Badge(label: 'Portrait'));
    if (metadata.isPanorama) badges.add(_Badge(label: 'Panorama'));
    if (metadata.isSelfie) badges.add(_Badge(label: 'Selfie'));
    if (metadata.isSlowMo) badges.add(_Badge(label: 'Slow-Mo'));
    if (metadata.isTimeLapse) badges.add(_Badge(label: 'Time-Lapse'));
    if (metadata.isVideo) badges.add(_Badge(label: 'Video'));
    if (metadata.isScreenshot) badges.add(_Badge(label: 'Screenshot'));
    
    if (badges.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: badges,
      ),
    );
  }
}

/// Small badge chip.
class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
