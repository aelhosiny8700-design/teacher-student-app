import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final AppUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _service = FirestoreService();
  final _scrollController = ScrollController();

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await _service.sendMessage(AnnouncementMessage(
      id: '',
      text: text,
      senderName: widget.user.name,
      senderId: widget.user.uid,
      isAnnouncement: widget.user.isTeacher,
      createdAt: DateTime.now(),
    ));

    _controller.clear();

    // نزول لآخر رسالة بعد إرسالها
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<AnnouncementMessage>>(
            stream: _service.getMessagesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return const Center(
                  child: Text('مفيش رسائل لسه', style: TextStyle(color: Colors.grey)),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == widget.user.uid;
                  return _buildBubble(msg, isMe);
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: widget.user.isTeacher
                          ? 'اكتب تنبيه عام للطلبة...'
                          : 'اكتب رسالتك...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF2E5AAC),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(AnnouncementMessage msg, bool isMe) {
    if (msg.isAnnouncement) {
      // رسالة تنبيه عام من المدرس - تظهر بشكل مميز للكل
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFE69C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign, size: 16, color: Color(0xFF856404)),
                const SizedBox(width: 6),
                Text(
                  'تنبيه من ${msg.senderName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF856404), fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(msg.text),
            const SizedBox(height: 4),
            Text(
              intl.DateFormat('d/M - h:mm a').format(msg.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2E5AAC) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(msg.senderName,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMe ? Colors.white70 : Colors.grey.shade700)),
            Text(
              msg.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
