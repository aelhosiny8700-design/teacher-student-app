import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ChatHubScreen extends StatelessWidget {
  final AppUser user;

  const ChatHubScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          'الرسائل والاستفسارات',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF0062E6).withOpacity(0.12),
                child: const Icon(Icons.person, color: Color(0xFF0062E6)),
              ),
              title: const Text(
                'المعلم الخاص بك',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: const Text(
                'اضغط هنا لبدء محادثة طرح الأسئلة والواجبات',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              trailing: const Icon(Icons.chat, color: Color(0xFF0062E6)),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
