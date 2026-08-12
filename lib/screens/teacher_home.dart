import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'content_list_screen.dart';
import 'upload_content_screen.dart';
import 'quiz_list_screen.dart';
import 'quiz_create_screen.dart';
import 'chat_hub_screen.dart';

// ألوان الهوية الأساسية للتطبيق
class AppColors {
  static const primary = Color(0xFF2E5AAC);
  static const primaryDark = Color(0xFF1E3F7D);
  static const primaryLight = Color(0xFF5C82C9);
  static const accent = Color(0xFFFFA726);
  static const background = Color(0xFFF4F6FA);
  static const cardShadow = Color(0x1A1E3F7D);
}

class TeacherHome extends StatefulWidget {
  final AppUser user;
  const TeacherHome({super.key, required this.user});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _TeacherDashboardTab(user: widget.user),
      ContentListScreen(user: widget.user),
      QuizListScreen(user: widget.user),
      ChatHubScreen(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهلاً أستاذ/ة ${widget.user.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'لوحة تحكم المعلم',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: pages[_index],
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder, color: AppColors.primary),
            label: 'المحتوى',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz, color: AppColors.primary),
            label: 'الاختبارات',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.primary),
            label: 'الرسائل',
          ),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    if (_index == 1) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('رفع محتوى', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UploadContentScreen(user: widget.user)),
          );
        },
      );
    } else if (_index == 2) {
      return FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('اختبار جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QuizCreateScreen(user: widget.user)),
          );
        },
      );
    }
    return null;
  }
}

/// تبويب الرئيسية: إحصائيات المعلم + وصول سريع
class _TeacherDashboardTab extends StatelessWidget {
  final AppUser user;
  const _TeacherDashboardTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _WelcomeBanner(name: user.name),
          const SizedBox(height: 20),
          _StatsRow(teacherUid: user.uid),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'الوصول السريع'),
          const SizedBox(height: 12),
          _QuickActionsGrid(user: user),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'آخر المحتوى المضاف'),
          const SizedBox(height: 12),
          _RecentContentList(teacherUid: user.uid),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;
  const _WelcomeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبًا بيك يا أستاذ $name 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'تابع طلابك وأضف محتوى واختبارات جديدة من هنا',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final String teacherUid;
  const _StatsRow({required this.teacherUid});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people_alt,
            color: const Color(0xFF43A047),
            label: 'الطلاب',
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .snapshots(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.folder_copy,
            color: const Color(0xFFFB8C00),
            label: 'المحتوى',
            stream: FirebaseFirestore.instance
                .collection('content')
                .where('teacherUid', isEqualTo: teacherUid)
                .snapshots(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.quiz,
            color: const Color(0xFFAB47BC),
            label: 'الاختبارات',
            stream: FirebaseFirestore.instance
                .collection('quizzes')
                .where('teacherUid', isEqualTo: teacherUid)
                .snapshots(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Stream<QuerySnapshot> stream;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Text(
                snapshot.connectionState == ConnectionState.waiting ? '—' : '$count',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final AppUser user;
  const _QuickActionsGrid({required this.user});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.upload_file,
        color: const Color(0xFF2E5AAC),
        label: 'رفع محتوى',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UploadContentScreen(user: user))),
      ),
      _QuickAction(
        icon: Icons.add_box,
        color: const Color(0xFFAB47BC),
        label: 'اختبار جديد',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizCreateScreen(user: user))),
      ),
      _QuickAction(
        icon: Icons.folder_open,
        color: const Color(0xFFFB8C00),
        label: 'كل المحتوى',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentListScreen(user: user))),
      ),
      _QuickAction(
        icon: Icons.chat_bubble,
        color: const Color(0xFF43A047),
        label: 'الرسائل',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatHubScreen(user: user))),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.6,
      children: actions,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentContentList extends StatelessWidget {
  final String teacherUid;
  const _RecentContentList({required this.teacherUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('content')
          .where('teacherUid', isEqualTo: teacherUid)
          .orderBy('createdAt', descending: true)
          .limit(4)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('لسه مفيش محتوى مضاف', style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insert_drive_file, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (data['title'] ?? 'بدون عنوان').toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
