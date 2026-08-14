import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'quiz_create_screen.dart';
import 'quiz_preview_screen.dart';
import 'quiz_results_screen.dart';
import 'pending_approvals_screen.dart';
import 'chat_hub_screen.dart';

class TeacherColors {
  static const primary = Color(0xFF0062E6);
  static const primaryDark = Color(0xFF004CB3);
  static const background = Color(0xFFF4F7FC);
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
}

class TeacherHome extends StatefulWidget {
  final AppUser user;

  const TeacherHome({super.key, required this.user});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _TeacherDashboardTab(
        user: widget.user,
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
        onOpenUploadModal: () => _showAddContentModal(context),
      ),
      _UploadedContentTab(user: widget.user, onOpenUploadModal: () => _showAddContentModal(context)),
      _TeacherQuizzesTab(user: widget.user),
      ChatHubScreen(user: widget.user),
      _TeacherProfileTab(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: TeacherColors.background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: TeacherColors.primary,
          unselectedItemColor: TeacherColors.textMuted,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'المحتوى'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'الاختبارات'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'الرسائل'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'المزيد'),
          ],
        ),
      ),
    );
  }

  void _showAddContentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _AddContentBottomSheet(teacherUid: widget.user.uid),
    );
  }
}

// ==========================================
// 1. شاشة الرئيسية للمعلم
// ==========================================
class _TeacherDashboardTab extends StatefulWidget {
  final AppUser user;
  final Function(int) onNavigateToTab;
  final VoidCallback onOpenUploadModal;

  const _TeacherDashboardTab({
    required this.user,
    required this.onNavigateToTab,
    required this.onOpenUploadModal,
  });

  @override
  State<_TeacherDashboardTab> createState() => _TeacherDashboardTabState();
}

class _TeacherDashboardTabState extends State<_TeacherDashboardTab> {
  bool _isGeneratingCode = false;

