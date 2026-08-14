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
        title: Column(
          children: [
            const Text('الاختبارات والتقييمات', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
            Text(user.stage ?? 'الصف الدراسي', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .where('teacherUid', isEqualTo: user.linkedTeacherUid)
            .snapshots(),
        builder: (context, quizSnapshot) {
          if (quizSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0062E6)));
          }

          final quizDocs = quizSnapshot.data?.docs ?? [];

          // تصفية الاختبارات لتناسب صف الطالب بالضبط
          final filteredQuizzes = quizDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['stage'] == user.stage;
          }).toList();

          if (filteredQuizzes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'لا يوجد اختبارات مضافة لـ (${user.stage ?? 'صفك'}) حالياً',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // استعلام للتحقق من نتائج الطالب المكتملة
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('quiz_results')
                .where('studentUid', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, resultSnapshot) {
              final resultDocs = resultSnapshot.data?.docs ?? [];

              // تحويل النتائج لخرائط سريعة الوصول
              final Map<String, Map<String, dynamic>> completedQuizzes = {};
              for (final resDoc in resultDocs) {
                final rData = resDoc.data() as Map<String, dynamic>;
                final qId = rData['quizId'];
                if (qId != null) {
                  completedQuizzes[qId.toString()] = rData;
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredQuizzes.length,
                itemBuilder: (context, index) {
                  final doc = filteredQuizzes[index];
                  final q = doc.data() as Map<String, dynamic>;
                  final questions = (q['questions'] as List?) ?? [];
                  final quizId = doc.id;

                  final bool isCompleted = completedQuizzes.containsKey(quizId);
                  final resultData = completedQuizzes[quizId];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCompleted ? const Color(0xFF059669).withOpacity(0.12) : const Color(0xFF0062E6).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_circle : Icons.quiz,
                            color: isCompleted ? const Color(0xFF059669) : const Color(0xFF0062E6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                q['title'] ?? 'اختبار',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${q['subject']} • ${q['durationMinutes']} دقيقة • ${questions.length} أسئلة',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Text('مكتمل', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                                Text(
                                  '${resultData?['score']}/${resultData?['maxScore']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                              ],
                            ),
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0062E6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
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
                            child: const Text('ابدأ الآن', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
