import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/quiz_model.dart';
import '../services/firestore_service.dart';
import 'quiz_take_screen.dart';
import 'quiz_results_screen.dart';

class QuizListScreen extends StatelessWidget {
  final AppUser user;
  const QuizListScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    final teacherUid = user.isTeacher ? user.uid : (user.linkedTeacherUid ?? '');

    if (teacherUid.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'لا يوجد معلم مرتبط بحسابك حاليًا.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      );
    }

    return StreamBuilder<List<Quiz>>(
      stream: service.getQuizzesStream(teacherUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final quizzes = snapshot.data ?? [];
        if (quizzes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'مفيش اختبارات لسه.',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3ECFA),
                  child: Icon(Icons.quiz, color: Color(0xFF2E5AAC)),
                ),
                title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${quiz.questions.length} سؤال'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (user.isTeacher) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizResultsScreen(quiz: quiz),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizTakeScreen(quiz: quiz, user: user),
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}


