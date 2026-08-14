import 'package:flutter/material.dart';

class QuizPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> quizData;
  final String quizId;

  const QuizPreviewScreen({
    super.key,
    required this.quizData,
    required this.quizId,
  });

  @override
  Widget build(BuildContext context) {
    final title = quizData['title'] ?? 'بدون عنوان';
    final subject = quizData['subject'] ?? 'بدون مادة';
    final stage = quizData['stage'] ?? 'بدون مرحلة';
    final duration = quizData['durationMinutes'] ?? 30;
    final questions = (quizData['questions'] as List?) ?? [];

    int totalPoints = 0;
    for (var q in questions) {
      totalPoints += (q['points'] as num?)?.toInt() ?? 1;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text('معاينة: $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF0062E6),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة تفاصيل الاختبار الكلية
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(label: 'المادة: $subject', color: const Color(0xFF0062E6)),
                      _Chip(label: 'الصف: $stage', color: const Color(0xFF059669)),
                      _Chip(label: 'المدة: $duration دقيقة', color: const Color(0xFFD97706)),
                      _Chip(label: 'الدرجة الكلية: $totalPoints', color: const Color(0xFF7C3AED)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('أسئلة الاختبار (${questions.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),

            if (questions.isEmpty)
              const Center(child: Text('لا توجد أسئلة مضافة في هذا الاختبار', style: TextStyle(color: Colors.grey)))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final qText = q['questionText'] ?? '';
                  final type = q['type'] ?? 'mcq';
                  final points = q['points'] ?? 1;
                  final correctAns = q['correctAnswer'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'س${index + 1}: $qText',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0062E6).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('$points درجات', style: const TextStyle(color: Color(0xFF0062E6), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('نوع السؤال: ${_getTypeLabel(type)}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const Divider(height: 20),

                        if (type == 'mcq') ...[
                          ...List.generate((q['options'] as List? ?? []).length, (optIdx) {
                            final optText = q['options'][optIdx];
                            final isCorrect = correctAns == optIdx;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isCorrect ? const Color(0xFF059669).withOpacity(0.1) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCorrect ? const Color(0xFF059669) : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isCorrect ? const Color(0xFF059669) : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      optText,
                                      style: TextStyle(
                                        color: isCorrect ? const Color(0xFF059669) : const Color(0xFF1E293B),
                                        fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (isCorrect)
                                    const Text('الإجابة الصحيحة ✓', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }),
                        ] else if (type == 'true_false') ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF059669)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'الإجابة النموذجية: ${correctAns == true ? "صواب (صح)" : "خطأ"}',
                                  style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF059669)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'الإجابة النموذجية: ${correctAns ?? "لا يوجد"}',
                                    style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'mcq': return 'اختيار من متعدد';
      case 'true_false': return 'صح أم خطأ';
      case 'complete': return 'أكمل العبارات';
      case 'essay': return 'سؤال مقالي';
      default: return type;
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
