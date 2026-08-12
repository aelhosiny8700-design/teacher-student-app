import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/content_model.dart';
import '../models/quiz_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // =========================================================
  // المراحل الدراسية
  // =========================================================

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

  static String stageKey(String stage) {
    switch (stage) {
      case 'أولى ابتدائي':
        return 'primary_1';

      case 'ثانية ابتدائي':
        return 'primary_2';

      case 'ثالثة ابتدائي':
        return 'primary_3';

      case 'رابعة ابتدائي':
        return 'primary_4';

      case 'خامسة ابتدائي':
        return 'primary_5';

      case 'سادسة ابتدائي':
        return 'primary_6';

      case 'أولى إعدادي':
        return 'prep_1';

      case 'ثانية إعدادي':
        return 'prep_2';

      case 'ثالثة إعدادي':
        return 'prep_3';

      case 'أولى ثانوي':
        return 'secondary_1';

      case 'ثانية ثانوي':
        return 'secondary_2';

      case 'ثالثة ثانوي':
        return 'secondary_3';

      default:
        return 'unknown';
    }
  }

  // =========================================================
  // المحتوى
  // =========================================================

  Future<void> addContent(ContentItem item) async {
    await _db
        .collection('content')
        .add(item.toMap());
  }

  Stream<List<ContentItem>> getContentStream() {
    return _db
        .collection('content')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) =>
                ContentItem.fromMap(doc.id, doc.data()),
          )
          .toList();

      list.sort((a, b) {
        return b.createdAt.compareTo(a.createdAt);
      });

      return list;
    });
  }

  Stream<List<ContentItem>> getContentStreamByStage(
    String stage,
  ) {
    return _db
        .collection('content')
        .where('stage', isEqualTo: stage)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) =>
                ContentItem.fromMap(doc.id, doc.data()),
          )
          .toList();

      list.sort((a, b) {
        return b.createdAt.compareTo(a.createdAt);
      });

      return list;
    });
  }

  Future<void> deleteContent(String id) async {
    await _db
        .collection('content')
        .doc(id)
        .delete();
  }

  // =========================================================
  // الاختبارات
  // =========================================================

  Future<void> addQuiz(Quiz quiz) async {
    await _db
        .collection('quizzes')
        .add(quiz.toMap());
  }

  Stream<List<Quiz>> getQuizzesStream() {
    return _db
        .collection('quizzes')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) => Quiz.fromMap(
              doc.id,
              doc.data(),
            ),
          )
          .toList();

      return list;
    });
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
        .where(
          'quizId',
          isEqualTo: quizId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    QuizResult.fromMap(doc.data()),
              )
              .toList(),
        );
  }

  // =========================================================
  // الشات
  // =========================================================

  static String buildPrivateChatId(
    String uid1,
    String uid2,
  ) {
    final ids = [uid1, uid2]..sort();

    return 'private_${ids[0]}_${ids[1]}';
  }

  static String buildGeneralChatId(
    String stage,
  ) {
    return 'general_${stageKey(stage)}';
  }

  Future<void> sendMessage(
    AnnouncementMessage message,
  ) async {
    await _db
        .collection('messages')
        .add(message.toMap());
  }

  Stream<List<AnnouncementMessage>>
      getMessagesStream(String chatId) {
    return _db
        .collection('messages')
        .where(
          'chatId',
          isEqualTo: chatId,
        )
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) =>
                AnnouncementMessage.fromMap(
              doc.id,
              doc.data(),
            ),
          )
          .toList();

      list.sort((a, b) {
        return a.createdAt.compareTo(
          b.createdAt,
        );
      });

      return list;
    });
  }

  Future<void> deleteMessage(
    String id,
  ) async {
    await _db
        .collection('messages')
        .doc(id)
        .delete();
  }

  // =========================================================
  // الطلاب
  // =========================================================

  Stream<List<AppUser>> getStudentsStream() {
    return _db
        .collection('users')
        .where(
          'role',
          isEqualTo: 'student',
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                AppUser.fromMap(doc.data()),
          )
          .toList();
    });
  }

  Stream<List<AppUser>> getStudentsByStage(
    String stage,
  ) {
    return _db
        .collection('users')
        .where(
          'role',
          isEqualTo: 'student',
        )
        .where(
          'stage',
          isEqualTo: stage,
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                AppUser.fromMap(doc.data()),
          )
          .toList();
    });
  }

  Stream<List<AppUser>> getTeachersStream() {
    return _db
        .collection('users')
        .where(
          'role',
          isEqualTo: 'teacher',
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                AppUser.fromMap(doc.data()),
          )
          .toList();
    });
  }
}
