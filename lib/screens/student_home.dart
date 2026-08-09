import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'content_list_screen.dart';
import 'quiz_list_screen.dart';
import 'chat_screen.dart';

class StudentHome extends StatefulWidget {
  final AppUser user;
  const StudentHome({super.key, required this.user});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
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
        title: Text('أهلاً ${widget.user.name}'),
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
}
