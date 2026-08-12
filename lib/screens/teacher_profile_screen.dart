import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';

class TeacherProfileScreen extends StatefulWidget {
  final AppUser teacher;

  const TeacherProfileScreen({super.key, required this.teacher});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _service = FirestoreService();

  late String _code;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _code = widget.teacher.teacherCode ?? '—';
  }

  Future<void> _regenerateCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير الكود'),
        content: const Text(
          'الكود القديم هيتلغي فوراً ولن يقدر أي طالب جديد يستخدمه. الطلاب المقبولين بالفعل لن يتأثروا. متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      final newCode = await _service.regenerateTeacherCode(widget.teacher.uid);
      if (mounted) {
        setState(() {
          _code = newCode;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الكود')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كود الدعوة'),
        backgroundColor: const Color(0xFF2E5AAC),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'شارك الكود ده مع طلابك عشان يقدروا يسجلوا معاك',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E5AAC).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E5AAC).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    _code,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Color(0xFF2E5AAC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('نسخ الكود'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _regenerateCode,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('توليد كود جديد'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade800),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'لو حسيت إن الكود اتسرب، غيّره فوراً. الطلاب المقبولين بالفعل مش هيتأثروا.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
