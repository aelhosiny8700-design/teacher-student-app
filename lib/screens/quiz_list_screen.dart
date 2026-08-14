import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'quiz_take_screen.dart';

class QuizListScreen extends StatelessWidget {
  final AppUser user;

  const QuizListScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // جلب أحدث بيانات الطالب لحظياً للتأكد من المعلم المربوط والصف
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        String? teacherUid = user.linkedTeacherUid;
        // دعم قراءة المرحلة سواء كانت مخزنة كـ grade أو stage
        String? studentGrade = user.stage;
        String? status = user.status;

        if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
          final rawUser = userSnapshot.data!.data();
          if (rawUser is Map) {
            teacherUid = rawUser['linkedTeacherUid']?.toString() ?? teacherUid;
            studentGrade = rawUser['grade']?.toString() ?? rawUser['stage']?.toString() ?? studentGrade;
            status = rawUser['status']?.toString() ?? status;
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FC),
          appBar: AppBar(
            title: Column(
              children: [
                const Text('الاختبارات والتقييمات 📝', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
                Text(studentGrade ?? 'الصف الدراسي', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: _buildQuizzesBody(context, teacherUid, studentGrade, status),
        );
      },
    );
  }

  Widget _buildQuizzesBody(BuildContext context, String? teacherUid, String? studentGrade, String? status) {
    if (teacherUid == null || teacherUid.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'لم تنضم إلى أي معلم بعد!\nيرجى كتابة كود المعلم في الرئيسية لرؤية الاختبارات.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
      );
    }

    if (status == 'pending') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'طلب انضمامك للمعلم قيد الانتظار ⏳\nستظهر الاختبارات فور قبول المعلم لطلبك.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ),
      );
    }

    // جلب جميع الاختبارات وتصفيتها برمجياً لتجنب مشاكل اختلاف أسماء الحقول (teacherId / teacherUid)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
      builder: (context, quizSnapshot) {
        if (quizSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0062E6)));
        }

        final quizDocs = quizSnapshot.data?.docs ?? [];

        // تصفية ذكية للاختبارات
        final filteredQuizzes = quizDocs.where((doc) {
          final raw = doc.data();
          if (raw is! Map) return false;
          final data = raw.cast<String, dynamic>();

          // 1. التحقق من المعلم (سواء مخزن بـ teacherId أو teacherUid)
          final tId = data['teacherId']?.toString();
          final tUid = data['teacherUid']?.toString();
          final bool isForThisTeacher = (tId == teacherUid || tUid == teacherUid);
          if (!isForThisTeacher) return false;

          // 2. التحقق من المرحلة (لو الاختبار ليس له مرحلة مسجلة، يظهر تلقائياً)
          final quizGrade = data['grade']?.toString() ?? data['stage']?.toString();
          if (quizGrade == null || quizGrade.isEmpty) {
            return true;
          }

          return (studentGrade == null || studentGrade.isEmpty) || (quizGrade == studentGrade);
        }).toList();

        if (filteredQuizzes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'لا توجد اختبارات مضافة لـ (${studentGrade ?? 'صفك'}) حالياً',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          );
        }

        // استعلام نتائج الطالب المكتملة
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('quiz_results')
              .where('studentUid', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, resultSnapshot) {
            final resultDocs = resultSnapshot.data?.docs ?? [];

            final Map<String, Map<String, dynamic>> completedQuizzes = {};
            for (final resDoc in resultDocs) {
              final rawRes = resDoc.data();
              if (rawRes is Map) {
                final rData = rawRes.cast<String, dynamic>();
                final qId = rData['quizId'];
                if (qId != null) {
                  completedQuizzes[qId.toString()] = rData;
                }
              }
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredQuizzes.length,
              itemBuilder: (context, index) {
                final doc = filteredQuizzes[index];
                final raw = doc.data();
                final Map<String, dynamic> q = (raw is Map) ? raw.cast<String, dynamic>() : {};
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
                              q['title']?.toString() ?? 'اختبار',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${q['subject'] ?? ''} • ${q['durationMinutes'] ?? 30} دقيقة • ${questions.length} أسئلة',
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
                                  quizTitle: q['title']?.toString() ?? 'اختبار',
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
    );
  }
}
