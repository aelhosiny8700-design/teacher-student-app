import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_model.dart';
import '../models/quiz_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // ============================================================
  // المحتوى
  // ============================================================

  Future<void> addContent(ContentItem item) async {
    await _db.collection('content').add(item.toMap());
  }

  Stream<List<ContentItem>> getContentStream() {
    return _db
        .collection('content')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ContentItem.fromMap(
                      doc.id,
                      doc.data(),
                    ),
              )
              .toList(),
        );
  }

  Stream<List<ContentItem>> getContentStreamByStage(
    String stage,
  ) {
    return _db
        .collection('content')
        .where('stage', isEqualTo: stage)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ContentItem.fromMap(
                      doc.id,
                      doc.data(),
                    ),
              )
              .toList(),
        );
  }

  Future<void> deleteContent(String id) async {
    await _db.collection('content').doc(id).delete();
  }

  // ============================================================
  // الاختبارات
  // ============================================================

  Future<void> addQuiz(Quiz quiz) async {
    await _db.collection('quizzes').add(quiz.toMap());
  }

  Stream<List<Quiz>> getQuizzesStream() {
    return _db
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Quiz.fromMap(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> submitQuizResult(
    QuizResult result,
  ) async {
    await _db
        .collection('quiz_results')
        .add(result.toMap());
  }

  Stream<List<QuizResult>> getResultsForQuiz(
    String quizId,
  ) {
    return _db
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    QuizResult.fromMap(
                      doc.data(),
                    ),
              )
              .toList(),
        );
  }

  // ============================================================
  // الشات
  // ============================================================

  static String buildPrivateChatId(
    String uid1,
    String uid2,
  ) {
    final ids = [uid1, uid2]..sort();

    return 'private_${ids[0]}_${ids[1]}';
  }

  static String buildClassChatId(
    String classId,
  ) {
    return 'class_$classId';
  }

  Future<void> sendMessage(
    AnnouncementMessage message,
  ) async {
    await _db
        .collection('messages')
        .add(message.toMap());
  }

  // ------------------------------------------------------------
  // الشات العام للمرحلة
  // ------------------------------------------------------------

  Stream<List<AnnouncementMessage>>
      getClassMessagesStream(String classId) {
    final chatId = buildClassChatId(classId);

    return _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AnnouncementMessage.fromMap(
                      doc.id,
                      doc.data(),
                    ),
              )
              .toList(),
        );
  }

  Future<void> sendClassMessage({
    required String classId,
    required String text,
    required String senderId,
    required String senderName,
  }) async {
    final message = AnnouncementMessage(
      id: '',
      chatId: buildClassChatId(classId),
      text: text,
      senderName: senderName,
      senderId: senderId,
      isAnnouncement: true,
      classId: classId,
      createdAt: DateTime.now(),
    );

    await sendMessage(message);
  }

  // ------------------------------------------------------------
  // الشات الخاص
  // ------------------------------------------------------------

  Stream<List<AnnouncementMessage>>
      getPrivateMessagesStream(
    String currentUid,
    String otherUid,
  ) {
    final chatId = buildPrivateChatId(
      currentUid,
      otherUid,
    );

    return _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AnnouncementMessage.fromMap(
                      doc.id,
                      doc.data(),
                    ),
              )
              .toList(),
        );
  }

  Future<void> sendPrivateMessage({
    required String currentUid,
    required String otherUid,
    required String senderName,
    required String text,
  }) async {
    final message = AnnouncementMessage(
      id: '',
      chatId: buildPrivateChatId(
        currentUid,
        otherUid,
      ),
      text: text,
      senderName: senderName,
      senderId: currentUid,
      isAnnouncement: false,
      classId: null,
      createdAt: DateTime.now(),
    );

    await sendMessage(message);
  }

  Future<void> deleteMessage(String id) async {
    await _db
        .collection('messages')
        .doc(id)
        .delete();
  }

  // ============================================================
  // الطلاب
  // ============================================================

  Stream<List<AppUser>> getStudentsStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AppUser.fromMap(
                      doc.data(),
                    ),
              )
              .toList(),
        );
  }

  Stream<List<AppUser>> getStudentsByClass(
    String classId,
  ) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    AppUser.fromMap(
                      doc.data(),
                    ),
              )
              .toList(),
        );
  }
}