  Future<void> _generateTeacherCode() async {
    setState(() => _isGeneratingCode = true);
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    final newCode = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'teacherCode': newCode,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تغيير كود المعلم للجديد: $newCode 🎉'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء تجديد الكود: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingCode = false);
    }
  }

  void _confirmRegenerateCode() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تجديد كود المعلم', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل تريد تغيير كودك الحالي وتوليد كود جديد؟ (استخدم هذا إذا اتسرب كودك القديم).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TeacherColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              _generateTeacherCode();
            },
            child: const Text('توليد كود جديد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _copyCodeToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ كود المعلم إلى الحافظة 📋'), backgroundColor: TeacherColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // الهيدر
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [TeacherColors.primary, TeacherColors.primaryDark],
                begin: Alignment.topRight, end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white, size: 22),
                      onPressed: () async => await AuthService().signOut(),
                    ),
                    Row(
                      children: [
                        const Text('يَــفـهَــم', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.school, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
                  builder: (context, snapshot) {
                    String? currentCode = widget.user.teacherCode;
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                      final raw = snapshot.data!.data();
                      if (raw is Map) {
                        currentCode = raw['teacherCode']?.toString() ?? currentCode;
                      }
                    }

                    if (currentCode == null || currentCode.isEmpty) {
                      return ElevatedButton.icon(
                        onPressed: _isGeneratingCode ? null : _generateTeacherCode,
                        icon: const Icon(Icons.vpn_key, size: 18, color: TeacherColors.primary),
                        label: const Text('توليد كود المعلم الآن', style: TextStyle(fontWeight: FontWeight.bold, color: TeacherColors.primary)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _copyCodeToClipboard(currentCode!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.copy, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'كودك: $currentCode',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isGeneratingCode ? null : _confirmRegenerateCode,
                          icon: const Icon(Icons.refresh, size: 16, color: TeacherColors.primary),
                          label: const Text('تجديد الكود', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TeacherColors.primary)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),
                Text('أهلاً بك يا أستاذ/ة ${widget.user.name} 👋', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(widget.user.uid, widget.onNavigateToTab),
                const SizedBox(height: 24),
                const Text('الوصول السريع', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.25,
                  children: [
                    _QuickTile(
                      title: 'رفع محتوى دراسي',
                      icon: Icons.cloud_upload_rounded,
                      color: const Color(0xFF2563EB),
                      onTap: widget.onOpenUploadModal,
                    ),
                    _QuickTile(
                      title: 'اختبار جديد',
                      icon: Icons.add_task_rounded,
                      color: const Color(0xFF059669),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizCreateScreen(user: widget.user)));
                      },
                    ),
                    _QuickTile(
                      title: 'رصد النتائج',
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFFD97706),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizResultsScreen(user: widget.user)));
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('linkedTeacherUid', isEqualTo: widget.user.uid)
                          .snapshots(),
                      builder: (context, pendingSnap) {
                        int pendingCount = 0;
                        if (pendingSnap.hasData && pendingSnap.data != null) {
                          for (var doc in pendingSnap.data!.docs) {
                            final raw = doc.data();
                            if (raw is Map && raw['status'] == 'pending') {
                              pendingCount++;
                            }
                          }
                        }

                        return _QuickTile(
                          title: 'طلبات الانضمام',
                          icon: Icons.person_add_alt_1_rounded,
                          color: const Color(0xFFDC2626),
                          badgeCount: pendingCount > 0 ? '$pendingCount' : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PendingApprovalsScreen(teacher: widget.user)),
                            );
                          },
                        );
                      },
                    ),
                    _QuickTile(
                      title: 'إدارة الطلاب',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF7C3AED),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => _TeacherStudentsScreen(user: widget.user)));
                      },
                    ),
                    _QuickTile(
                      title: 'تجديد الكود (تسريب)',
                      icon: Icons.published_with_changes_rounded,
                      color: const Color(0xFF0284C7),
                      onTap: _confirmRegenerateCode,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String teacherUid, Function(int) onNavigateToTab) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('linkedTeacherUid', isEqualTo: teacherUid).snapshots(),
      builder: (context, studentSnap) {
        final studentsCount = (studentSnap.hasData && studentSnap.data != null) ? studentSnap.data!.docs.length : 0;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('quizzes').where('teacherUid', isEqualTo: teacherUid).snapshots(),
          builder: (context, quizSnap) {
            final quizCount = (quizSnap.hasData && quizSnap.data != null) ? quizSnap.data!.docs.length : 0;
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('contents').where('teacherUid', isEqualTo: teacherUid).snapshots(),
              builder: (context, contentSnap) {
                final contentCount = (contentSnap.hasData && contentSnap.data != null) ? contentSnap.data!.docs.length : 0;
                return Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => _TeacherStudentsScreen(user: widget.user)));
                        },
                        child: _StatCard(title: 'الطلاب', count: '$studentsCount', icon: Icons.people, color: const Color(0xFF2563EB)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onNavigateToTab(1),
                        child: _StatCard(title: 'المحتوى', count: '$contentCount', icon: Icons.folder, color: const Color(0xFFD97706)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onNavigateToTab(2),
                        child: _StatCard(title: 'الاختبارات', count: '$quizCount', icon: Icons.assignment, color: const Color(0xFF7C3AED)),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 2. شاشة إدارة الطلاب
// ==========================================
class _TeacherStudentsScreen extends StatelessWidget {
  final AppUser user;

  const _TeacherStudentsScreen({required this.user});

  void _confirmDeleteStudent(BuildContext context, String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إزالة طالب', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من إزالة الطالب ($studentName) من مجموعتك؟'),
              actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            Navigator.pop(ctx);
            
            DocumentSnapshot studentDoc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
            if (studentDoc.exists) {
              Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;

              await FirebaseFirestore.instance.collection('archived_students').doc(studentId).set(studentData);

              await FirebaseFirestore.instance.collection('users').doc(studentId).update({
                'linkedTeacherUid': FieldValue.delete(),
              });
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نقل الطالب للأرشيف بنجاح')),
              );
            }
          },
          child: const Text('إزالة الطالب', style: TextStyle(color: Colors.white)),
        ),
      ],


  void _openWhatsApp(String phone) async {
    if (phone.trim().isEmpty) return;
    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '20${formattedPhone.substring(1)}';
    }
    final Uri url = Uri.parse('https://wa.me/$formattedPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: const Text('قائمة الطلاب المضافين', style: TextStyle(color: TeacherColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: TeacherColors.textDark,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('linkedTeacherUid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: TeacherColors.primary));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('لا يوجد طلاب مربوطين بكودك حالياً', style: TextStyle(color: TeacherColors.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final raw = doc.data();
              final Map<String, dynamic> data = (raw is Map) ? raw.cast<String, dynamic>() : {};
              final name = data['name']?.toString() ?? 'طالب بدون اسم';
              final stage = data['stage']?.toString() ?? 'لم يحدد الصف';
              final parentPhone = data['parentPhone']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
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
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: TeacherColors.primary.withOpacity(0.12),
                      child: const Icon(Icons.person, color: TeacherColors.primary, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: TeacherColors.textDark)),
                          const SizedBox(height: 4),
                          Text(stage, style: const TextStyle(fontSize: 12, color: TeacherColors.textMuted)),
                          if (parentPhone.isNotEmpty)
                            Text('ولي الأمر: $parentPhone', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (parentPhone.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.green),
                        tooltip: 'مراسلة ولي الأمر',
                        onPressed: () => _openWhatsApp(parentPhone),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'حذف الطالب',
                      onPressed: () => _confirmDeleteStudent(context, doc.id, name),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 3. تبويب إدارة الاختبارات
// ==========================================
class _TeacherQuizzesTab extends StatelessWidget {
  final AppUser user;

  const _TeacherQuizzesTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: const Text('إدارة الاختبارات', style: TextStyle(color: TeacherColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => QuizCreateScreen(user: user)));
        },
        backgroundColor: TeacherColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('اختبار جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quizzes').where('teacherUid', isEqualTo: user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: TeacherColors.primary));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('لم تقم بنشر أي اختبارات حتى الآن', style: TextStyle(color: TeacherColors.textMuted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final raw = doc.data();
              final Map<String, dynamic> q = (raw is Map) ? raw.cast<String, dynamic>() : {};
              final questions = (q['questions'] as List?)?.length ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizPreviewScreen(quizData: q, quizId: doc.id),
                      ),
                    );
                  },
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.quiz, color: TeacherColors.primary)),
                  title: Text(q['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${q['subject']} • ${q['stage']} • $questions أسئلة'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, color: TeacherColors.primary),
                        tooltip: 'معاينة الاختبار',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizPreviewScreen(quizData: q, quizId: doc.id),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'حذف',
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('quizzes').doc(doc.id).delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 4. تبويب المحتوى المضاف
// ==========================================
class _UploadedContentTab extends StatelessWidget {
  final AppUser user;
  final VoidCallback onOpenUploadModal;

  const _UploadedContentTab({required this.user, required this.onOpenUploadModal});

  void _openContentUrl(BuildContext context, String urlString) async {
    if (urlString.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط الملف غير متوفر')),
      );
      return;
    }

    final Uri url = Uri.parse(urlString.trim());
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح رابط الملف أو الفيديو')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: const Text('المحتوى المضاف', style: TextStyle(color: TeacherColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onOpenUploadModal,
        backgroundColor: TeacherColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('رفع محتوى', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('contents').where('teacherUid', isEqualTo: user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: TeacherColors.primary));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('لم تقم برفع أي محتوى تعليمي حتى الآن', style: TextStyle(color: TeacherColors.textMuted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final raw = doc.data();
              final Map<String, dynamic> d = (raw is Map) ? raw.cast<String, dynamic>() : {};
              final fileUrl = d['fileUrl']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => _openContentUrl(context, fileUrl),
                  leading: const Icon(Icons.insert_drive_file, color: TeacherColors.primary),
                  title: Text(d['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${d['stage'] ?? ''} • ${d['type'] ?? ''}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new, color: TeacherColors.primary),
                        tooltip: 'فتح المحتوى',
                        onPressed: () => _openContentUrl(context, fileUrl),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'حذف',
                        onPressed: () => FirebaseFirestore.instance.collection('contents').doc(doc.id).delete(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 5. تبويب المزيد والملف الشخصي
// ==========================================
class _TeacherProfileTab extends StatelessWidget {
  final AppUser user;

  const _TeacherProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: const Text('المزيد والملف الشخصي', style: TextStyle(color: TeacherColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: TeacherColors.primary,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
            Text(user.email, style: const TextStyle(fontSize: 13, color: TeacherColors.textMuted)),
            const SizedBox(height: 24),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('linkedTeacherUid', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, pendingSnap) {
                int pendingCount = 0;
                if (pendingSnap.hasData && pendingSnap.data != null) {
                  for (var doc in pendingSnap.data!.docs) {
                    final raw = doc.data();
                    if (raw is Map && raw['status'] == 'pending') {
                      pendingCount++;
                    }
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PendingApprovalsScreen(teacher: user)),
                      );
                    },
                    leading: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFDC2626)),
                    title: const Text('طلبات الانضمام للطلاب', style: TextStyle(color: TeacherColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pendingCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                            child: Text('$pendingCount جديد', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: TeacherColors.textMuted),
                      ],
                    ),
                  ),
                );
              },
            ),

            _buildProfileTile(
              Icons.vpn_key,
              user.teacherCode != null ? 'كودك: ${user.teacherCode}' : 'كود المعلم غير مفعل',
              () {
                if (user.teacherCode != null) {
                  Clipboard.setData(ClipboardData(text: user.teacherCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الكود للحافظة!')),
                  );
                }
              },
            ),
            _buildProfileTile(
              Icons.emoji_events_rounded,
              'رصد نتائج الطلاب',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QuizResultsScreen(user: user)),
                );
              },
            ),
            _buildProfileTile(Icons.info_outline, 'معلومات الحساب والتخصص', () {}),
            _buildProfileTile(Icons.help_outline, 'الدعم الفني والمساعدة', () {}),
            const SizedBox(height: 20),
            _buildProfileTile(
              Icons.logout,
              'تسجيل الخروج',
              () async => await AuthService().signOut(),
              isDanger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, VoidCallback onTap, {bool isDanger = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDanger ? Colors.red : TeacherColors.primary),
        title: Text(title, style: TextStyle(color: isDanger ? Colors.red : TeacherColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: isDanger ? Colors.red : TeacherColors.textMuted),
      ),
    );
  }
}

