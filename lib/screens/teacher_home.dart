import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'quiz_create_screen.dart';
import 'pending_approvals_screen.dart';

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
      _TeacherStudentsTab(user: widget.user),
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
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), activeIcon: Icon(Icons.people_alt), label: 'الطلاب'),
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

  // دالة توليد كود عشوائي جديد للمعلم
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
          SnackBar(content: Text('تم توليد كود المعلم الجديد: $newCode 🎉'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء توليد الكود: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingCode = false);
    }
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
          // الهيدر العلوي
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

                // زرار توليد/عرض كود المعلم في الهيدر
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final currentCode = data?['teacherCode'] ?? widget.user.teacherCode;

                    if (currentCode == null || currentCode.toString().isEmpty) {
                      return ElevatedButton.icon(
                        onPressed: _isGeneratingCode ? null : _generateTeacherCode,
                        icon: const Icon(Icons.vpn_key, size: 18, color: TeacherColors.primary),
                        label: const Text('توليد كود المعلم الأن', style: TextStyle(fontWeight: FontWeight.bold, color: TeacherColors.primary)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      );
                    }

                    return InkWell(
                      onTap: () => _copyCodeToClipboard(currentCode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'كودك: $currentCode',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
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

                // شبكة الوصول السريع
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.25,
                  children: [
                    _QuickTile(
                      title: 'رفع محتوى',
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
                    // زرار طلبات الانضمام المعلقة
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('linkedTeacherUid', isEqualTo: widget.user.uid)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, pendingSnap) {
                        final pendingCount = pendingSnap.data?.docs.length ?? 0;
                        return _QuickTile(
                          title: 'طلبات الانضمام',
                          icon: Icons.person_add_alt_1_rounded,
                          color: const Color(0xFFDC2626),
                          badgeCount: pendingCount > 0 ? '$pendingCount' : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PendingApprovalsScreen(user: widget.user)),
                            );
                          },
                        );
                      },
                    ),
                    _QuickTile(
                      title: 'توليد / نسخ الكود',
                      icon: Icons.key_rounded,
                      color: const Color(0xFFD97706),
                      onTap: () {
                        if (widget.user.teacherCode != null) {
                          _copyCodeToClipboard(widget.user.teacherCode!);
                        } else {
                          _generateTeacherCode();
                        }
                      },
                    ),
                    _QuickTile(
                      title: 'قائمة الطلاب',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF7C3AED),
                      onTap: () => widget.onNavigateToTab(3),
                    ),
                    _QuickTile(
                      title: 'المحتوى المضاف',
                      icon: Icons.folder_copy_rounded,
                      color: const Color(0xFF0284C7),
                      onTap: () => widget.onNavigateToTab(1),
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
        final studentsCount = studentSnap.data?.docs.length ?? 0;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('quizzes').where('teacherUid', isEqualTo: teacherUid).snapshots(),
          builder: (context, quizSnap) {
            final quizCount = quizSnap.data?.docs.length ?? 0;
            return Row(
              children: [
                GestureDetector(
                  onTap: () => onNavigateToTab(3),
                  child: _StatCard(title: 'الطلاب', count: '$studentsCount', icon: Icons.people, color: const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => onNavigateToTab(2),
                  child: _StatCard(title: 'الاختبارات', count: '$quizCount', icon: Icons.assignment, color: const Color(0xFF7C3AED)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 2. شاشة إدارة الطلاب وحذفهم
// ==========================================
class _TeacherStudentsTab extends StatelessWidget {
  final AppUser user;

  const _TeacherStudentsTab({required this.user});

  void _confirmDeleteStudent(BuildContext context, String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إزالة طالب', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت أستاذ/ة متأكد من إزالة الطالب ($studentName) من مجموعتك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('users').doc(studentId).update({
                'linkedTeacherUid': FieldValue.delete(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تمت إزالة الطالب $studentName بنجاح')),
                );
              }
            },
            child: const Text('إزالة الطالب', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

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
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'طالب بدون اسم';
              final stage = data['stage'] ?? 'لم يحدد الصف';
              final parentPhone = data['parentPhone'] ?? '';

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
// 3. باقي التبويبات والمكونات المساعدة
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
            return const Center(child: Text('لم تقم بنشر أي اختبارات حتى الآن'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final q = doc.data() as Map<String, dynamic>;
              final questions = (q['questions'] as List?)?.length ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.quiz, color: TeacherColors.primary)),
                  title: Text(q['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${q['subject']} • ${q['stage']} • $questions أسئلة'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('quizzes').doc(doc.id).delete();
                    },
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
  String? _selectedStage = 'الصف الأول الإعدادي';
  String? _selectedType = 'مذكرة / ملف PDF';

  final List<String> _stages = [
    'الصف الأول الابتدائي', 'الصف الثاني الابتدائي', 'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي', 'الصف الخامس الابتدائي', 'الصف السادس الابتدائي',
    'الصف الأول الإعدادي', 'الصف الثاني الإعدادي', 'الصف الثالث الإعدادي',
    'الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي',
  ];

  Future<void> _uploadContent() async {
    if (_titleController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('contents').add({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'fileUrl': _urlController.text.trim(),
      'stage': _selectedStage,
      'type': _selectedType,
      'teacherUid': widget.teacherUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('رفع محتوى جديد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedStage,
            items: _stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() => _selectedStage = val),
          ),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'عنوان المحتوى')),
          TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'الرابط')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _uploadContent, child: const Text('حفظ')),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _UploadedContentTab extends StatelessWidget {
  final AppUser user;
  final VoidCallback onOpenUploadModal;
  const _UploadedContentTab({required this.user, required this.onOpenUploadModal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحتوى المضاف')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('contents').where('teacherUid', isEqualTo: user.uid).snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(d['title'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => FirebaseFirestore.instance.collection('contents').doc(docs[i].id).delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, count; final IconData icon; final Color color;
  const _StatCard({required this.title, required this.count, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text(title)]),
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

class _TeacherProfileTab extends StatelessWidget {
  final AppUser user;
  const _TeacherProfileTab({required this.user});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: ElevatedButton(onPressed: () => AuthService().signOut(), child: const Text('تسجيل الخروج'))));
  }
}
