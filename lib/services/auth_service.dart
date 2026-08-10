import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
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
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'خطأ: $e';
    }
  }

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
      return 'خطأ: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

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
        return 'خطأ: $code';
    }
  }
}
5. انزل تحت واضغط "Commit changes" (الزرار الأخضر) → تأكيد
الجزء الثاني: تعديل صلاحيات قاعدة البيانات (Firestore)
1. افتح تاب/نافذة جديدة وروح على:
console.firebase.google.com
2. اضغط على مشروعك "Ahmed fikry"
3. من القايمة الجانبية على اليسار، دور على "Firestore Database" واضغط عليه
4. فوق هتلاقي تابات (Data / Rules / Indexes...) — اضغط على "Rules"
5. هتلاقي صندوق فيه كود — امسحه كله والصق ده بدله:
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
6. اضغط زرار "Publish" (المفروض يكون فوق على اليمين)
الجزء الثالث: بناء APK جديد
1. روح على Codemagic (codemagic.io)
2. افتح تطبيق teacher-student-app
3. اضغط "Start new build"
4. اختار workflow: "Android APK Build"
5. اضغط "Start new build" تاني للتأكيد
الجزء الرابع: التجربة
استنى الـ build يخلص (2-5 دقايق)
حمّل ملف app-release.apk
احذف التطبيق القديم من الموبايل
ثبّت الجديد
جرب تسجيل دخول أو عمل حساب جديد
ابعتلي سكرين شوت من رسالة الخطأ اللي هتظهر (لو ظهرت)
ابدأ بالجزء الأول وقولي أول ما تخلصه.
