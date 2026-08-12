import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final AppUser user;

  final AppUser? otherUser;

  final String? classId;

  const ChatScreen({
    super.key,
    required this.user,
    this.otherUser,
    this.classId,
  });

  bool get isPrivateChat =>
      otherUser != null;

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  final _controller =
      TextEditingController();

  final _service =
      FirestoreService();

  final _scrollController =
      ScrollController();

  Future<void> _sendMessage() async {
    final text =
        _controller.text.trim();

    if (text.isEmpty) return;

    try {
      if (widget.isPrivateChat) {
        await _service.sendPrivateMessage(
          currentUid:
              widget.user.uid,
          otherUid:
              widget.otherUser!.uid,
          senderName:
              widget.user.name,
          text: text,
        );
      } else {
        final classId =
            widget.classId ??
            widget.user.classId;

        if (classId == null ||
            classId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              const SnackBar(
                content: Text(
                  'لم يتم تحديد الصف الدراسي',
                ),
              ),
            );
          }

          return;
        }

        await _service.sendClassMessage(
          classId: classId,
          text: text,
          senderId:
              widget.user.uid,
          senderName:
              widget.user.name,
        );
      }

      _controller.clear();

      Future.delayed(
        const Duration(
          milliseconds: 300,
        ),
        () {
          if (_scrollController
              .hasClients) {
            _scrollController.animateTo(
              _scrollController
                  .position
                  .maxScrollExtent,
              duration:
                  const Duration(
                milliseconds: 300,
              ),
              curve:
                  Curves.easeOut,
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: $e',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final privateChat =
        widget.isPrivateChat;

    final classId =
        widget.classId ??
        widget.user.classId;

    if (!privateChat &&
        (classId == null ||
            classId.isEmpty)) {
      return const Center(
        child: Text(
          'لم يتم تحديد الصف الدراسي لهذا الحساب',
        ),
      );
    }

    final Stream<
            List<AnnouncementMessage>>
        messageStream = privateChat
            ? _service
                .getPrivateMessagesStream(
                widget.user.uid,
                widget.otherUser!.uid,
              )
            : _service
                .getClassMessagesStream(
                classId!,
              );

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<
              List<AnnouncementMessage>>(
            stream: messageStream,
            builder:
                (context, snapshot) {
              if (snapshot
                      .connectionState ==
                  ConnectionState
                      .waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'حدث خطأ: ${snapshot.error}',
                  ),
                );
              }

              final messages =
                  snapshot.data ?? [];

              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    privateChat
                        ? 'ابدأ المحادثة'
                        : 'مفيش رسائل في الشات لسه',
                  ),
                );
              }

              WidgetsBinding
                  .instance
                  .addPostFrameCallback(
                (_) {
                  if (_scrollController
                      .hasClients) {
                    _scrollController
                        .jumpTo(
                      _scrollController
                          .position
                          .maxScrollExtent,
                    );
                  }
                },
              );

              return ListView.builder(
                controller:
                    _scrollController,
                padding:
                    const EdgeInsets.all(
                  12,
                ),
                itemCount:
                    messages.length,
                itemBuilder:
                    (context, index) {
                  final message =
                      messages[index];

                  final isMe =
                      message.senderId ==
                          widget.user.uid;

                  return _buildBubble(
                    message,
                    isMe,
                  );
                },
              );
            },
          ),
        ),

        SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _controller,
                    decoration:
                        InputDecoration(
                      hintText: privateChat
                          ? 'اكتب رسالتك...'
                          : 'اكتب رسالة للصف...',
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          24,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted:
                        (_) =>
                            _sendMessage(),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                CircleAvatar(
                  backgroundColor:
                      const Color(
                    0xFF2E5AAC,
                  ),
                  child: IconButton(
                    icon:
                        const Icon(
                      Icons.send,
                      color:
                          Colors.white,
                    ),
                    onPressed:
                        _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(
    AnnouncementMessage msg,
    bool isMe,
  ) {
    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin:
            const EdgeInsets.symmetric(
          vertical: 4,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  0.75,
        ),
        decoration:
            BoxDecoration(
          color: isMe
              ? const Color(
                  0xFF2E5AAC,
                )
              : Colors.grey.shade200,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                msg.senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Colors.grey.shade700,
                ),
              ),

            Text(
              msg.text,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : Colors.black87,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              intl.DateFormat(
                'd/M - h:mm a',
              ).format(
                msg.createdAt,
              ),
              style: TextStyle(
                fontSize: 9,
                color: isMe
                    ? Colors.white70
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
