import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/content_model.dart';
import '../models/quiz_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> stages = [
    'أولى ابتدائي',
    'ثانية ابتدائي',
    'ثالثة ابتدائي',
    'رابعة ابتدائي',
    'خامسة ابتدائي',
    'سادسة ابتدائي',
    'أولى إعدادي',
    'ثانية إعدادي',
    'ثالثة إعدادي',
    'أولى ثانوي',
    'ثانية ثانوي',
    'ثالثة ثانوي',
  ];

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> generateUniqueTeacherCode() async {
    while (true) {
      final code = _generateRandomCode();
      final existing = await _db
          .collection('users')
          .where('teacherCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        return code;
      }
    }
  }

  Future<String> regenerateTeacherCode(String teacherUid) async {
    final newCode = await generateUniqueTeacherCode();
    await _db.collection('users').doc(teacherUid).update({'teacherCode': newCode});
    return newCode;
  }

  Future<AppUser?> findTeacherByCode(String code) async {
    final trimmedCode = code.trim().toUpperCase();
    if (trimmedCode.isEmpty) return null;

    final result = await _db
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .where('teacherCode', isEqualTo: trimmedCode)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;
    return AppUser.fromMap(result.docs.first.data());
  }

  Stream<List<AppUser>> getPendingStudentsStream(String teacherUid) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('linkedTeacherUid', isEqualTo: teacherUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList());
  }

  Future<void> approveStudent(String studentUid) async {
    await _db.collection('users').doc(studentUid).update({'status': 'approved'});
  }

  Future<void> rejectStudent(String studentUid) async {
    await _db.collection('users').doc(studentUid).update({'status': 'rejected'});
  }

  Future<void> addContent(ContentItem item) async {
    await _db.collection('content').add(item.toMap());
  }

  Stream<List<ContentItem>> getContentStream(String teacherUid) {
    return _db
        .collection('content')
        .where('teacherId', isEqualTo: teacherUid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ContentItem.fromMap(doc.id, doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<ContentItem>> getContentStreamByStage(String teacherUid, String stage) {
    return _db
        .collection('content')
        .where('teacherId', isEqualTo: teacherUid)
        .where('stage', isEqualTo: stage)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => ContentItem.fromMap(doc.id, doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> deleteContent(String id) async {
    await _db.collection('content').doc(id).delete();
  }

  Future<void> addQuiz(Quiz quiz) async {
    await _db.collection('quizzes').add(quiz.toMap());
  }

  Stream<List<Quiz>> getQuizzesStream(String teacherUid) {
    return _db
        .collection('quizzes')
        .where('teacherUid', isEqualTo: teacherUid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Quiz.fromMap(doc.id, doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> submitQuizResult(QuizResult result) async {
    await _db.collection('quiz_results').add(result.toMap());
  }

  Stream<List<QuizResult>> getResultsForQuiz(String quizId) {
    return _db
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => QuizResult.fromMap(doc.data())).toList());
  }

  static String buildPrivateChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return 'private_${ids[0]}_${ids[1]}';
  }

  static String buildGeneralChatId(String teacherUid, String stage) {
    final safeStage = stage.trim();
    return 'general_${teacherUid}_${safeStage.hashCode.abs()}';
  }

  Future<void> sendMessage(AnnouncementMessage message) async {
    await _db.collection('messages').add(message.toMap());
  }

  Stream<List<AnnouncementMessage>> getMessagesStream(String chatId) {
    return _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) => AnnouncementMessage.fromMap(doc.id, doc.data())).toList();
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  /// حذف عند الطرفين (زي "Delete for everyone" في تليجرام)
  Future<void> deleteMessage(String id) async {
    await _db.collection('messages').doc(id).delete();
  }

  /// حذف عندي بس (زي "Delete for me" في تليجرام)
  Future<void> deleteMessageForMe(String messageId, String uid) async {
    await _db.collection('messages').doc(messageId).update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });
  }

  Stream<List<AppUser>> getStudentsStream(String teacherUid) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('linkedTeacherUid', isEqualTo: teacherUid)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList());
  }

  Stream<List<AppUser>> getLinkedTeacherStream(String teacherUid) {
    return _db.collection('users').doc(teacherUid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return <AppUser>[];
      return [AppUser.fromMap(doc.data()!)];
    });
  }
   // دالة أرشفة الطالب (تضاف في نهاية الملف)
  Future<void> archiveStudent(String studentId, Map<String, dynamic> studentData) async {
    try {
      await FirebaseFirestore.instance.collection('archived_students').doc(studentId).set(studentData);
      await FirebaseFirestore.instance.collection('students').doc(studentId).delete();
    } catch (e) {
      print("Error archiving: $e");
    }
  }

  // دالة استعادة الطالب بكود جديد (تضاف بجانبها في نهاية الملف)
  Future<void> restoreStudent(String studentId, String newCode) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('archived_students').doc(studentId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['access_code'] = newCode; 
        await FirebaseFirestore.instance.collection('students').doc(studentId).set(data);
        await FirebaseFirestore.instance.collection('archived_students').doc(studentId).delete();
      }
    } catch (e) {
      print("Error restoring: $e");
    }
  }
}
