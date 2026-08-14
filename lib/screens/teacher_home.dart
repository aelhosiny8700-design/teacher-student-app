import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'quiz_create_screen.dart';

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
      _TeacherStudentsTab(user: widget.user), // شاشة إدارة الطلاب
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
class _TeacherDashboardTab extends StatelessWidget {
  final AppUser user;
  final Function(int) onNavigateToTab;
  final VoidCallback onOpenUploadModal;

  const _TeacherDashboardTab({
    required this.user,
    required this.onNavigateToTab,
    required this.onOpenUploadModal,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white, size: 22),
                          onPressed: () async => await AuthService().signOut(),
                        ),
                        if (user.teacherCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: Text('كودك: ${user.teacherCode}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const Text('يَــفـهَــم', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 20),
                Text('أهلاً بك يا أستاذ/ة ${user.name} 👋', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(user.uid, onNavigateToTab),
                const SizedBox(height: 24),
                const Text('الوصول السريع', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.3,
                  children: [
                    _QuickTile(title: 'رفع محتوى', icon: Icons.cloud_upload_rounded, color: const Color(0xFF2563EB), onTap: onOpenUploadModal),
                    _QuickTile(
                      title: 'اختبار جديد', icon: Icons.add_task_rounded, color: const Color(0xFF059669),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizCreateScreen(user: user)));
                      },
                    ),
                    _QuickTile(title: 'المحتوى المضاف', icon: Icons.folder_copy_rounded, color: const Color(0xFFD97706), onTap: () => onNavigateToTab(1)),
                    _QuickTile(title: 'قائمة الطلاب', icon: Icons.people_alt_rounded, color: const Color(0xFF7C3AED), onTap: () => onNavigateToTab(3)),
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
              // إلغاء ربط الطالب بالمعلم
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
  final String title; final IconData icon; final Color color; final VoidCallback onTap;
  const _QuickTile({required this.title, required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color), Text(title)]),
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
