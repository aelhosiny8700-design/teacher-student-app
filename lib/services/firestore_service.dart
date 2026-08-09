import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart';
import '../models/quiz_model.dart';
import '../models/message_model.dart';

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

  Future<void> deleteContent(String id) async {
    await _db.collection('content').doc(id).delete();
  }

  // ---------- الاختبارات ----------

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

  // ---------- الرسائل / الشات / التنبيهات العامة ----------

  Future<void> sendMessage(AnnouncementMessage message) async {
    await _db.collection('messages').add(message.toMap());
  }

  Stream<List<AnnouncementMessage>> getMessagesStream() {
    return _db
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementMessage.fromMap(doc.id, doc.data()))
            .toList());
  }
}
