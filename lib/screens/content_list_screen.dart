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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('المحتوى الدراسي', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.user.stage ?? 'الصف الدراسي', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // أزرار فلترة أنواع المحتوى
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

          // جلب المحتوى الخاص بمعلم الطالب ومرحلته الدراسية
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('contents')
                  .where('teacherUid', isEqualTo: widget.user.linkedTeacherUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0062E6)));
                }

                final docs = snapshot.data?.docs ?? [];

                // تصفية المحتوى بدقة: مرحلة الطالب + نوع المحتوى المختار
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final stageMatch = data['stage'] == widget.user.stage;
                  final typeMatch = _selectedTypeFilter == 'الكل' || data['type'] == _selectedTypeFilter;
                  return stageMatch && typeMatch;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'لا يوجد محتوى مضاف لـ (${widget.user.stage ?? 'مرحلتك'}) حالياً',
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
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'محتوى دراسي';
                    final description = data['description'] ?? '';
                    final type = data['type'] ?? 'ملف';
                    final fileUrl = data['fileUrl'] ?? '';

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
                        trailing: IconButton(
                          icon: const Icon(Icons.file_download_outlined, color: Color(0xFF0062E6)),
                          onPressed: () => _openUrl(fileUrl),
                        ),
                      ),
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
