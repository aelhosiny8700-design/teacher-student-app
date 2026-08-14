import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'quiz_take_screen.dart';

class QuizListScreen extends StatelessWidget {
  final AppUser user;

  const QuizListScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('الاختبارات والواجبات', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .where('teacherUid', isEqualTo: user.linkedTeacherUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0062E6)));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('لا يوجد اختبارات مضافة حالياً من المعلم'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final q = doc.data() as Map<String, dynamic>;
              final questions = (q['questions'] as List?) ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.quiz, color: Color(0xFF0062E6))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(q['title'] ?? 'اختبار', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${q['subject']} • ${q['durationMinutes']} دقيقة • ${questions.length} أسئلة', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0062E6)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizTakeScreen(
                              quizId: doc.id,
                              quizTitle: q['title'] ?? 'اختبار',
                              studentUid: user.uid,
                              questions: questions,
                            ),
                          ),
                        );
                      },
                      child: const Text('ابدأ الآن', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