// ==========================================
// 6. نافذة رفع المحتوى
// ==========================================
class _AddContentBottomSheet extends StatefulWidget {
  final String teacherUid;

  const _AddContentBottomSheet({required this.teacherUid});

  @override
  State<_AddContentBottomSheet> createState() => _AddContentBottomSheetState();
}

class _AddContentBottomSheetState extends State<_AddContentBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();

  String _uploadSource = 'file';
  String? _selectedStage = 'الصف الأول الإعدادي';
  String? _selectedType = 'مذكرة / ملف PDF';
  bool _isLoading = false;
  bool _isUploadingFile = false;
  String? _pickedFileName;
  String _uploadStatusText = '';

  final List<String> _stages = [
    'الصف الأول الابتدائي', 'الصف الثاني الابتدائي', 'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي', 'الصف الخامس الابتدائي', 'الصف السادس الابتدائي',
    'الصف الأول الإعدادي', 'الصف الثاني الإعدادي', 'الصف الثالث الإعدادي',
    'الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي',
  ];

  final List<String> _types = [
    'مذكرة / ملف PDF',
    'فيديو شرح',
    'ملخص دراسي',
    'واجب منزلي',
  ];

  Future<void> _pickAndUploadFileFromPhone() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'mp4', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        setState(() {
          _isUploadingFile = true;
          _uploadStatusText = 'جاري رفع الملف للسيرفر... برجاء الانتظار ⏳';
          _pickedFileName = fileName;
          if (_titleController.text.trim().isEmpty) {
            _titleController.text = fileName.split('.').first;
          }
        });

        String? uploadedUrl;

        try {
          var request = http.MultipartRequest('POST', Uri.parse('https://catbox.moe/user/api.php'));
          request.fields['reqtype'] = 'fileupload';
          request.files.add(await http.MultipartFile.fromPath('fileToUpload', filePath));
          var streamedResponse = await request.send().timeout(const Duration(seconds: 40));
          var response = await http.Response.fromStream(streamedResponse);
          if (response.statusCode == 200 && response.body.trim().startsWith('http')) {
            uploadedUrl = response.body.trim();
          }
        } catch (e) {
          debugPrint('Catbox upload failed: $e');
        }

        if (uploadedUrl == null) {
          try {
            var request = http.MultipartRequest('POST', Uri.parse('https://tmpfiles.org/api/v1/upload'));
            request.files.add(await http.MultipartFile.fromPath('file', filePath));
            var streamedResponse = await request.send().timeout(const Duration(seconds: 40));
            var response = await http.Response.fromStream(streamedResponse);
            if (response.statusCode == 200) {
              var json = jsonDecode(response.body);
              String rawUrl = json['data']['url'];
              uploadedUrl = rawUrl.replaceFirst('tmpfiles.org/', 'tmpfiles.org/dl/');
            }
          } catch (e) {
            debugPrint('TmpFiles upload failed: $e');
          }
        }

        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          setState(() {
            _urlController.text = uploadedUrl!;
            _uploadStatusText = 'تم رفع الملف بنجاح! جاهز للحفظ ✅';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم رفع الملف بنجاح 🎉'), backgroundColor: Colors.green),
            );
          }
        } else {
          setState(() {
            _uploadStatusText = 'تعذر الرفع التلقائي، يمكنك وضع رابط مباشر بالأسفل.';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تعذر الرفع التلقائي، يرجى إدخال الرابط يدوياً'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ أثناء اختيار الملف: $e');
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _uploadContent() async {
    final title = _titleController.text.trim();
    final fileUrl = _urlController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل عنوان المحتوى')),
      );
      return;
    }

    if (fileUrl.isEmpty) {
      if (_uploadSource == 'file') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('من فضلك اضغط على زر اختيار الملف أولاً وانتظر اكتمال الرفع')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('من فضلك أدخل رابط المحتوى المباشر')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('contents').add({
        'title': title,
        'description': _descController.text.trim(),
        'fileUrl': fileUrl,
        'stage': _selectedStage,
        'type': _selectedType,
        'uploadSource': _uploadSource,
        'teacherUid': widget.teacherUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ ونشر المحتوى بنجاح 🎉'), backgroundColor: Colors.green),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('رفع محتوى دراسي جديد 📚', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),

            const Text('طريقة الرفع', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _uploadSource,
              decoration: _inputDecoration(),
              items: const [
                DropdownMenuItem(value: 'file', child: Text('رفع ملف من ذاكرة الهاتف (PDF / فيديو / صورة)')),
                DropdownMenuItem(value: 'link', child: Text('إدخال رابط مباشر (Drive / YouTube / غيره)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _uploadSource = val;
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            if (_uploadSource == 'file') ...[
              OutlinedButton.icon(
                onPressed: _isUploadingFile ? null : _pickAndUploadFileFromPhone,
                icon: _isUploadingFile
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.file_upload_outlined, color: TeacherColors.primary),
                label: Text(
                  _isUploadingFile
                      ? 'جاري الرفع إلى السيرفر...'
                      : (_pickedFileName != null ? 'تم اختيار: $_pickedFileName' : 'اضغط لاختيار الملف من الهاتف 📁'),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: TeacherColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: TeacherColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_uploadStatusText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _uploadStatusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _uploadStatusText.contains('بنجاح') ? Colors.green : Colors.blueGrey,
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],

            if (_uploadSource == 'link') ...[
              const Text('رابط المحتوى المباشر', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _urlController,
                decoration: _inputDecoration(hint: 'ضع رابط Google Drive أو YouTube هنا'),
              ),
              const SizedBox(height: 14),
            ],

            const Text('الصف الدراسي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedStage,
              decoration: _inputDecoration(),
              items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _selectedStage = val),
            ),
            const SizedBox(height: 12),

            const Text('نوع المحتوى', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: _inputDecoration(),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedType = val),
            ),
            const SizedBox(height: 12),

            const Text('عنوان المحتوى', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(controller: _titleController, decoration: _inputDecoration(hint: 'مثال: شرح درس الذرة والمادة')),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isLoading || _isUploadingFile) ? null : _uploadContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ ونشر المحتوى', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

// ==========================================
// 7. المكونات المساعدة (تم إصلاح التنسيق لتفادي الشاشة الرصاصي)
// ==========================================
class _StatCard extends StatelessWidget {
  final String title, count;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(count, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
          Text(title, style: const TextStyle(fontSize: 11, color: TeacherColors.textMuted)),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badgeCount;

  const _QuickTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
                  ],
                ),
              ),
              if (badgeCount != null)
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(badgeCount!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
