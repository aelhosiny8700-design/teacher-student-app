import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'content_list_screen.dart';
import 'quiz_list_screen.dart';
import 'chat_hub_screen.dart';
import 'teacher_home.dart' show AppColors;

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
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _StudentDashboardTab(user: widget.user),
      ContentListScreen(user: widget.user),
      QuizListScreen(user: widget.user),
      ChatHubScreen(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهلاً ${widget.user.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'لوحة تحكم الطالب',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard,
              color: AppColors.primary,
            ),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(
              Icons.folder,
              color: AppColors.primary,
            ),
            label: 'المحتوى',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(
              Icons.quiz,
              color: AppColors.primary,
            ),
            label: 'الاختبارات',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(
              Icons.chat_bubble,
              color: AppColors.primary,
            ),
            label: 'الرسائل',
          ),
        ],
      ),
    );
  }
}

class _StudentDashboardTab extends StatelessWidget {
  final AppUser user;

  const _StudentDashboardTab({
    required this.user,
  });

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
          _ProgressRow(uid: user.uid),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'الوصول السريع'),
          const SizedBox(height: 12),
          _QuickActionsGrid(user: user),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'آخر نتائجك'),
          const SizedBox(height: 12),
          _RecentResultsList(uid: user.uid),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;

  const _WelcomeBanner({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبًا بيك يا $name 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'استمر في مذاكرتك وحل الاختبارات عشان تحسن مستواك',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
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
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String uid;

  const _ProgressRow({
    required this.uid,
  });

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

          avg = (sum / total) * 100;
        }

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                color: const Color(0xFF43A047),
                label: 'اختبارات مُنجزة',
                value: snapshot.connectionState == ConnectionState.waiting
                    ? '—'
                    : '$total',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.trending_up,
                color: const Color(0xFF2E5AAC),
                label: 'متوسط الدرجات',
                value: snapshot.connectionState == ConnectionState.waiting
                    ? '—'
                    : '${avg.toStringAsFixed(0)}%',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final AppUser user;

  const _QuickActionsGrid({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.menu_book,
        color: const Color(0xFF2E5AAC),
        label: 'المحتوى الدراسي',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ContentListScreen(
                user: user,
              ),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.quiz,
        color: const Color(0xFFAB47BC),
        label: 'حل اختبار',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizListScreen(
                user: user,
              ),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.chat_bubble,
        color: const Color(0xFF43A047),
        label: 'اسأل المعلم',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatHubScreen(
                user: user,
              ),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.emoji_events,
        color: const Color(0xFFFB8C00),
        label: 'نتائجي',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizListScreen(
                user: user,
              ),
            ),
          );
        },
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
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
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

class _RecentResultsList extends StatelessWidget {
  final String uid;

  const _RecentResultsList({
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz_results')
          .where('studentUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('حدث خطأ أثناء تحميل النتائج')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
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
              child: Text(
                'لسه مفيش نتائج اختبارات',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        // ترتيب المستندات في الكود لتجنب خطأ الترتيب المركب مع الفلترة
        final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
        sortedDocs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return Column(
          children: sortedDocs.take(4).map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final score = data['score'] ?? 0;
            final maxScore = data['maxScore'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (data['quizTitle'] ?? 'اختبار').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$score / $maxScore',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
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
