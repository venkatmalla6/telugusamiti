import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:telugu_samithi/core/services/gallery_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../models/album_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class CreateAlbumScreen extends ConsumerStatefulWidget {
  const CreateAlbumScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateAlbumScreen> createState() => _CreateAlbumScreenState();
}

class _CreateAlbumScreenState extends ConsumerState<CreateAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  XFile? _coverImage;
  List<XFile> _mediaFiles = [];
  final TextEditingController _driveLinkController = TextEditingController();

  bool _isLoading = false;

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _coverImage = image);
    }
  }

  Future<void> _pickMedia() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Add Photos'),
              onTap: () async {
                final picker = ImagePicker();
                try {
                  final images = await picker.pickMultiImage();
                  if (context.mounted) Navigator.pop(context);
                  
                  if (images.isNotEmpty) {
                    setState(() => _mediaFiles.addAll(images));
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully selected ${images.length} photos!')));
                  } else {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No photos were returned by the phone')));
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking photos: $e')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Add Video'),
              onTap: () async {
                final picker = ImagePicker();
                try {
                  final video = await picker.pickVideo(source: ImageSource.gallery);
                  if (context.mounted) Navigator.pop(context);
                  
                  if (video != null) {
                    setState(() => _mediaFiles.add(video));
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully selected 1 video!')));
                  } else {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No video was returned by the phone')));
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking video: $e')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAlbum() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap the empty box to select a cover image for the album')),
      );
      return;
    }
    setState(() => _isLoading = true);
      try {
        final user = ref.read(currentUserProvider).value!;
        final service = ref.read(galleryServiceProvider);
        // Create album and get its ID
        final albumId = await service.createAlbum(
          title: _titleController.text.trim(),
          category: _categoryController.text.trim(),
          coverPath: _coverImage!.path,
          createdBy: user.uid,
        );
        // Upload selected media items
        for (final media in _mediaFiles) {
          final ext = media.path.split('.').last.toLowerCase();
          if (ext == 'mp4' || ext == 'mov' || ext == 'avi') {
            await service.uploadVideo(File(media.path), albumId);
          } else {
            await service.uploadPhoto(File(media.path), albumId);
          }
        }
        // Optional Google Drive link
        final driveLink = _driveLinkController.text.trim();
        if (driveLink.isNotEmpty) {
          await service.db.collection('gallery_albums').doc(albumId).collection('media').add({
            'type': 'link',
            'url': driveLink,
            'addedBy': user.uid,
            'addedAt': FieldValue.serverTimestamp(),
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Album and media uploaded successfully')),
          );
          context.pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create album: $e')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Album'),
        backgroundColor: AppColors.primaryMaroon,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Album Title'),
                validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) => v == null || v.isEmpty ? 'Enter category' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickCover,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _coverImage == null
                      ? const Center(child: Icon(Icons.photo, size: 48))
                      : Image.file(File(_coverImage!.path), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              // Media picker button
              ElevatedButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.collections),
                label: const Text('Add Photos/Videos'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C0A0A)),
              ),
              const SizedBox(height: 8),
              // Show count of selected media
              if (_mediaFiles.isNotEmpty)
                Text('${_mediaFiles.length} media items selected', style: const TextStyle(color: Colors.black)),
              const SizedBox(height: 12),
              // Google Drive link field
              TextFormField(
                controller: _driveLinkController,
                decoration: const InputDecoration(labelText: 'Google Drive Link (optional)'),
              ),
              const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createAlbum,
                  icon: const Icon(Icons.save),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: const Color(0xFF5C0A0A))
                      : const Text('Create Album'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C0A0A),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
