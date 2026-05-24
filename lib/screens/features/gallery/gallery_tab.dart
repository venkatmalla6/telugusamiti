import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/album_model.dart';
import '../../../models/album_model.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/services/gallery_service.dart';

class GalleryTab extends ConsumerStatefulWidget {
  const GalleryTab({super.key});

  @override
  ConsumerState<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends ConsumerState<GalleryTab> {
  @override
  void initState() {
    super.initState();
    // Force a fresh load whenever this tab is opened/mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
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
              foregroundColor: const Color(0xFF5C0A0A),
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
                      return _AlbumTile(
                        album: albums[index],
                        canManage: canManage,
                        onRefresh: () => notifier.refresh(),
                      );
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
              icon: const Icon(Icons.add_photo_alternate, color: const Color(0xFF5C0A0A)),
              label: const Text('New Album', style: TextStyle(color: const Color(0xFF5C0A0A))),
            )
          : null,
    );
  }
}

class _AlbumTile extends ConsumerWidget {
  final Album album;
  final bool canManage;
  final VoidCallback onRefresh;

  const _AlbumTile({
    required this.album,
    required this.canManage,
    required this.onRefresh,
  });

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController(text: album.title);
    final catCtrl = TextEditingController(text: album.category);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF5C0A0A),
        title: const Text('Edit Album', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: catCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGold),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                try {
                  await ref.read(galleryServiceProvider).updateAlbum(
                        album.id,
                        titleCtrl.text.trim(),
                        catCtrl.text.trim(),
                      );
                  onRefresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Album updated successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF5C0A0A))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF5C0A0A),
        title: const Text('Delete Album', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this album? All media inside will be removed. This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(galleryServiceProvider).deleteAlbum(album.id);
                onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Album deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/gallery/album/${album.id}', extra: album),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF5C0A0A),
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
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
                  if (canManage)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          color: const Color(0xFF5C0A0A),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showEditDialog(context, ref);
                            } else if (val == 'delete') {
                              _confirmDelete(context, ref);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                      color: const Color(0xFF5C0A0A).withValues(alpha: 0.2),
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
