import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherStudentsScreen extends StatelessWidget {
  final AppUser user;
  const TeacherStudentsScreen({super.key, required this.user});

  void _updateStudentStatus(BuildContext context, String studentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(studentId).update({
        'status': newStatus,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'archived' ? 'تم نقل الطالب إلى الأرشيف' : 'تمت استعادة الطالب بنجاح'),
            backgroundColor: newStatus == 'archived' ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openWhatsApp(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف غير متوفر')),
      );
      return;
    }
    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '20${formattedPhone.substring(1)}';
    }
    final Uri url = Uri.parse('https://wa.me/$formattedPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق واتساب')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        appBar: AppBar(
          title: const Text('إدارة الطلاب', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0062E6),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: [
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'الطلاب النشطون'),
              Tab(icon: Icon(Icons.archive_outlined), text: 'الأرشيف'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStudentsList(context, 'approved', false),
            _buildStudentsList(context, 'archived', true),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList(BuildContext context, String status, bool isArchived) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('linkedTeacherUid', isEqualTo: user.uid)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ في تحميل البيانات: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isArchived ? Icons.archive_outlined : Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  isArchived ? 'لا يوجد طلاب في الأرشيف' : 'لا يوجد طلاب نشطون حالياً',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String studentName = data['name'] ?? 'بدون اسم';
            final String stage = data['stage'] ?? 'غير محدد';
            final String? parentPhone = data['parentPhone'];

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1.5,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: isArchived ? Colors.grey.shade300 : const Color(0xFF0062E6).withOpacity(0.12),
                  child: Icon(
                    Icons.person,
                    color: isArchived ? Colors.grey.shade600 : const Color(0xFF0062E6),
                  ),
                ),
                title: Text(
                  studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  'المرحلة: $stage',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isArchived && parentPhone != null && parentPhone.trim().isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                        tooltip: 'مراسلة ولي الأمر',
                        onPressed: () => _openWhatsApp(context, parentPhone),
                      ),
                    IconButton(
                      icon: Icon(
                        isArchived ? Icons.settings_backup_restore_rounded : Icons.archive_outlined,
                        color: isArchived ? Colors.green : Colors.orange,
                      ),
                      tooltip: isArchived ? 'استعادة الطالب' : 'أرشفة الطالب',
                      onPressed: () => _updateStudentStatus(
                        context,
                        doc.id,
                        isArchived ? 'approved' : 'archived',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
