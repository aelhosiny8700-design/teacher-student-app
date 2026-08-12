import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// خدمة رفع الملفات (صور, فيديوهات, مستندات) إلى Cloudinary
/// فمن الآمن وضعها هنا (Unsigned Upload Preset) البيانات دي مش سرية ///
class CloudinaryService {
  static const String cloudName = 'liklhr8f';
  static const String uploadPreset = 'teacher_app_uploads';

  /// يرفع أي نوع ملف (صورة/فيديو/مستند) ويرجع رابط الملف بعد الرفع.
  /// بيرجع UploadResult فيه إما url أو رسالة خطأ واضحة تتعرض للمستخدم.
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
        // ignore: avoid_print
        print('Cloudinary upload error (${response.statusCode}): $responseBody');
        return UploadResult.failure(
          'فشل الرفع (${response.statusCode}): $cloudinaryMessage',
        );
      }
    } catch (e) {
      // ignore: avoid_print
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
lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
    String? stage,
    String? teacherCode,
  }) async {
    String? linkedTeacherUid;
    String? myTeacherCode;
    String status = 'approved';

    // نتحقق من كود المعلم *قبل* أي استدعاء لـ createUserWithEmailAndPassword.
    // لو الكود غلط بنوقف هنا فورًا من غير ما ننشئ أي حساب في Firebase Auth،
    // وده اللي بيمنع مشكلة "اللف والخروج" لأن حالة تسجيل الدخول
    // مش بتتغير أصلاً في حالة الفشل.
    if (role == 'student') {
      if (teacherCode == null || teacherCode.trim().isEmpty) {
        return 'من فضلك أدخل كود المعلم';
      }

      try {
        final teacher = await _firestoreService.findTeacherByCode(teacherCode.trim());

        if (teacher == null) {
          return 'كود المعلم غير صحيح';
        }

        linkedTeacherUid = teacher.uid;
        status = 'pending';
      } catch (e) {
        return 'تعذر التحقق من كود المعلم، حاول تاني (${e.toString()})';
      }
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      if (role == 'teacher') {
        myTeacherCode = await _firestoreService.generateUniqueTeacherCode();
      }

      final newUser = AppUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        stage: role == 'student' ? stage : null,
        teacherCode: role == 'teacher' ? myTeacherCode : null,
        linkedTeacherUid: linkedTeacherUid,
        status: status,
      );

      await _db.collection('users').doc(uid).set(newUser.toMap());

      if (role == 'student' && status == 'pending') {
        await _auth.signOut();
        return 'تم إنشاء حسابك بنجاح، وهيتم تفعيله بعد موافقة المعلم';
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'خطأ: $e';
    }
  }

  Future<String?> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final userData = await getUserData(uid);

      if (userData == null) {
        await _auth.signOut();
        return 'تعذر تحميل بيانات المستخدم';
      }

      if (userData.role == 'student') {
        if (userData.status == 'pending') {
          await _auth.signOut();
          return 'حسابك لسه قيد المراجعة من المعلم، حاول تاني بعدين';
        }
        if (userData.status == 'rejected') {
          await _auth.signOut();
          return 'تم رفض طلب انضمامك، تواصل مع المعلم';
        }
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'خطأ: $e';
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
        return 'أدخل إيميل صحيح';
      }
      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'خطأ: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'الإيميل ده مستخدم قبل كده';
      case 'invalid-email':
        return 'الإيميل مش صحيح';
      case 'weak-password':
        return 'كلمة السر لازم تكون 6 حروف على الأقل';
      case 'user-not-found':
        return 'الحساب ده مش موجود';
      case 'wrong-password':
        return 'كلمة السر غلط';
      case 'invalid-credential':
        return 'الإيميل أو كلمة السر غلط';
      default:
        return 'خطأ: $code';
    }
  }
}
