import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final AppUser user;
  final String chatId;
  final String title;
  final bool isGeneral;
  final String? stage;

  const ChatScreen({
    super.key,
    required this.user,
    required this.chatId,
    required this.title,
    required this.isGeneral,
    this.stage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _service = FirestoreService();

  bool _sending = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await _service.sendMessage(
        AnnouncementMessage(
          id: '',
          chatId: widget.chatId,
          text: text,
          senderName: widget.user.name,
          senderId: widget.user.uid,
          isAnnouncement: widget.isGeneral && widget.user.isTeacher,
          stage: widget.stage,
          createdAt: DateTime.now(),
        ),
      );
      _controller.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال الرسالة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showMessageOptions(AnnouncementMessage message, bool isMe) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('نسخ'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الرسالة')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('حذف عندي', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _service.deleteMessageForMe(message.id, widget.user.uid);
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('حذف عند الجميع', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await _confirmDeleteForEveryone();
                    if (confirmed == true) {
                      _service.deleteMessage(message.id);
                    }
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDeleteForEveryone() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف عند الجميع'),
        content: const Text('هتتشال الرسالة دي عند الطرف التاني برضه، مش عندك بس. متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF2E5AAC),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AnnouncementMessage>>(
              stream: _service.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'حدث خطأ في تحميل الرسائل\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final messages = (snapshot.data ?? [])
                    .where((m) => !m.isDeletedFor(widget.user.uid))
                    .toList();

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      widget.isGeneral ? 'لا توجد رسائل في الشات العام' : 'ابدأ المحادثة',
                      style: const TextStyle(color: Colors.grey),
                    ),
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
                    final message = messages[index];
                    final isMe = message.senderId == widget.user.uid;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      isGeneral: widget.isGeneral,
                      onLongPress: () => _showMessageOptions(message, isMe),
                    );
                  },
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    final hint = widget.isGeneral
        ? widget.user.isTeacher
            ? 'اكتب تنبيه للطلاب...'
            : 'اكتب رسالتك في الشات العام...'
        : 'اكتب رسالتك...';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textDirection: TextDirection.rtl,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF2E5AAC),
              child: IconButton(
                onPressed: _sending ? null : _sendMessage,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AnnouncementMessage message;
  final bool isMe;
  final bool isGeneral;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isGeneral,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (isGeneral && message.isAnnouncement) {
      return GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFE69C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, size: 18, color: Color(0xFF856404)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'تنبيه من ${message.senderName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF856404)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(message.text, textDirection: TextDirection.rtl),
              const SizedBox(height: 6),
              Text(
                intl.DateFormat('d/M - h:mm a').format(message.createdAt),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF2E5AAC) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  message.senderName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              Text(
                message.text,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                intl.DateFormat('h:mm a').format(message.createdAt),
                style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
