import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/quiz_model.dart';
import '../services/firestore_service.dart';

class QuizCreateScreen extends StatefulWidget {
  final AppUser user;
  const QuizCreateScreen({super.key, required this.user});

  @override
  State<QuizCreateScreen> createState() => _QuizCreateScreenState();
}

class _QuizCreateScreenState extends State<QuizCreateScreen> {
  final _titleController = TextEditingController();
  final List<_QuestionForm> _questions = [_QuestionForm()];
  bool _saving = false;

  void _addQuestion() {
    setState(() => _questions.add(_QuestionForm()));
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('اكتب عنوان الاختبار');
      return;
    }
    final questionModels = <QuizQuestion>[];
    for (final q in _questions) {
      if (q.questionController.text.trim().isEmpty) {
        _showError('كل سؤال لازم يكون ليه نص');
        return;
      }
      final options = q.optionControllers.map((c) => c.text.trim()).toList();
      if (options.any((o) => o.isEmpty)) {
        _showError('كل الاختيارات لازم تتملى');
        return;
      }
      questionModels.add(QuizQuestion(
        question: q.questionController.text.trim(),
        options: options,
        correctIndex: q.correctIndex,
      ));
    }

    setState(() => _saving = true);

    final quiz = Quiz(
      id: '',
      title: _titleController.text.trim(),
      teacherId: widget.user.uid,
      questions: questionModels,
      createdAt: DateTime.now(),
    );

    await FirestoreService().addQuiz(quiz);

    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار جديد'),
        backgroundColor: const Color(0xFF2E5AAC),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان الاختبار',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < _questions.length; i++)
            _buildQuestionCard(i),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add),
            label: const Text('إضافة سؤال'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF2E5AAC),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('حفظ الاختبار', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final q = _questions[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('السؤال ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (_questions.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () => _removeQuestion(index),
                  ),
              ],
            ),
            TextField(
              controller: q.questionController,
              decoration: const InputDecoration(
                labelText: 'نص السؤال',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text('اختر الإجابة الصحيحة:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            for (int j = 0; j < 4; j++)
              Row(
                children: [
                  Radio<int>(
                    value: j,
                    groupValue: q.correctIndex,
                    onChanged: (v) => setState(() => q.correctIndex = v!),
                  ),
                  Expanded(
                    child: TextField(
                      controller: q.optionControllers[j],
                      decoration: InputDecoration(
                        labelText: 'اختيار ${j + 1}',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestionForm {
  final questionController = TextEditingController();
  final optionControllers = List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;
}
