import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadProfileImage(File imageFile, String uid) async {
    try {
      // 1. Compress Image
      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(tempDir.path, '${uid}_compressed.jpg');
      
      final XFile? compressedImage = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );

      if (compressedImage == null) {
        throw Exception("Failed to compress image");
      }

      final fileToUpload = File(compressedImage.path);
      
      // 2. Upload to Supabase 'profile-images' bucket
      final fileName = '$uid-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'profiles/$fileName';

      await _supabase.storage.from('profile-images').upload(
            path,
            fileToUpload,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // 3. Get Public URL
      final String publicUrl = _supabase.storage.from('profile-images').getPublicUrl(path);

      // Clean up temp compressed file
      if (await fileToUpload.exists()) {
        await fileToUpload.delete();
      }

      return publicUrl;
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }
}
