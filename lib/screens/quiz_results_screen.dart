import 'package:flutter/material.dart';
import '../models/quiz_model.dart';
import '../services/firestore_service.dart';

class QuizResultsScreen extends StatelessWidget {
  final Quiz quiz;
  const QuizResultsScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text('نتائج: ${quiz.title}'),
        backgroundColor: const Color(0xFF2E5AAC),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<QuizResult>>(
        stream: service.getResultsForQuiz(quiz.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return const Center(
              child: Text('لسه محدش حل الاختبار', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final r = results[index];
              final percentage = (r.score / r.total * 100).round();
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: percentage >= 50
                        ? Colors.green.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: percentage >= 50 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  title: Text(r.studentName),
                  subtitle: Text('${r.score} من ${r.total}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
