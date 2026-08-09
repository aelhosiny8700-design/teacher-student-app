import 'package:cloud_firestore/cloud_firestore.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final String teacherId;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.teacherId,
    required this.questions,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'teacherId': teacherId,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Quiz.fromMap(String id, Map<String, dynamic> map) {
    return Quiz(
      id: id,
      title: map['title'] ?? '',
      teacherId: map['teacherId'] ?? '',
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class QuizResult {
  final String studentId;
  final String studentName;
  final String quizId;
  final int score;
  final int total;
  final DateTime submittedAt;

  QuizResult({
    required this.studentId,
    required this.studentName,
    required this.quizId,
    required this.score,
    required this.total,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'quizId': quizId,
      'score': score,
      'total': total,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      quizId: map['quizId'] ?? '',
      score: map['score'] ?? 0,
      total: map['total'] ?? 0,
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
