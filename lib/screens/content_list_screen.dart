import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';

class ContentListScreen extends StatefulWidget {
  final AppUser user;

  const ContentListScreen({super.key, required this.user});

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen> {
  String _selectedTypeFilter = 'الكل';

  final List<String> _types = [
    'الكل',
    'مذكرة / ملف PDF',
    'فيديو شرح',
    'ملخص دراسي',
    'واجب منزلي',
  ];

  void _openUrl(String urlString) async {
    if (urlString.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط المحتوى غير متوفر')),
      );
      return;
    }

    final Uri url = Uri.parse(urlString.trim());
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح رابط الملف أو الفيديو')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, userSnapshot) {
        String? teacherUid = widget.user.linkedTeacherUid;
        // دعم قراءة الحقل سواء كان grade أو stage
String? studentGrade = widget.user.stage;
        String? status = widget.user.status;

        if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
          final rawUser = userSnapshot.data!.data();
          if (rawUser is Map) {
            teacherUid = rawUser['linkedTeacherUid']?.toString() ?? teacherUid;
            // قراءة grade أو stage من قاعدة البيانات مباشرة
            studentGrade = rawUser['grade']?.toString() ?? rawUser['stage']?.toString() ?? studentGrade;
            status = rawUser['status']?.toString() ?? status;
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FC),
          appBar: AppBar(
            title: Column(
              children: [
                const Text('المحتوى الدراسي 📚', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
                Text(studentGrade ?? 'الصف الدراسي', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: _buildBody(teacherUid, studentGrade, status),
        );
      },
    );
  }

  Widget _buildBody(String? teacherUid, String? studentGrade, String? status) {
    if (teacherUid == null || teacherUid.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.vpn_key_outlined, size: 64, color: Colors.orange.shade400),
              const SizedBox(height: 16),
              const Text(
                'لم تنضم إلى معلم بعد!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'يرجى إدخال كود المعلم من الشاشة الرئيسية لتتمكن من رؤية المذكرات والفيديوهات الخاصة بصفك.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    // ملاحظة: إذا أردت أن يظهر المحتوى للطالب حتى لو كان في حالة pending، يمكنك إزالة هذا الشرط
    if (status == 'pending') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 64, color: Colors.amber.shade600),
              const SizedBox(height: 16),
              const Text(
                'طلب الانضمام قيد الانتظار ⏳',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'تم إرسال طلبك للمعلم، وبمجرد الموافقة عليه سيظهر كل المحتوى الدراسي هنا تلقائياً.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _types.map((type) {
                final isSelected = _selectedTypeFilter == type;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0062E6),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTypeFilter = type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('contents')
                .where('teacherId', isEqualTo: teacherUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0062E6)));
              }

              final docs = snapshot.data?.docs ?? [];

              final filteredDocs = docs.where((doc) {
                final raw = doc.data();
                if (raw is! Map) return false;
                final data = raw.cast<String, dynamic>();

                // فحص الحقل سواء كان grade أو stage في جدول المحتويات
                final contentGrade = data['grade']?.toString() ?? data['stage']?.toString();
                final contentType = data['type']?.toString();

                final bool gradeMatch = (studentGrade == null || studentGrade.isEmpty) || (contentGrade == studentGrade);
                final bool typeMatch = _selectedTypeFilter == 'الكل' || (contentType == _selectedTypeFilter);

                return gradeMatch && typeMatch;
              }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'لا يوجد محتوى مضاف لـ (${studentGrade ?? 'صفك'}) حالياً',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final raw = doc.data();
                  final Map<String, dynamic> data = (raw is Map) ? raw.cast<String, dynamic>() : {};
                  final title = data['title']?.toString() ?? 'محتوى دراسي';
                  final description = data['description']?.toString() ?? '';
                  final type = data['type']?.toString() ?? 'ملف';
                  final fileUrl = data['fileUrl']?.toString() ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                    child: ListTile(
                      onTap: () => _openUrl(fileUrl),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getContentTypeColor(type).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getContentTypeIcon(type), color: _getContentTypeColor(type), size: 24),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                      subtitle: Text(
                        description.isNotEmpty ? '$description • $type' : type,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      trailing: ElevatedButton.icon(
                        onPressed: () => _openUrl(fileUrl),
                        icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white),
                        label: const Text('فتح', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0062E6),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getContentTypeColor(String type) {
    if (type.contains('فيديو')) return const Color(0xFFDC2626);
    if (type.contains('مذكرة') || type.contains('PDF')) return const Color(0xFF2563EB);
    if (type.contains('واجب')) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  IconData _getContentTypeIcon(String type) {
    if (type.contains('فيديو')) return Icons.play_circle_fill_rounded;
    if (type.contains('مذكرة') || type.contains('PDF')) return Icons.picture_as_pdf_rounded;
    if (type.contains('واجب')) return Icons.assignment_rounded;
    return Icons.menu_book_rounded;
  }
}
