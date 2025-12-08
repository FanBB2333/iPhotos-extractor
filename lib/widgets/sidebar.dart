import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/photos_provider.dart';

/// Left sidebar navigation widget.
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PhotosProvider>();
    final stats = provider.stats;
    
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Photos Viewer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  count: 0, // No count for dashboard
                  isSelected: provider.currentView == NavView.dashboard,
                  onTap: () => provider.navigateTo(NavView.dashboard),
                ),
                const SizedBox(height: 8),
                _NavSection(
                  title: 'Library',
                  children: [
                    _NavItem(
                      icon: Icons.photo_library,
                      label: 'All Photos',
                      count: stats.total,
                      isSelected: provider.currentView == NavView.library,
                      onTap: () => provider.navigateTo(NavView.library),
                    ),
                    _NavItem(
                      icon: Icons.favorite,
                      label: 'Favorites',
                      count: stats.favorites,
                      isSelected: provider.currentView == NavView.favorites,
                      onTap: () => provider.navigateTo(NavView.favorites),
                    ),
                    _NavItem(
                      icon: Icons.access_time,
                      label: 'Recent',
                      count: stats.recent30Days,
                      isSelected: provider.currentView == NavView.recent,
                      onTap: () => provider.navigateTo(NavView.recent),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _NavSection(
                  title: 'Collections',
                  children: [
                    _NavItem(
                      icon: Icons.photo_album,
                      label: 'Albums',
                      count: stats.albums,
                      isSelected: provider.currentView == NavView.albums &&
                          provider.selectedAlbumUuid == null,
                      onTap: () => provider.navigateTo(NavView.albums),
                    ),
                    _NavItem(
                      icon: Icons.folder,
                      label: 'Folders',
                      count: stats.folders,
                      isSelected: provider.currentView == NavView.folders,
                      onTap: () => provider.navigateTo(NavView.folders),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _NavSection(
                  title: 'Media Types',
                  children: [
                    _NavItem(
                      icon: Icons.videocam,
                      label: 'Videos',
                      count: stats.videos,
                      isSelected: false,
                      onTap: () {
                        // TODO: Implement video filter
                      },
                    ),
                    _NavItem(
                      icon: Icons.screenshot,
                      label: 'Screenshots',
                      count: stats.screenshots,
                      isSelected: false,
                      onTap: () {
                        // TODO: Implement screenshot filter
                      },
                    ),
                    _NavItem(
                      icon: Icons.motion_photos_on,
                      label: 'Live Photos',
                      count: stats.livePhotos,
                      isSelected: false,
                      onTap: () {
                        // TODO: Implement live photo filter
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Library info footer
          if (provider.libraryInfo != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${stats.total} photos, ${stats.albums} albums',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Navigation section with title.
class _NavSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _NavSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// Single navigation item.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primaryContainer 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected 
                  ? colorScheme.primary 
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected 
                      ? colorScheme.onPrimaryContainer 
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (count > 0)
              Text(
                count.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
