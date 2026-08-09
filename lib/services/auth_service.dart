import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // تسجيل حساب جديد (مدرس أو طالب)
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String role, // "teacher" or "student"
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final newUser = AppUser(
        uid: uid,
        name: name,
        email: email.trim(),
        role: role,
      );

      await _db.collection('users').doc(uid).set(newUser.toMap());
      return null; // مفيش خطأ
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'حصل خطأ غير متوقع، حاول تاني';
    }
  }

  // تسجيل الدخول
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'حصل خطأ غير متوقع، حاول تاني';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // جلب بيانات المستخدم الحالي (اسمه، دوره: مدرس/طالب)
  Future<AppUser?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
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
        return 'حصل خطأ، حاول تاني';
    }
  }
}
