import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// خدمة رفع الملفات (صور, فيديوهات, مستندات) إلى Cloudinary
/// فمن الآمن وضعها هنا (Unsigned Upload Preset) البيانات دي مش سرية ///
class CloudinaryService {
  static const String cloudName = 'liklhr8f';
  static const String uploadPreset = 'teacher_app_uploads';

  static Future<UploadResult> uploadFile(
    File file, {
    required String resourceType,
  }) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
    );

    try {
      if (!await file.exists()) {
        return UploadResult.failure('الملف اللي اخترته مش موجود، اختار ملف تاني');
      }

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('انتهت مهلة الاتصال، تأكد من النت وحاول تاني'),
      );
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl == null) {
          return UploadResult.failure('الرفع نجح لكن الرابط مرجعش، جرب تاني');
        }
        return UploadResult.success(secureUrl);
      } else {
        String cloudinaryMessage = 'خطأ غير معروف';
        try {
          final data = jsonDecode(responseBody);
          cloudinaryMessage = data['error']?['message'] ?? cloudinaryMessage;
        } catch (_) {}
        print('Cloudinary upload error (${response.statusCode}): $responseBody');
        return UploadResult.failure(
          'فشل الرفع (${response.statusCode}): $cloudinaryMessage',
        );
      }
    } catch (e) {
      print('Cloudinary upload exception: $e');
      return UploadResult.failure('حصل خطأ أثناء الرفع: $e');
    }
  }
}

class UploadResult {
  final bool isSuccess;
  final String? url;
  final String? errorMessage;

  UploadResult._({required this.isSuccess, this.url, this.errorMessage});

  factory UploadResult.success(String url) =>
      UploadResult._(isSuccess: true, url: url);

  factory UploadResult.failure(String message) =>
      UploadResult._(isSuccess: false, errorMessage: message);
}
