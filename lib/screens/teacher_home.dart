import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'content_list_screen.dart';
import 'upload_content_screen.dart';
import 'quiz_list_screen.dart';
import 'quiz_create_screen.dart';
import 'chat_screen.dart';

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
      ContentListScreen(user: widget.user),
      QuizListScreen(user: widget.user),
      ChatScreen(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('أهلاً أستاذ/ة ${widget.user.name}'),
        backgroundColor: const Color(0xFF2E5AAC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: pages[_index],
      floatingActionButton: _buildFab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: const Color(0xFF2E5AAC),
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'المحتوى'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'الاختبارات'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'التنبيهات'),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    if (_index == 0) {
      return FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E5AAC),
        icon: const Icon(Icons.upload, color: Colors.white),
        label: const Text('رفع محتوى', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UploadContentScreen(user: widget.user),
            ),
          );
        },
      );
    } else if (_index == 1) {
      return FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E5AAC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('اختبار جديد', style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizCreateScreen(user: widget.user),
            ),
          );
        },
      );
    }
    return null;
  }
}
