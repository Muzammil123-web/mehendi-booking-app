import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Uploads a local file (picked from the phone's gallery) to Cloudinary's
/// free tier and returns a public URL to save on the Firestore doc.
///
/// SETUP (one-time, free, no credit card):
/// 1. Create a free account at https://cloudinary.com
/// 2. On your Cloudinary dashboard, copy your "Cloud name"
/// 3. Go to Settings (gear icon) -> Upload -> scroll to "Upload presets" ->
///    click "Add upload preset" -> set Signing Mode to "Unsigned" -> Save,
///    and copy the preset name it gives you
/// 4. Paste both values below
class StorageService {
  // TODO: replace these two with your own free Cloudinary account details.
static const String cloudName = 'hy3uy2cx';
static const String uploadPreset = 'newbookingapp';

  Future<String> uploadWorkPostFile(File file, {required bool isVideo}) async {
   if (cloudName.isEmpty || uploadPreset.isEmpty) {
  throw Exception('Cloudinary is not configured.');
}

    final resourceType = isVideo ? 'video' : 'image';
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Upload failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }
}
