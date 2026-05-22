import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../models/album_model.dart';
import '../../../models/media_item_model.dart';
import '../../../providers/dashboard_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/services/gallery_service.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class AlbumViewScreen extends ConsumerWidget {
  final Album album;

  const AlbumViewScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(albumMediaProvider(album.id));
    final user = ref.watch(currentUserProvider).value;
    final canManage = user?.isAdminOrSuperAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(album.title),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteAlbum(context, ref),
            ),
        ],
      ),
      body: mediaAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.photo_library_outlined,
              title: 'Album is Empty',
              subtitle: 'Media items will appear here once they are added.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _MediaTile(
                item: items[index],
                albumId: album.id,
                canManage: canManage,
              );
            },
          );
        },
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 15,
          itemBuilder: (_, __) => const SkeletonBox(height: double.infinity, borderRadius: 8),
        ),
        error: (err, _) => Center(child: Text('Error loading media: $err')),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/gallery/album/${album.id}/add_media'),
              backgroundColor: AppColors.primaryMaroon,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Media', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Future<void> _confirmDeleteAlbum(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Album?'),
        content: const Text('Are you sure you want to delete this entire album and all its media?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
      );
      
      try {
        await ref.read(galleryServiceProvider).deleteAlbum(album.id);
        if (context.mounted) {
          Navigator.pop(context); // pop loading
          context.pop(); // go back to gallery
          ref.read(galleryNotifierProvider.notifier).refresh();
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // pop loading
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _MediaTile extends ConsumerWidget {
  final MediaItem item;
  final String albumId;
  final bool canManage;

  const _MediaTile({
    required this.item,
    required this.albumId,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showFullMedia(context, ref),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildThumbnail(),
          ),
          if (item.type == 'video')
            const Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
            ),
          if (item.type == 'drive_link')
            const Center(
              child: Icon(Icons.link, color: Colors.white, size: 36),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    if (item.type == 'drive_link') {
      return Container(color: Colors.blueAccent);
    }
    final url = item.type == 'video' ? item.thumbUrl : item.downloadUrl;
    if (url == null || url.isEmpty) {
      return Container(color: Colors.grey[300], child: const Icon(Icons.broken_image));
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) => progress == null ? child : const SkeletonBox(height: double.infinity),
      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
    );
  }

  void _showFullMedia(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: _buildFullContent(context),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            if (item.caption != null)
              Positioned(
                bottom: canManage ? 80 : 24,
                left: 16,
                right: 16,
                child: Text(
                  item.caption!,
                  style: const TextStyle(color: Colors.white, fontSize: 16, shadows: [Shadow(blurRadius: 4)]),
                  textAlign: TextAlign.center,
                ),
              ),
            if (canManage)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _editCaption(ctx, ref),
                      tooltip: 'Edit Caption',
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteMedia(ctx, ref),
                      tooltip: 'Delete Media',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullContent(BuildContext context) {
    if (item.type == 'drive_link') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.drive_file_move, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(item.downloadUrl, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('(Tap link to open in browser)', style: TextStyle(color: Colors.white70)),
        ],
      );
    } else if (item.type == 'video') {
      return _VideoPlayerItem(videoUrl: item.downloadUrl);
    } else {
      return InteractiveViewer(child: Image.network(item.downloadUrl));
    }
  }

  Future<void> _editCaption(BuildContext dialogContext, WidgetRef ref) async {
    final controller = TextEditingController(text: item.caption);
    final result = await showDialog<String>(
      context: dialogContext,
      builder: (c) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter caption...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, controller.text), child: const Text('Save')),
        ],
      ),
    );

    if (result != null) {
      try {
        await ref.read(galleryServiceProvider).updateMediaCaption(albumId, item.id, result);
      } catch (e) {
        // Handle error implicitly
      }
    }
  }

  Future<void> _deleteMedia(BuildContext dialogContext, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: dialogContext,
      builder: (c) => AlertDialog(
        title: const Text('Delete Media?'),
        content: const Text('This will permanently delete this item.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(galleryServiceProvider).deleteMediaItem(albumId, item);
        if (dialogContext.mounted) {
          Navigator.pop(dialogContext); // close full screen
        }
      } catch (e) {
        // error
      }
    }
  }
}

class _VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerItem({required this.videoUrl});

  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
