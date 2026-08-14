import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class TeacherColors {
  static const primary = Color(0xFF0062E6);
  static const primaryDark = Color(0xFF004CB3);
  static const background = Color(0xFFF4F7FC);
  static const cardBg = Colors.white;
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
      _TeacherDashboardTab(user: widget.user),
      _PlaceholderTab(title: 'المحتوى المضاف', icon: Icons.folder),
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
}

class _TeacherDashboardTab extends StatelessWidget {
  final AppUser user;

  const _TeacherDashboardTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // الهيدر الأزرق المائل علوياً (طراز يفهم)
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
                // كروت الإحصائيات (الطلبة - المحتوى - الاختبارات)
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

                // أزرار الوصول السريع
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
                      onTap: () {},
                    ),
                    _QuickTile(
                      title: 'اختبار جديد',
                      icon: Icons.add_task_rounded,
                      color: const Color(0xFF059669),
                      onTap: () {},
                    ),
                    _QuickTile(
                      title: 'طلبات الانضمام',
                      icon: Icons.person_add_alt_1_rounded,
                      color: const Color(0xFFD97706),
                      onTap: () {},
                    ),
                    _QuickTile(
                      title: 'الرسائل',
                      icon: Icons.mark_chat_unread_rounded,
                      color: const Color(0xFF7C3AED),
                      onTap: () {},
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

        return Row(
          children: [
            _StatCard(title: 'الطلاب', count: '$studentsCount', icon: Icons.people, color: const Color(0xFF2563EB)),
            const SizedBox(width: 10),
            const _StatCard(title: 'المحتوى', count: '1', icon: Icons.folder, color: Color(0xFFD97706)),
            const SizedBox(width: 10),
            const _StatCard(title: 'الاختبارات', count: '0', icon: Icons.assignment, color: Color(0xFF7C3AED)),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

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
            Text(
              count,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TeacherColors.textDark),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: TeacherColors.textMuted),
            ),
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

  const _QuickTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
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
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: TeacherColors.textDark,
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
              backgroundColor: Color(0xFF0062E6),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TeacherColors.textDark),
            ),
            Text(
              user.email,
              style: const TextStyle(fontSize: 13, color: TeacherColors.textMuted),
            ),
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
            Text(
              'شاشة $title',
              style: const TextStyle(fontSize: 16, color: TeacherColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
