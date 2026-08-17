import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';

class QuizResultsScreen extends StatefulWidget {
  final AppUser user;

  const QuizResultsScreen({super.key, required this.user});

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  String _selectedStageFilter = 'الكل';
  final ScreenshotController _screenshotController = ScreenshotController();

  final List<String> _stages = [
    'الكل',
    'الصف الأول الابتدائي', 'الصف الثاني الابتدائي', 'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي', 'الصف الخامس الابتدائي', 'الصف السادس الابتدائي',
    'الصف الأول الإعدادي', 'الصف الثاني الإعدادي', 'الصف الثالث الإعدادي',
    'الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي',
  ];

  void _openWhatsApp(String phone, String studentName, String quizTitle, int score, int maxScore) async {
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم ولي الأمر غير مسجل لهذا الطالب')),
      );
      return;
    }

    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '20${formattedPhone.substring(1)}';
    }

    final double percentage = maxScore > 0 ? (score / maxScore) * 100 : 0;

    final String message = Uri.encodeComponent(
      'السلام عليكم، ولي أمر الطالب/ة ($studentName) 🌟\n\n'
      'تقرير نتيجة اختبار: $quizTitle\n'
      'الدرجة الحاصل عليها: $score من $maxScore بنسبة (${percentage.toStringAsFixed(0)}%)\n\n'
      'نتمنى له/لها دوام التوفيق والنجاح! 📚'
    );

    final Uri url = Uri.parse('https://wa.me/$formattedPhone?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق الواتساب')),
        );
      }
    }
  }

  // التقاط الشهادة كصورة ومشاركتها عبر الواتساب أو التطبيقات الأخرى
  void _shareCertificateAsImage(String studentName, String quizTitle, int score, int maxScore) async {
    try {
      // التقاط الويدجت كصورة بايتات
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) return;

      // حفظها في مسار مؤقت على الجهاز
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/certificate_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await imagePath.writeAsBytes(imageBytes);

      final double percentage = maxScore > 0 ? (score / maxScore) * 100 : 0;

      // مشاركة الصورة مع رسالة نصية ترحيبية
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'السلام عليكم، ولي أمر الطالب/ة ($studentName) 🌟\n\n'
            'يسر منصة يَفهم التعليمية إعلامكم بحصول ابنكم/ابنتكم على شهادة تقدير وتفوق لتفوقه في اختبار: $quizTitle\n'
            'الدرجة الحاصل عليها: $score من $maxScore بنسبة (${percentage.toStringAsFixed(0)}%)\n\n'
            'مستر / أحمد فكري (مدرس العلوم والفيزياء)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء مشاركة الشهادة: $e')),
        );
      }
    }
  }

  // دالة عرض شهادة التقدير المبهرة مع إمكانية التقاطها كصورة
  void _showCertificateDialog(String studentName, String quizTitle, int score, int maxScore) {
    final double percentage = maxScore > 0 ? (score / maxScore) * 100 : 0;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // تغليف تصميم الشهادة بـ ScreenshotController لالتقاطها بدقة
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium, size: 54, color: Color(0xFFD4AF37)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "منصة يَفهم التعليمية",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "شهادة تقدير وتفوق", 
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFD4AF37), thickness: 1.5, indent: 40, endIndent: 40),
                        const SizedBox(height: 12),
                        const Text(
                          "تُمنح هذه الشهادة بكل فخر واعتزاز للطالب(ة) المتميز(ة):", 
                          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0062E6).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF0062E6).withOpacity(0.3)),
                          ),
                          child: Text(
                            studentName, 
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0062E6)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "توقيعاً على تميزه وتفوقه الساطع بحصوله على درجة ($score/$maxScore) بنسبة (${percentage.toStringAsFixed(0)}%)\nفي اختبار: ($quizTitle)", 
                          style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("إشراف وإعداد", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                const SizedBox(height: 2),
                                const Text(
                                  "مستر / أحمد فكري", 
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const Text("مدرس العلوم والفيزياء", style: TextStyle(fontSize: 11, color: Color(0xFF0062E6))),
                              ],
                            ),
                            const Icon(Icons.verified, color: Color(0xFF25D366), size: 36),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // زر مشاركة صورة الشهادة
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _shareCertificateAsImage(studentName, quizTitle, score, maxScore);
                    },
                    icon: const Icon(Icons.share, color: Colors.white, size: 20),
                    label: const Text('مشاركتها كصورة (واتساب / أخرى)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("إغلاق النافذة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('رصد نتائج الطلاب', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text('فلترة حسب الصف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStageFilter,
                        isExpanded: true,
                        items: _stages.map((stage) {
                          return DropdownMenuItem(
                            value: stage,
                            child: Text(stage, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStageFilter = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('quiz_results')
                  .where('teacherUid', isEqualTo: widget.user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0062E6)));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ أثناء تحميل النتائج: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((doc) {
                  if (_selectedStageFilter == 'الكل') return true;
                  final data = doc.data() as Map<String, dynamic>;
                  return data['stage'] == _selectedStageFilter;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('لا توجد نتائج اختبارات مسجلة لهذه الفئة حتى الآن', style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  );
                }

                filteredDocs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    final studentName = data['studentName'] ?? 'طالب';
                    final quizTitle = data['quizTitle'] ?? 'اختبار';
                    final score = data['score'] ?? 0;
                    final maxScore = data['maxScore'] ?? 1;
                    final stage = data['stage'] ?? 'غير محدد';
                    final parentPhone = data['parentPhone'] ?? '';

                    final double percentage = maxScore > 0 ? (score / maxScore) * 100 : 0;
                    final Color statusColor = percentage >= 50 ? const Color(0xFF059669) : const Color(0xFFDC2626);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: const Color(0xFF0062E6).withOpacity(0.12),
                                    child: const Icon(Icons.person, color: Color(0xFF0062E6), size: 22),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                                      Text(stage, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$score / $maxScore (${percentage.toStringAsFixed(0)}%)',
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.quiz_outlined, size: 18, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(quizTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                                ],
                              ),
                              Row(
                                children: [
                                  if (percentage >= 85) ...[
                                    ElevatedButton.icon(
                                      onPressed: () => _showCertificateDialog(studentName, quizTitle, score, maxScore),
                                      icon: const Icon(Icons.workspace_premium, size: 16, color: Colors.white),
                                      label: const Text('شهادة تقدير', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD4AF37),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (parentPhone.isNotEmpty)
                                    ElevatedButton.icon(
                                      onPressed: () => _openWhatsApp(parentPhone, studentName, quizTitle, score, maxScore),
                                      icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                                      label: const Text('مراسلة ولي الأمر', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF25D366),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
