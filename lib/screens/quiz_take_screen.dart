import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QuizTakeScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final String studentUid;
  final List questions;

  const QuizTakeScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.studentUid,
    required this.questions,
  });

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen> {
  final Map<int, dynamic> _studentAnswers = {};
  bool _isSubmitting = false;

  // دالة إرسال النتيجة لولي الأمر على الواتساب
  Future<void> _sendWhatsAppToParent({
    required String parentPhone,
    required String studentName,
    required int score,
    required int maxScore,
  }) async {
    if (parentPhone.trim().isEmpty) return;

    // تحويل رقم الموبايل للصيغة الدولية (مصر +20)
    String formattedPhone = parentPhone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '20${formattedPhone.substring(1)}';
    }

    final double percentage = maxScore > 0 ? (score / maxScore) * 100 : 0;

    final String message = Uri.encodeComponent(
      'السلام عليكم، ولي أمر الطالب/ة ($studentName) 🌟\n\n'
      'تم الانتهاء من أداء اختبار: ${widget.quizTitle}\n'
      'الدرجة الحاصل عليها: $score من $maxScore (${percentage.toStringAsFixed(0)}%)\n\n'
      'نتمنى له/لها دوام التوفيق والنجاح! 📚'
    );

    final Uri whatsappUri = Uri.parse('https://wa.me/$formattedPhone?text=$message');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('تعذر فتح الواتساب: $e');
    }
  }

  void _submitQuiz() async {
    int totalScore = 0;
    int maxScore = 0;

    // حساب الدرجات لكل سؤال بناءً على النقاط المحددة
    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final points = (q['points'] as num?)?.toInt() ?? 1;
      maxScore += points;

      final studentAns = _studentAnswers[i];
      final correctAns = q['correctAnswer'];

      if (q['type'] == 'mcq' || q['type'] == 'true_false') {
        if (studentAns == correctAns) {
          totalScore += points;
        }
      } else if (q['type'] == 'complete') {
        if (studentAns.toString().trim().toLowerCase() == correctAns.toString().trim().toLowerCase()) {
          totalScore += points;
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. جلب بيانات الطالب للحصول على اسمه ورقم ولي أمره
      final studentDoc = await FirebaseFirestore.instance.collection('users').doc(widget.studentUid).get();
      final studentData = studentDoc.data() ?? {};
      final String studentName = studentData['name'] ?? 'الطالب';
      final String parentPhone = studentData['parentPhone'] ?? '';

      // 2. حفظ النتيجة في Firebase
      await FirebaseFirestore.instance.collection('quiz_results').add({
        'quizId': widget.quizId,
        'quizTitle': widget.quizTitle,
        'studentUid': widget.studentUid,
        'studentName': studentName,
        'score': totalScore,
        'maxScore': maxScore,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('تم تسليم الاختبار 🎉', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'حصلت على درجة:\n$totalScore من $maxScore',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0062E6)),
                ),
                const SizedBox(height: 16),
                if (parentPhone.isNotEmpty)
                  const Text(
                    'سيتم فتح تطبيق الواتساب الآن لإرسال كشف النتيجة لولي الأمر.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  Navigator.pop(context);

                  // فتح الواتساب لإرسال التقرير لولي الأمر
                  if (parentPhone.isNotEmpty) {
                    await _sendWhatsAppToParent(
                      parentPhone: parentPhone,
                      studentName: studentName,
                      score: totalScore,
                      maxScore: maxScore,
                    );
                  }
                },
                child: const Text('موافق وإرسال النتيجة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء التسليم: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(widget.quizTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0062E6),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.questions.length,
        itemBuilder: (context, i) {
          final q = widget.questions[i];
          final type = q['type'];
          final points = q['points'] ?? 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
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
                        'س${i + 1}: ${q['questionText']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0062E6).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$points درجة',
                        style: const TextStyle(color: Color(0xFF0062E6), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (type == 'mcq') ...[
                  ...List.generate((q['options'] as List).length, (optIdx) {
                    return RadioListTile<int>(
                      title: Text(q['options'][optIdx]),
                      value: optIdx,
                      groupValue: _studentAnswers[i],
                      activeColor: const Color(0xFF0062E6),
                      onChanged: (val) => setState(() => _studentAnswers[i] = val),
                    );
                  }),
                ] else if (type == 'true_false') ...[
                  RadioListTile<bool>(
                    title: const Text('صواب (صح)'),
                    value: true,
                    groupValue: _studentAnswers[i],
                    activeColor: const Color(0xFF0062E6),
                    onChanged: (val) => setState(() => _studentAnswers[i] = val),
                  ),
                  RadioListTile<bool>(
                    title: const Text('خطأ'),
                    value: false,
                    groupValue: _studentAnswers[i],
                    activeColor: const Color(0xFF0062E6),
                    onChanged: (val) => setState(() => _studentAnswers[i] = val),
                  ),
                ] else ...[
                  TextField(
                    onChanged: (val) => _studentAnswers[i] = val,
                    decoration: InputDecoration(
                      hintText: 'اكتب إجابتك هنا...',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0062E6),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('تسليم الاختبار وحفظ النتيجة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
