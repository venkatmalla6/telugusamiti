import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/album_model.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/auth_provider.dart';

class GalleryTab extends ConsumerWidget {
  const GalleryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryState = ref.watch(galleryNotifierProvider);
    final notifier = ref.read(galleryNotifierProvider.notifier);
    final user = ref.watch(currentUserProvider).value;
    final canManage = user?.isAdminOrSuperAdmin ?? false;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primaryMaroon,
        onRefresh: () async => notifier.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar(
              title: Text('Gallery Albums'),
              pinned: true,
              backgroundColor: AppColors.primaryMaroon,
              foregroundColor: Colors.white,
            ),
            if (galleryState.isLoading && galleryState.items.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => const SkeletonBox(height: double.infinity, borderRadius: 12),
                    childCount: 9,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                ),
              )
            else if (galleryState.error != null && galleryState.items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateWidget(
                  icon: Icons.photo_library_outlined,
                  title: 'Could not load gallery',
                  subtitle: 'Pull down to refresh',
                  actionLabel: 'Try Again',
                  onAction: () => notifier.refresh(),
                ),
              )
            else if (galleryState.items.isEmpty)
              SliverToBoxAdapter(
                child: EmptyStateWidget(
                  icon: Icons.photo_album_outlined,
                  title: 'No Albums Yet',
                  subtitle: 'Event albums will appear here once they are created by the Samiti.',
                  actionLabel: 'Refresh',
                  onAction: () => notifier.refresh(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final albums = galleryState.items;
                      if (index == albums.length) {
                        return galleryState.hasMore
                            ? GestureDetector(
                                onTap: () => notifier.loadMore(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryMaroon.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, color: AppColors.primaryMaroon),
                                        SizedBox(height: 4),
                                        Text('More', style: TextStyle(fontSize: 12, color: AppColors.primaryMaroon)),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      return _AlbumTile(album: albums[index]);
                    },
                    childCount: galleryState.items.length + (galleryState.hasMore ? 1 : 0),
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/gallery/create').then((_) => notifier.refresh()),
              backgroundColor: AppColors.primaryMaroon,
              icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
              label: const Text('New Album', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}

class _AlbumTile extends StatelessWidget {
  final Album album;
  const _AlbumTile({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/gallery/album/${album.id}', extra: album),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  album.coverUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const SkeletonBox(height: double.infinity),
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title.isEmpty ? 'Untitled Album' : album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black, // Explicitly black for white background
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      album.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryMaroon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
