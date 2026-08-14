import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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
      _PlaceholderTab(title: 'إدارة الاختبارات', icon: Icons.assignment),
      _PlaceholderTab(title: 'الرسائل والاستفسارات', icon: Icons.chat),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'المحتوى',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'الاختبارات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'الرسائل',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'المزيد',
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
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
                          tooltip: 'خروج',
                        ),
                        if (user.teacherCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'كودك: ${user.teacherCode}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'يَــفـهَــم',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'لوحة تحكم المعلم 👨‍🏫',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'مرحباً بك يا أستاذ/ة ${user.name} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(user.uid),
                const SizedBox(height: 24),
                const Text(
                  'الوصول السريع',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: TeacherColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.3,
                  children: [
                    _QuickTile(
                      title: 'رفع محتوى',
                      icon: Icons.cloud_upload_rounded,
                      color: const Color(0xFF2563EB),
                      onTap: onOpenUploadModal,
                    ),
                    _QuickTile(
                      title: 'اختبار جديد',
                      icon: Icons.add_task_rounded,
                      color: const Color(0xFF059669),
                      onTap: () => onNavigateToTab(2),
                    ),
                    _QuickTile(
                      title: 'المحتوى المضاف',
                      icon: Icons.folder_copy_rounded,
                      color: const Color(0xFFD97706),
                      onTap: () => onNavigateToTab(1),
                    ),
                    _QuickTile(
                      title: 'الرسائل',
                      icon: Icons.mark_chat_unread_rounded,
                      color: const Color(0xFF7C3AED),
                      onTap: () => onNavigateToTab(3),
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

  Widget _buildStatsRow(String teacherUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('linkedTeacherUid', isEqualTo: teacherUid)
          .snapshots(),
      builder: (context, studentSnap) {
        final studentsCount = studentSnap.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('contents')
              .where('teacherUid', isEqualTo: teacherUid)
              .snapshots(),
          builder: (context, contentSnap) {
            final contentCount = contentSnap.data?.docs.length ?? 0;

            return Row(
              children: [
                _StatCard(title: 'الطلاب', count: '$studentsCount', icon: Icons.people, color: const Color(0xFF2563EB)),
                const SizedBox(width: 10),
                _StatCard(title: 'المحتوى', count: '$contentCount', icon: Icons.folder, color: const Color(0xFFD97706)),
                const SizedBox(width: 10),
                const _StatCard(title: 'الاختبارات', count: '0', icon: Icons.assignment, color: Color(0xFF7C3AED)),
              ],
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 2. نافذة رفع المحتوى مع جميع المراحل الدراسية
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

  String? _selectedStage = 'الصف الأول الابتدائي';
  String? _selectedType = 'مذكرة / ملف PDF';
  bool _isLoading = false;

  // القائمة الكاملة من أولى ابتدائي إلى ثالثة ثانوي
  final List<String> _stages = [
    // المرحلة الابتدائية
    'الصف الأول الابتدائي',
    'الصف الثاني الابتدائي',
    'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي',
    'الصف الخامس الابتدائي',
    'الصف السادس الابتدائي',
    // المرحلة الإعدادية
    'الصف الأول الإعدادي',
    'الصف الثاني الإعدادي',
    'الصف الثالث الإعدادي',
    // المرحلة الثانوية
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي',
    'الصف الثالث الثانوي',
  ];

  final List<String> _types = [
    'مذكرة / ملف PDF',
    'فيديو شرح',
    'ملخص دراسي',
    'واجب منزلي',
  ];

  Future<void> _uploadContent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل عنوان المحتوى')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('contents').add({
        'title': title,
        'description': _descController.text.trim(),
        'fileUrl': _urlController.text.trim(),
        'stage': _selectedStage,
        'type': _selectedType,
        'teacherUid': widget.teacherUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفع المحتوى بنجاح 🎉'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الرفع: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'رفع محتوى دراسي جديد 📚',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TeacherColors.textDark),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // القائمة المنسدلة 1: الصف الدراسي (شاملة كل المراحل)
            const Text('الصف الدراسي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedStage,
              decoration: _inputDecoration(),
              items: _stages.map((stage) {
                return DropdownMenuItem(value: stage, child: Text(stage));
              }).toList(),
              onChanged: (val) => setState(() => _selectedStage = val),
            ),
            const SizedBox(height: 14),

            // القائمة المنسدلة 2: نوع المحتوى
            const Text('نوع المحتوى', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: _inputDecoration(),
              items: _types.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val),
            ),
            const SizedBox(height: 14),

            // حقل العنوان
            const Text('عنوان الدرس / المحتوى', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration(hint: 'مثال: شرح درس الذرة والمادة'),
            ),
            const SizedBox(height: 14),

            // حقل الوصف
            const Text('الوصف (اختياري)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              decoration: _inputDecoration(hint: 'أضف ملاحظات أو تعليمات للطلاب'),
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            // رابط الملف أو الفيديو
            const Text('رابط الملف / الفيديو (Cloudinary أو Drive)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              decoration: _inputDecoration(hint: 'ضع رابط التحميل هنا'),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('رفع وحفظ المحتوى', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// ==========================================
// 3. تبويب المحتوى المضاف
// ==========================================
class _UploadedContentTab extends StatelessWidget {
  final AppUser user;
  final VoidCallback onOpenUploadModal;

  const _UploadedContentTab({required this.user, required this.onOpenUploadModal});

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
        label: const Text('إضافة محتوى', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('contents')
            .where('teacherUid', isEqualTo: user.uid)
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
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TeacherColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.insert_drive_file, color: TeacherColors.primary),
                  ),
                  title: Text(data['title'] ?? 'بدون عنوان', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text('${data['stage'] ?? ''} • ${data['type'] ?? ''}', style: const TextStyle(fontSize: 12, color: TeacherColors.textMuted)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('contents').doc(doc.id).delete();
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

// ==========================================
// 4. أجزاء مساعدة
// ==========================================
class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
            Text(title, style: const TextStyle(fontSize: 12, color: TeacherColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickTile({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TeacherColors.textDark)),
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
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: const Text('الملف الشخصي للمعلم', style: TextStyle(color: TeacherColors.textDark, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 20),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async => await AuthService().signOut(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: TeacherColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: TeacherColors.primary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text('شاشة $title', style: const TextStyle(fontSize: 16, color: TeacherColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
