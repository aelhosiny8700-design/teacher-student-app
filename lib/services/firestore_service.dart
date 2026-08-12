import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart';
import '../models/quiz_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- المحتوى (ملفات / صور / فيديوهات) ----------

  Future<void> addContent(ContentItem item) async {
    await _db.collection('content').add(item.toMap());
  }

  Stream<List<ContentItem>> getContentStream() {
    return _db
        .collection('content')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContentItem.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// محتوى مفلتر حسب المرحلة الدراسية
  Stream<List<ContentItem>> getContentStreamByStage(String stage) {
    return _db
        .collection('content')
        .where('stage', isEqualTo: stage)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContentItem.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> deleteContent(String id) async {
    await _db.collection('content').doc(id).delete();
  }

  // ---------- الاختيارات ----------

  Future<void> addQuiz(Quiz quiz) async {
    await _db.collection('quizzes').add(quiz.toMap());
  }

  Stream<List<Quiz>> getQuizzesStream() {
    return _db
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Quiz.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> submitQuizResult(QuizResult result) async {
    await _db.collection('quiz_results').add(result.toMap());
  }

  Stream<List<QuizResult>> getResultsForQuiz(String quizId) {
    return _db
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => QuizResult.fromMap(doc.data())).toList());
  }

  // ---------- الرسائل / الشات الخاص ----------

  /// بيبني نفس chatId بغض النظر عن ترتيب الأطراف
  static String buildChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> sendMessage(AnnouncementMessage message) async {
    await _db.collection('messages').add(message.toMap());
  }

  /// رسائل شات خاص بين معلم وطالب واحد بس
  Stream<List<AnnouncementMessage>> getMessagesStream(String chatId) {
    return _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> deleteMessage(String id) async {
    await _db.collection('messages').doc(id).delete();
  }

  // ---------- قائمة الطلاب (للمعلم) ----------

  Stream<List<AppUser>> getStudentsStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromMap(doc.data())).toList());
  }
}


