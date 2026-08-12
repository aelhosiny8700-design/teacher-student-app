import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;
import '../models/user_model.dart';
import '../models/content_model.dart';
import '../services/firestore_service.dart';

class ContentListScreen extends StatefulWidget {
  final AppUser user;
  const ContentListScreen({super.key, required this.user});

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<ContentListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: EduStage.all.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'image':
        return Colors.purple;
      case 'video':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> _openContent(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: const Color(0xFFFF2E5AAC),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: EduStage.all.map((s) => Tab(text: s)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: EduStage.all.map((stage) => _buildList(stage)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildList(String stage) {
    return StreamBuilder<List<ContentItem>>(
      stream: _service.getContentStreamByStage(stage),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'مفيش محتوى هنا.\nهيظهر هنا أي ملفات أو صور أو فيديوهات يرفعها المدرس.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _colorForType(item.type).withOpacity(0.15),
                  child: Icon(_iconForType(item.type), color: _colorForType(item.type)),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${item.description}\n${item.uploadedBy} • ${intl.DateFormat('d/M/yyyy').format(item.createdAt)}',
                ),
                isThreeLine: true,
                trailing: widget.user.isTeacher
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _service.deleteContent(item.id),
                      )
                    : const Icon(Icons.open_in_new),
                onTap: () => _openContent(item.url),
              ),
            );
          },
        );
      },
    );
  }
}


