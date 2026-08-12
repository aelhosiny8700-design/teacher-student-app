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
