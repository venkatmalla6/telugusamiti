import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/gallery_service.dart';

class AddMediaScreen extends ConsumerStatefulWidget {
  final String albumId;
  const AddMediaScreen({super.key, required this.albumId});

  @override
  ConsumerState<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends ConsumerState<AddMediaScreen> {
  final _picker = ImagePicker();
  
  bool _isUploading = false;
  
  // State for multiple files
  final List<File> _selectedFiles = [];
  final List<String> _fileTypes = []; // 'photo' or 'video'
  final List<TextEditingController> _captionControllers = [];

  // State for Drive link
  bool _isAddingDriveLink = false;
  final _driveLinkController = TextEditingController();
  final _driveCaptionController = TextEditingController();

  Future<void> _pickFiles(bool isVideo) async {
    if (isVideo) {
      final xFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (xFile != null) {
        setState(() {
          _selectedFiles.add(File(xFile.path));
          _fileTypes.add('video');
          _captionControllers.add(TextEditingController());
        });
      }
    } else {
      final xFiles = await _picker.pickMultiImage();
      if (xFiles.isNotEmpty) {
        setState(() {
          for (var x in xFiles) {
            _selectedFiles.add(File(x.path));
            _fileTypes.add('photo');
            _captionControllers.add(TextEditingController());
          }
        });
      }
    }
  }

  Future<void> _uploadAll() async {
    if (_selectedFiles.isEmpty && !_isAddingDriveLink) return;
    
    if (_isAddingDriveLink && _driveLinkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a Google Drive link.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final service = ref.read(galleryServiceProvider);

      // Add Drive link if any
      if (_isAddingDriveLink && _driveLinkController.text.trim().isNotEmpty) {
        await service.addDriveLink(
          widget.albumId, 
          _driveLinkController.text.trim(),
          caption: _driveCaptionController.text.trim()
        );
      }

      // Upload files
      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final type = _fileTypes[i];
        final caption = _captionControllers[i].text.trim();

        if (type == 'video') {
          await service.uploadVideo(file, widget.albumId, caption: caption);
        } else {
          await service.uploadPhoto(file, widget.albumId, caption: caption);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media uploaded successfully!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _fileTypes.removeAt(index);
      _captionControllers[index].dispose();
      _captionControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var c in _captionControllers) {
      c.dispose();
    }
    _driveLinkController.dispose();
    _driveCaptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Media'),
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: const Color(0xFF5C0A0A),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: const Color(0xFF5C0A0A)),
                  SizedBox(height: 16),
                  Text('Uploading media...', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pick Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickFiles(false),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Add Photos'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryMaroon),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickFiles(true),
                          icon: const Icon(Icons.video_library),
                          label: const Text('Add Video'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryMaroon),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _isAddingDriveLink = !_isAddingDriveLink),
                    icon: Icon(_isAddingDriveLink ? Icons.close : Icons.add_link),
                    label: Text(_isAddingDriveLink ? 'Cancel Drive Link' : 'Add Google Drive Link'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                  
                  if (_isAddingDriveLink) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _driveLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Google Drive Link',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _driveCaptionController,
                      decoration: const InputDecoration(
                        labelText: 'Caption (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const Divider(height: 32),
                  ],

                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Selected Files:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedFiles.length,
                      itemBuilder: (ctx, i) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                _fileTypes[i] == 'video'
                                    ? Container(
                                        width: 60, height: 60,
                                        color: Colors.black12,
                                        child: const Icon(Icons.videocam),
                                      )
                                    : Image.file(_selectedFiles[i], width: 60, height: 60, fit: BoxFit.cover),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _captionControllers[i],
                                    decoration: const InputDecoration(
                                      hintText: 'Add a caption...',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _removeFile(i),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 32),
                  if (_selectedFiles.isNotEmpty || _isAddingDriveLink)
                    ElevatedButton(
                      onPressed: _uploadAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C0A0A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Upload to Album', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                ],
              ),
            ),
    );
  }
}
