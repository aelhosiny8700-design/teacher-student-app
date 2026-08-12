import 'package:flutter/material.dart';
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
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  final _controller =
      TextEditingController();

  final _scrollController =
      ScrollController();

  final _service =
      FirestoreService();

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text =
        _controller.text.trim();

    if (text.isEmpty ||
        _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final message =
          AnnouncementMessage(
        id: '',
        chatId: widget.chatId,
        text: text,
        senderName:
            widget.user.name,
        senderId:
            widget.user.uid,
        isAnnouncement:
            widget.isGeneral &&
                widget.user.isTeacher,
        chatType:
            widget.isGeneral
                ? 'general'
                : 'private',
        stage: widget.stage,
        createdAt:
            DateTime.now(),
      );

      await _service
          .sendMessage(message);

      _controller.clear();

      if (!mounted) return;

      await Future.delayed(
        const Duration(
          milliseconds: 200,
        ),
      );

      if (_scrollController
          .hasClients) {
        await _scrollController
            .animateTo(
          _scrollController
              .position
              .maxScrollExtent,
          duration:
              const Duration(
            milliseconds: 250,
          ),
          curve:
              Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'فشل إرسال الرسالة: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor:
            const Color(0xFF2E5AAC),
        foregroundColor:
            Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                List<AnnouncementMessage>>(
              stream: _service
                  .getMessagesStream(
                widget.chatId,
              ),
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
                      'حدث خطأ في تحميل الرسائل\n${snapshot.error}',
                      textAlign:
                          TextAlign.center,
                    ),
                  );
                }

                final messages =
                    snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      widget.isGeneral
                          ? 'مفيش رسائل في شات المرحلة لسه'
                          : 'ابدأ المحادثة مع الطالب/المدرس',
                      style:
                          const TextStyle(
                        color:
                            Colors.grey,
                      ),
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
                          12),
                  itemCount:
                      messages.length,
                  itemBuilder:
                      (context, index) {
                    final msg =
                        messages[index];

                    final isMe =
                        msg.senderId ==
                            widget.user.uid;

                    return _buildBubble(
                      msg,
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
                    child:
                        TextField(
                      controller:
                          _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction:
                          TextInputAction
                              .send,
                      decoration:
                          InputDecoration(
                        hintText:
                            widget.isGeneral
                                ? 'اكتب رسالة للمرحلة...'
                                : 'اكتب رسالتك...',
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      24),
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
                            0xFF2E5AAC),
                    child:
                        IconButton(
                      icon: _sending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(
                                color: Colors
                                    .white,
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors
                                  .white,
                            ),
                      onPressed:
                          _sending
                              ? null
                              : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(
    AnnouncementMessage msg,
    bool isMe,
  ) {
    if (msg.isAnnouncement) {
      return Container(
        width: double.infinity,
        margin:
            const EdgeInsets.symmetric(
          vertical: 6,
        ),
        padding:
            const EdgeInsets.all(12),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFFFFF3CD),
          borderRadius:
              BorderRadius.circular(
                  10),
          border: Border.all(
            color:
                const Color(0xFFFFE69C),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.campaign,
                  size: 18,
                  color:
                      Color(0xFF856404),
                ),
                const SizedBox(
                    width: 6),
                Expanded(
                  child: Text(
                    'تنبيه من ${msg.senderName}',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF856404),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
                height: 6),

            Text(msg.text),

            const SizedBox(
                height: 4),

            Text(
              intl.DateFormat(
                'd/M - h:mm a',
              ).format(
                msg.createdAt,
              ),
              style:
                  const TextStyle(
                fontSize: 10,
                color:
                    Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

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
                  0.78,
        ),
        decoration:
            BoxDecoration(
          color: isMe
              ? const Color(
                  0xFF2E5AAC)
              : Colors.grey.shade200,
          borderRadius:
              BorderRadius.circular(
                  14),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            if (!isMe)
              Text(
                msg.senderName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors
                      .grey
                      .shade700,
                ),
              ),

            if (!isMe)
              const SizedBox(
                  height: 3),

            Text(
              msg.text,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : Colors.black87,
              ),
            ),

            const SizedBox(
                height: 3),

            Text(
              intl.DateFormat(
                'h:mm a',
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
