import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'content_list_screen.dart';
import 'quiz_list_screen.dart';
import 'chat_hub_screen.dart';

class NewUiColors {
  static const primary = Color(0xFF0062E6);
  static const primaryDark = Color(0xFF004CB3);
  static const background = Color(0xFFF4F7FC);
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
}

class StudentHome extends StatefulWidget {
  final AppUser user;

  const StudentHome({
    super.key,
    required this.user,
  });

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeDashboardTab(
        user: widget.user,
        onNavigateToTab: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      ContentListScreen(user: widget.user),
      QuizListScreen(user: widget.user),
      ChatHubScreen(user: widget.user),
      _ProfileTab(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: NewUiColors.background,
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
          selectedItemColor: NewUiColors.primary,
          unselectedItemColor: NewUiColors.textMuted,
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
              label: 'المواد',
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

class _HomeDashboardTab extends StatelessWidget {
  final AppUser user;
  final Function(int) onNavigateToTab;

  const _HomeDashboardTab({
    required this.user,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: NewUiColors.primary,
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _HeaderSection(user: user),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuickAccessGrid(
                    user: user,
                    onNavigateToTab: onNavigateToTab,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'التقدم في المواد',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: NewUiColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SubjectProgressCard(uid: user.uid),
                  const SizedBox(height: 28),
                  const Text(
                    'آخر النتائج',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: NewUiColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RecentResultsList(uid: user.uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final AppUser user;

  const _HeaderSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [NewUiColors.primary, NewUiColors.primaryDark],
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
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                onPressed: () {},
              ),
              Row(
                children: [
                  const Text(
                    'يَــفـهَــم',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.black,
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
            'تعلم بسهولة، وابدع كل يوم ✨',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'أهلاً بك 👋 ${user.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final AppUser user;
  final Function(int) onNavigateToTab;

  const _QuickAccessGrid({
    required this.user,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.3,
      children: [
        _CategoryCard(
          title: 'المواد',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF2563EB),
          onTap: () => onNavigateToTab(1),
        ),
        _CategoryCard(
          title: 'الاختبارات',
          icon: Icons.assignment_turned_in_rounded,
          color: const Color(0xFF059669),
          onTap: () => onNavigateToTab(2),
        ),
        _CategoryCard(
          title: 'الرسائل',
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFFD97706),
          onTap: () => onNavigateToTab(3),
        ),
        _CategoryCard(
          title: 'الملف الشخصي',
          icon: Icons.person_rounded,
          color: const Color(0xFF7C3AED),
          onTap: () => onNavigateToTab(4),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
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
                  color: NewUiColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectProgressCard extends StatelessWidget {
  final String uid;

  const _SubjectProgressCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz_results')
          .where('studentUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final total = docs.length;

        double avg = 0;
        if (total > 0) {
          double sum = 0;
          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final score = data['score'] ?? 0;
            final maxScore = data['maxScore'] ?? 1;
            if (score is num && maxScore is num && maxScore > 0) {
              sum += score / maxScore;
            }
          }
          avg = (sum / total);
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'معدل النجاح الإجمالي',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: NewUiColors.textDark,
                    ),
                  ),
                  Text(
                    '${(avg * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: NewUiColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: avg,
                  minHeight: 10,
                  backgroundColor: NewUiColors.primary.withOpacity(0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(NewUiColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF059669)),
                  const SizedBox(width: 6),
                  Text(
                    'إجمالي الاختبارات المكتملة: $total',
                    style: const TextStyle(fontSize: 12, color: NewUiColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentResultsList extends StatelessWidget {
  final String uid;

  const _RecentResultsList({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz_results')
          .where('studentUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: NewUiColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('لا يوجد نتائج اختبارات حتى الآن', style: TextStyle(color: NewUiColors.textMuted)),
            ),
          );
        }

        final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
        sortedDocs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return Column(
          children: sortedDocs.take(3).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final score = data['score'] ?? 0;
            final maxScore = data['maxScore'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (data['quizTitle'] ?? 'اختبار').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Text(
                    '$score / $maxScore',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: NewUiColors.primary,
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

class _ProfileTab extends StatelessWidget {
  final AppUser user;

  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewUiColors.background,
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(color: NewUiColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 45,
              backgroundColor: NewUiColors.primary.withOpacity(0.15),
              child: const Icon(Icons.person, size: 50, color: NewUiColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: NewUiColors.textDark),
            ),
            Text(
              user.email,
              style: const TextStyle(fontSize: 13, color: NewUiColors.textMuted),
            ),
            const SizedBox(height: 28),
            _buildProfileTile(Icons.info_outline, 'معلومات الحساب', () {}),
            _buildProfileTile(Icons.lock_outline, 'تغيير كلمة المرور', () {}),
            _buildProfileTile(Icons.help_outline, 'الدعم والمساعدة', () {}),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDanger ? Colors.red : NewUiColors.primary),
        title: Text(
          title,
          style: TextStyle(
            color: isDanger ? Colors.red : NewUiColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDanger ? Colors.red : NewUiColors.textMuted,
        ),
      ),
    );
  }
}
