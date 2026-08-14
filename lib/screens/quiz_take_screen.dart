import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  void _submitQuiz() async {
    int totalScore = 0;
    int maxScore = 0;

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
      await FirebaseFirestore.instance.collection('quiz_results').add({
        'quizId': widget.quizId,
        'quizTitle': widget.quizTitle,
        'studentUid': widget.studentUid,
        'score': totalScore,
        'maxScore': maxScore,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('تم تسليم الاختبار 🎉'),
            content: Text('حصلت على درجة: $totalScore من $maxScore'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('موافق'),
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
      appBar: AppBar(
        title: Text(widget.quizTitle),
        backgroundColor: const Color(0xFF0062E6),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.questions.length,
        itemBuilder: (context, i) {
          final q = widget.questions[i];
          final type = q['type'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('س${i + 1}: ${q['questionText']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),

                if (type == 'mcq') ...[
                  ...List.generate((q['options'] as List).length, (optIdx) {
                    return RadioListTile<int>(
                      title: Text(q['options'][optIdx]),
                      value: optIdx,
                      groupValue: _studentAnswers[i],
                      onChanged: (val) => setState(() => _studentAnswers[i] = val),
                    );
                  }),
                ] else if (type == 'true_false') ...[
                  RadioListTile<bool>(
                    title: const Text('صواب (صح)'), value: true,
                    groupValue: _studentAnswers[i], onChanged: (val) => setState(() => _studentAnswers[i] = val),
                  ),
                  RadioListTile<bool>(
                    title: const Text('خطأ'), value: false,
                    groupValue: _studentAnswers[i], onChanged: (val) => setState(() => _studentAnswers[i] = val),
                  ),
                ] else ...[
                  TextField(
                    onChanged: (val) => _studentAnswers[i] = val,
                    decoration: const InputDecoration(hintText: 'اكتب إجابتك هنا...', border: OutlineInputBorder()),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitQuiz,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0062E6), minimumSize: const Size.fromHeight(50)),
          child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('تسليم الإجابات', style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
    );
  }
}
