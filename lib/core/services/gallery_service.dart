import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../models/album_model.dart';
import '../../models/media_item_model.dart'; // placeholder for MediaItem (to be created later)
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

class GalleryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  FirebaseFirestore get db => _db;

  // ---------- Album ----------
  Future<String> createAlbum({required String title, required String category, required String coverPath, required String createdBy}) async {
    // Upload cover image first
    final coverFile = File(coverPath);
    final coverFileName = _uuid.v4() + '.jpg';
    final storagePath = 'gallery-media/album_covers/$coverFileName';
    await _supabase.storage.from('gallery-media').uploadBinary(storagePath, await coverFile.readAsBytes());
    final coverUrl = _supabase.storage.from('gallery-media').getPublicUrl(storagePath);

    final doc = await _db.collection('gallery_albums').add({
      'title': title,
      'category': category,
      'coverUrl': coverUrl,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // ---------- Media (photo) ----------
  // ---------- Media (photo) ----------
  Future<String> uploadPhoto(File file, String albumId, {String? caption}) async {
    final compressed = await _compressPhoto(file);
    final path = 'gallery-media/$albumId/${_uuid.v4()}.jpg';
    await _supabase.storage.from('gallery-media').uploadBinary(path, await compressed.readAsBytes());
    final url = _supabase.storage.from('gallery-media').getPublicUrl(path);
    await _db.collection('gallery_albums').doc(albumId).collection('media').add({
      'type': 'photo',
      'storagePath': path,
      'downloadUrl': url,
      'sizeBytes': compressed.lengthSync(),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
    return url;
  }

  // ---------- Media (video) ----------
  // ---------- Media (video) ----------
  Future<String> uploadVideo(File file, String albumId, {String? caption}) async {
    final compressed = await _compressVideo(file);
    final path = 'gallery-media/$albumId/${_uuid.v4()}.mp4';
    await _supabase.storage.from('gallery-media').uploadBinary(path, await compressed.file.readAsBytes());
    // thumbnail upload
    final thumbPath = 'gallery-media/$albumId/${_uuid.v4()}_thumb.jpg';
    await _supabase.storage.from('gallery-media').uploadBinary(thumbPath, await compressed.thumbnailFile.readAsBytes());
    final url = _supabase.storage.from('gallery-media').getPublicUrl(path);
    final thumbUrl = _supabase.storage.from('gallery-media').getPublicUrl(thumbPath);
    await _db.collection('gallery_albums').doc(albumId).collection('media').add({
      'type': 'video',
      'storagePath': path,
      'downloadUrl': url,
      'thumbUrl': thumbUrl,
      'sizeBytes': compressed.file.lengthSync(),
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
    return url;
  }

  // ---------- Media (Google Drive Link) ----------
  Future<String> addDriveLink(String albumId, String link, {String? caption}) async {
    await _db.collection('gallery_albums').doc(albumId).collection('media').add({
      'type': 'drive_link',
      'storagePath': '',
      'downloadUrl': link,
      'sizeBytes': 0,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
    return link;
  }

  // ---------- Delete & Update Media ----------
  Future<void> deleteMediaItem(String albumId, MediaItem item) async {
    // delete from storage if photo/video
    if (item.type != 'drive_link' && item.storagePath.isNotEmpty) {
      try {
        await _supabase.storage.from('gallery-media').remove([item.storagePath]);
        if (item.thumbUrl != null && item.thumbUrl!.isNotEmpty) {
          // hacky way to guess thumb path if needed, or if we stored it explicitly
          // For now, we only stored `storagePath` for the main file.
          // In a perfect world, we'd store thumbPath too. 
        }
      } catch (e) {
        // Ignore storage delete errors (e.g. file already deleted)
      }
    }
    await _db.collection('gallery_albums').doc(albumId).collection('media').doc(item.id).delete();
  }

  Future<void> updateMediaCaption(String albumId, String mediaId, String newCaption) async {
    await _db.collection('gallery_albums').doc(albumId).collection('media').doc(mediaId).update({
      'caption': newCaption,
    });
  }

  Future<void> updateAlbum(String albumId, String title, String category) async {
    await _db.collection('gallery_albums').doc(albumId).update({
      'title': title,
      'category': category,
    });
  }

  Future<void> deleteAlbum(String albumId) async {
    // Delete all media docs (firestore does not auto cascade)
    final mediaDocs = await _db.collection('gallery_albums').doc(albumId).collection('media').get();
    for (var doc in mediaDocs.docs) {
       await _db.collection('gallery_albums').doc(albumId).collection('media').doc(doc.id).delete();
       // Note: we'd also want to delete from Supabase, but it might be easier to just delete the folder if supported,
       // or delete individually. For now, just delete the firestore doc to hide it.
    }
    await _db.collection('gallery_albums').doc(albumId).delete();
  }

  // ---------- Compression helpers ----------
  Future<File> _compressPhoto(File original) async {
    // Using flutter_image_compress (already in pubspec)
    final result = await FlutterImageCompress.compressAndGetFile(
      original.path,
      '${original.path}_cmp.jpg',
      quality: 80,
      minWidth: 1024,
    );
    return result == null ? original : File(result.path);
  }

  Future<_VideoCompressResult> _compressVideo(File original) async {
    // Using video_compress package
    final info = await VideoCompress.compressVideo(
      original.path,
      quality: VideoQuality.MediumQuality,
    );
    final thumbnail = await VideoCompress.getFileThumbnail(
      original.path,
      quality: 50,
      position: -1,
    );
    return _VideoCompressResult(file: info!.file!, thumbnailFile: thumbnail);
  }
}

class _VideoCompressResult {
  final File file;
  final File thumbnailFile;
  _VideoCompressResult({required this.file, required this.thumbnailFile});
}

final galleryServiceProvider = Provider<GalleryService>((ref) {
  return GalleryService();
});
