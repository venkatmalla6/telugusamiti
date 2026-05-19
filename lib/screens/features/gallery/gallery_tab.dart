import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/gallery_model.dart';
import '../../../providers/dashboard_providers.dart';

class GalleryTab extends ConsumerWidget {
  const GalleryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryState = ref.watch(galleryNotifierProvider);
    final notifier = ref.read(galleryNotifierProvider.notifier);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primaryMaroon,
        onRefresh: () async => notifier.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar(
              title: Text('Gallery'),
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
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
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
                  icon: Icons.photo_camera_back_outlined,
                  title: 'Gallery is Empty',
                  subtitle: 'Event photos will appear here after they are uploaded by the Samiti.',
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
                      final photos = galleryState.items;
                      if (index == photos.length) {
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
                      return _GalleryTile(photo: galleryState.items[index]);
                    },
                    childCount: galleryState.items.length + (galleryState.hasMore ? 1 : 0),
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final GalleryModel photo;
  const _GalleryTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          photo.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : const SkeletonBox(height: double.infinity),
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(photo.imageUrl),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              if (photo.caption != null)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Text(
                    photo.caption!,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
