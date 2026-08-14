import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ContentListScreen extends StatefulWidget {
  final AppUser user;

  const ContentListScreen({super.key, required this.user});

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen> {
  String _selectedFilter = 'الكل';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'المواد الدراسية',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip('الكل'),
                const SizedBox(width: 8),
                _buildFilterChip('أساسي'),
                const SizedBox(width: 8),
                _buildFilterChip('ثانوي'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('contents')
                  .where('teacherUid', isEqualTo: widget.user.linkedTeacherUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0062E6)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'لا يوجد محتوى دراسي متاح حالياً',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _SubjectCard(
                      title: data['title'] ?? 'مادة دراسية',
                      subtitle: data['description'] ?? 'عرض دروس ووحدات المادة',
                      lessonsCount: data['lessonsCount'] ?? 12,
                      color: _getSubjectColor(index),
                      icon: _getSubjectIcon(data['title'] ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonDetailScreen(
                              title: data['title'] ?? 'تفاصيل الدرس',
                              contentUrl: data['fileUrl'] ?? '',
                            ),
                          ),
                        );
                      },
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1E293B),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0062E6),
      backgroundColor: const Color(0xFFF1F5F9),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = label);
      },
    );
  }

  Color _getSubjectColor(int index) {
    final colors = [
      const Color(0xFF2563EB),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFF7C3AED),
      const Color(0xFFDC2626),
    ];
    return colors[index % colors.length];
  }

  IconData _getSubjectIcon(String title) {
    if (title.contains('رياضيات')) return Icons.calculate;
    if (title.contains('علوم') || title.contains('فيزياء')) return Icons.science;
    if (title.contains('عربي')) return Icons.menu_book;
    if (title.contains('إنجليزي')) return Icons.language;
    return Icons.school;
  }
}

class _SubjectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int lessonsCount;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.title,
    required this.subtitle,
    required this.lessonsCount,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          '$subtitle • $lessonsCount درس',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
      ),
    );
  }
}

class LessonDetailScreen extends StatelessWidget {
  final String title;
  final String contentUrl;

  const LessonDetailScreen({
    super.key,
    required this.title,
    required this.contentUrl,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        appBar: AppBar(
          title: Text(title, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF1E293B),
          bottom: const TabBar(
            labelColor: Color(0xFF0062E6),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF0062E6),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'الشرح'),
              Tab(text: 'أمثلة'),
              Tab(text: 'اختبر نفسك'),
              Tab(text: 'ملاحظات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExplanationTab(),
            const Center(child: Text('الأمثلة المحلولة ستظهر هنا')),
            const Center(child: Text('أسئلة سريعة على الدرس')),
            const Center(child: Text('الملاحظات والملخصات')),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            const Text(
              'المحتوى التعليمي الخاص بالدرس متاح ومحمل عبر السحابة. يمكنك القراءة والمتابعة للوصول إلى أعلى درجات الفهم.',
              style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }
}
