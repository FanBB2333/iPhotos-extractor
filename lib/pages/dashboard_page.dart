import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photos_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotosProvider>();
    final info = provider.libraryInfo;
    final stats = provider.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Library Info Card
          if (info != null)
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.perm_media,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Library Connected',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Chip(
                          label: Text('Photos v${info.photosVersion}'),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                        label: 'Path', value: info.libraryPath, tooltip: true),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Database', value: info.dbVersion),
                  ],
                ),
              ),
            ),

          Text(
            'Statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Statistics Grid
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    icon: Icons.photo,
                    label: 'Total Photos',
                    value: '${stats.total}',
                    color: Colors.blue,
                  ),
                  _StatCard(
                    icon: Icons.videocam,
                    label: 'Videos',
                    value: '${stats.videos}',
                    color: Colors.orange,
                  ),
                  _StatCard(
                    icon: Icons.favorite,
                    label: 'Favorites',
                    value: '${stats.favorites}',
                    color: Colors.red,
                  ),
                  _StatCard(
                    icon: Icons.photo_album,
                    label: 'Albums',
                    value: '${stats.albums}',
                    color: Colors.green,
                  ),
                  _StatCard(
                    icon: Icons.folder,
                    label: 'Folders',
                    value: '${stats.folders}',
                    color: Colors.purple,
                  ),
                  _StatCard(
                    icon: Icons.motion_photos_on,
                    label: 'Live Photos',
                    value: '${stats.livePhotos}',
                    color: Colors.amber,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool tooltip;

  const _InfoRow({
    required this.label,
    required this.value,
    this.tooltip = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: tooltip
              ? Tooltip(
                  message: value,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final MaterialColor color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SizedBox(
        width: 160,
        height: 120, // Reduced height
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
