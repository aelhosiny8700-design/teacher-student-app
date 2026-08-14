import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class QuizCreateScreen extends StatefulWidget {
  final AppUser user;

  const QuizCreateScreen({super.key, required this.user});

  @override
  State<QuizCreateScreen> createState() => _QuizCreateScreenState();
}

class _QuizCreateScreenState extends State<QuizCreateScreen> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _durationController = TextEditingController(text: '30');

  String _selectedStage = 'الصف الأول الإعدادي';
  bool _isLoading = false;

  final List<String> _stages = [
    'الصف الأول الابتدائي', 'الصف الثاني الابتدائي', 'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي', 'الصف الخامس الابتدائي', 'الصف السادس الابتدائي',
    'الصف الأول الإعدادي', 'الصف الثاني الإعدادي', 'الصف الثالث الإعدادي',
    'الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي',
  ];

  final List<Map<String, dynamic>> _questions = [];

  void _addQuestionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddQuestionBottomSheet(
        onQuestionAdded: (questionMap) {
          setState(() {
            _questions.add(questionMap);
          });
        },
      ),
    );
  }

  Future<void> _saveQuiz() async {
    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 30;

    if (title.isEmpty || subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك ادخل عنوان الاختبار والمادة')),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أضف سؤالاً واحداً على الأقل')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('quizzes').add({
        'title': title,
        'subject': subject,
        'stage': _selectedStage,
        'durationMinutes': duration,
        'teacherUid': widget.user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'questions': _questions,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر الاختبار بنجاح 🎉'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('إنشاء اختبار جديد', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('بيانات الاختبار الأساسية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: _inputDecoration('عنوان الاختبار (مثال: اختبار شهر أكتوبر)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    decoration: _inputDecoration('اسم المادة (مثال: العلوم / الفيزياء)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedStage,
                    decoration: _inputDecoration('الصف الدراسي'),
                    items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedStage = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('مدة الاختبار بالدقائق'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الأسئلة المضافة (${_questions.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _addQuestionModal,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة سؤال'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0062E6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_questions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(
                  child: Text('لم تقم بإضافة أسئلة حتى الآن. اضغط على "إضافة سؤال"', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      title: Text('س${index + 1}: ${q['questionText']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('النوع: ${_getQuestionTypeLabel(q['type'])} • الدرجة: ${q['points']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() => _questions.removeAt(index));
                        },
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0062E6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('نشر الاختبار للطلاب', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'mcq': return 'اختيار من متعدد';
      case 'true_false': return 'صح أم خطأ';
      case 'complete': return 'أكمل';
      case 'essay': return 'مقالي';
      default: return type;
    }
  }
}

class _AddQuestionBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onQuestionAdded;

  const _AddQuestionBottomSheet({required this.onQuestionAdded});

  @override
  State<_AddQuestionBottomSheet> createState() => _AddQuestionBottomSheetState();
}

class _AddQuestionBottomSheetState extends State<_AddQuestionBottomSheet> {
  String _type = 'mcq';
  final _questionTextController = TextEditingController();
  final _pointsController = TextEditingController(text: '1');

  final _opt1 = TextEditingController();
  final _opt2 = TextEditingController();
  final _opt3 = TextEditingController();
  final _opt4 = TextEditingController();
  int _correctMcqIndex = 0;

  bool _isTrueCorrect = true;
  final _correctAnswerController = TextEditingController();

  void _submit() {
    final text = _questionTextController.text.trim();
    if (text.isEmpty) return;

    Map<String, dynamic> qMap = {
      'questionText': text,
      'type': _type,
      'points': int.tryParse(_pointsController.text) ?? 1,
    };

    if (_type == 'mcq') {
      qMap['options'] = [_opt1.text.trim(), _opt2.text.trim(), _opt3.text.trim(), _opt4.text.trim()];
      qMap['correctAnswer'] = _correctMcqIndex;
    } else if (_type == 'true_false') {
      qMap['correctAnswer'] = _isTrueCorrect;
    } else {
      qMap['correctAnswer'] = _correctAnswerController.text.trim();
    }

    widget.onQuestionAdded(qMap);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20, left: 20, right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إضافة سؤال جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'نوع السؤال'),
              items: const [
                DropdownMenuItem(value: 'mcq', child: Text('اختيار من متعدد')),
                DropdownMenuItem(value: 'true_false', child: Text('صح أم خطأ')),
                DropdownMenuItem(value: 'complete', child: Text('أكمل العبارات')),
                DropdownMenuItem(value: 'essay', child: Text('سؤال مقالي')),
              ],
              onChanged: (val) => setState(() => _type = val!),
            ),
            const SizedBox(height: 10),
            TextField(controller: _questionTextController, decoration: const InputDecoration(labelText: 'نص السؤال')),
            const SizedBox(height: 10),
            TextField(controller: _pointsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الدرجة')),
            const SizedBox(height: 14),

            if (_type == 'mcq') ...[
              TextField(controller: _opt1, decoration: const InputDecoration(labelText: 'الخيار الأول')),
              TextField(controller: _opt2, decoration: const InputDecoration(labelText: 'الخيار الثاني')),
              TextField(controller: _opt3, decoration: const InputDecoration(labelText: 'الخيار الثالث')),
              TextField(controller: _opt4, decoration: const InputDecoration(labelText: 'الخيار الرابع')),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _correctMcqIndex,
                decoration: const InputDecoration(labelText: 'الإجابة الصحيحة هي'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('الخيار الأول')),
                  DropdownMenuItem(value: 1, child: Text('الخيار الثاني')),
                  DropdownMenuItem(value: 2, child: Text('الخيار الثالث')),
                  DropdownMenuItem(value: 3, child: Text('الخيار الرابع')),
                ],
                onChanged: (val) => setState(() => _correctMcqIndex = val!),
              ),
            ] else if (_type == 'true_false') ...[
              SwitchListTile(
                title: Text(_isTrueCorrect ? 'الإجابة الصحيحة: صواب (صح)' : 'الإجابة الصحيحة: خطأ'),
                value: _isTrueCorrect,
                onChanged: (val) => setState(() => _isTrueCorrect = val),
              ),
            ] else ...[
              TextField(controller: _correctAnswerController, decoration: const InputDecoration(labelText: 'الإجابة النموذجية / الكلمة الصحيحة')),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0062E6)),
                child: const Text('حفظ السؤال', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
