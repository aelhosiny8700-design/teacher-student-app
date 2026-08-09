import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/quiz_model.dart';
import '../services/firestore_service.dart';

class QuizTakeScreen extends StatefulWidget {
  final Quiz quiz;
  final AppUser user;
  const QuizTakeScreen({super.key, required this.quiz, required this.user});

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen> {
  late List<int?> _answers;
  bool _submitted = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.quiz.questions.length, null);
  }

  Future<void> _submit() async {
    if (_answers.contains(null)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('جاوب على كل الأسئلة الأول')));
      return;
    }

    int score = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_answers[i] == widget.quiz.questions[i].correctIndex) score++;
    }

    await FirestoreService().submitQuizResult(QuizResult(
      studentId: widget.user.uid,
      studentName: widget.user.name,
      quizId: widget.quiz.id,
      score: score,
      total: widget.quiz.questions.length,
      submittedAt: DateTime.now(),
    ));

    setState(() {
      _submitted = true;
      _score = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: const Color(0xFF2E5AAC),
        foregroundColor: Colors.white,
      ),
      body: _submitted ? _buildResult() : _buildQuiz(),
    );
  }

  Widget _buildResult() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 72),
          const SizedBox(height: 16),
          Text(
            'نتيجتك: $_score من ${widget.quiz.questions.length}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رجوع'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (int i = 0; i < widget.quiz.questions.length; i++)
          _buildQuestionCard(i),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF2E5AAC),
          ),
          child: const Text('تسليم الإجابات',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index) {
    final q = widget.quiz.questions[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${index + 1}. ${q.question}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            for (int j = 0; j < q.options.length; j++)
              RadioListTile<int>(
                title: Text(q.options[j]),
                value: j,
                groupValue: _answers[index],
                onChanged: (v) => setState(() => _answers[index] = v),
              ),
          ],
        ),
      ),
    );
  }
}
