import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';

class ChatColors {
  static const primary = Color(0xFF0062E6);
  static const background = Color(0xFFF4F7FC);
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
}

class ChatHubScreen extends StatelessWidget {
  final AppUser user;

  const ChatHubScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: ChatColors.background,
        appBar: AppBar(
          title: const Text('مركـز الرسـائل', style: TextStyle(color: ChatColors.textDark, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: ChatColors.primary,
            unselectedLabelColor: ChatColors.textMuted,
            indicatorColor: ChatColors.primary,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(icon: Icon(Icons.campaign_outlined), text: 'الشات العام (الإعلانات)'),
              Tab(icon: Icon(Icons.forum_outlined), text: 'المحادثات الخاصة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GeneralChatTab(currentUser: user),
            _PrivateChatsTab(currentUser: user),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. الشات العام (إعلانات المعلم حسب المراحل)
// ==========================================
class _GeneralChatTab extends StatefulWidget {
  final AppUser currentUser;

  const _GeneralChatTab({required this.currentUser});

  @override
  State<_GeneralChatTab> createState() => _GeneralChatTabState();
}

class _GeneralChatTabState extends State<_GeneralChatTab> {
  final TextEditingController _msgController = TextEditingController();
  String _selectedTargetStage = 'جميع المراحل';

  final List<String> _stagesList = [
    'جميع المراحل',
    'الصف الأول الابتدائي', 'الصف الثاني الابتدائي', 'الصف الثالث الابتدائي',
    'الصف الرابع الابتدائي', 'الصف الخامس الابتدائي', 'الصف السادس الابتدائي',
    'الصف الأول الإعدادي', 'الصف الثاني الإعدادي', 'الصف الثالث الإعدادي',
    'الصف الأول الثانوي', 'الصف الثاني الثانوي', 'الصف الثالث الثانوي',
  ];

  String get _targetTeacherUid {
    if (widget.currentUser.role == 'teacher') {
      return widget.currentUser.uid;
    }
    return widget.currentUser.linkedTeacherUid ?? '';
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final targetStage = _selectedTargetStage;
    _msgController.clear();

    await FirebaseFirestore.instance.collection('general_chats').add({
      'teacherUid': widget.currentUser.uid,
      'senderUid': widget.currentUser.uid,
      'senderName': widget.currentUser.name,
      'text': text,
      'targetStage': targetStage,
      'createdAt': FieldValue.serverTimestamp(),
      'deletedFor': [],
    });
  }

  void _showOptionsModal(BuildContext context, String docId, String text, Map<String, dynamic> msgData) {
    final isTeacher = widget.currentUser.role == 'teacher';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: ChatColors.primary),
              title: const Text('نسخ الرسالة'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص 📋')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('حذف من عندي فقط'),
              onTap: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('general_chats').doc(docId).update({
                  'deletedFor': FieldValue.arrayUnion([widget.currentUser.uid]),
                });
              },
            ),
            if (isTeacher)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('حذف عند الجميع (إلغاء الإعلان)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance.collection('general_chats').doc(docId).delete();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTeacher = widget.currentUser.role == 'teacher';
    final String teacherUid = _targetTeacherUid;

    if (teacherUid.isEmpty && !isTeacher) {
      return const Center(child: Text('لم تقم بالانضمام لأي معلم بعد لرؤية الشات العام'));
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('general_chats')
                .where('teacherUid', isEqualTo: teacherUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: ChatColors.primary));
              }

              final docs = snapshot.data?.docs ?? [];

              // تصفية الرسائل المحذوفة والفلترة حسب مرحلة الطالب
              final filteredDocs = docs.where((doc) {
                final raw = doc.data();
                if (raw is! Map) return false;

                final Map<String, dynamic> data = raw.cast<String, dynamic>();

                // فحص الحذف
                final deletedFor = List<String>.from(data['deletedFor'] ?? []);
                if (deletedFor.contains(widget.currentUser.uid)) {
                  return false;
                }

                // فحص المرحلة للطالب
                if (!isTeacher) {
                  final targetStage = data['targetStage']?.toString() ?? 'جميع المراحل';
                  if (targetStage != 'جميع المراحل' && targetStage != widget.currentUser.stage) {
                    return false; // لا يظهر للطالب إذا كان الإعلان لمرحلة أخرى
                  }
                }

                return true;
              }).toList();

              // ترتيب الرسائل زمنياً
              filteredDocs.sort((a, b) {
                final aRaw = a.data();
                final bRaw = b.data();
                final aTime = (aRaw is Map) ? aRaw['createdAt'] as Timestamp? : null;
                final bTime = (bRaw is Map) ? bRaw['createdAt'] as Timestamp? : null;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              if (filteredDocs.isEmpty) {
                return const Center(child: Text('لا توجد إعلانات عامة في القناة حتى الآن', style: TextStyle(color: ChatColors.textMuted)));
              }

              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final raw = doc.data();
                  final Map<String, dynamic> data = (raw is Map) ? raw.cast<String, dynamic>() : {};
                  final msgText = data['text']?.toString() ?? '';
                  final senderName = data['senderName']?.toString() ?? 'المعلم';
                  final targetStage = data['targetStage']?.toString() ?? 'جميع المراحل';

                  return GestureDetector(
                    onLongPress: () => _showOptionsModal(context, doc.id, msgText, data),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ChatColors.primary.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 12,
                                backgroundColor: ChatColors.primary,
                                child: Icon(Icons.campaign, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Text(senderName, style: const TextStyle(fontWeight: FontWeight.bold, color: ChatColors.primary, fontSize: 13)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: targetStage == 'جميع المراحل' ? const Color(0xFFF1F5F9) : const Color(0xFFE0E7FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'موجه إلى: $targetStage',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: targetStage == 'جميع المراحل' ? const Color(0xFF64748B) : ChatColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(msgText, style: const TextStyle(fontSize: 14, color: ChatColors.textDark, height: 1.4)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // مربع إرسال الرسائل واختيار المرحلة (يظهر للمعلم فقط)
        if (isTeacher)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // القائمة المنسدلة لاختيار المرحلة المستهدفة
                Row(
                  children: [
                    const Text('المرحلة المستهدفة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: ChatColors.textDark)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTargetStage,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 12, color: ChatColors.textDark, fontWeight: FontWeight.bold),
                            items: _stagesList.map((stage) {
                              return DropdownMenuItem(
                                value: stage,
                                child: Text(stage),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTargetStage = val);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // حقل كتابة الرسالة وزر الإرسال
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        decoration: InputDecoration(
                          hintText: 'اكتب إعلاناً لـ ($_selectedTargetStage)...',
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: ChatColors.primary,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade50,
            child: const Text(
              '🔒 القناة العامة مخصصة لإعلانات ونشرات المعلم فقط.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

// ==========================================
// 2. تبويب المحادثات الخاصة
// ==========================================
class _PrivateChatsTab extends StatelessWidget {
  final AppUser currentUser;

  const _PrivateChatsTab({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    if (currentUser.role == 'teacher') {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('linkedTeacherUid', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: ChatColors.primary));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('لا يوجد طلاب مضافين لبدء محادثة خاصة'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final raw = doc.data();
              final Map<String, dynamic> data = (raw is Map) ? raw.cast<String, dynamic>() : {};
              final studentName = data['name']?.toString() ?? 'طالب';
              final studentStage = data['stage']?.toString() ?? 'غير محدد';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0E7FF),
                    child: Icon(Icons.person, color: ChatColors.primary),
                  ),
                  title: Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(studentStage),
                  trailing: const Icon(Icons.chat_bubble_outline, color: ChatColors.primary),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivateChatDetailScreen(
                          currentUser: currentUser,
                          otherUserUid: doc.id,
                          otherUserName: studentName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    } else {
      final teacherUid = currentUser.linkedTeacherUid ?? '';

      if (teacherUid.isEmpty) {
        return const Center(child: Text('يجب عليك الانضمام لمعلم أولاً عبر الكود'));
      }

      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(teacherUid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: ChatColors.primary));
          }

          final raw = snapshot.data?.data();
          final Map<String, dynamic> teacherData = (raw is Map) ? raw.cast<String, dynamic>() : {};
          final teacherName = teacherData['name']?.toString() ?? 'المعلم';

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: ChatColors.primary,
                  child: Icon(Icons.school, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text('المعلم: $teacherName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('تواصل بشكل مباشر مع معلمك لطرح الاستفسارات والأسئلة.', textAlign: TextAlign.center, style: TextStyle(color: ChatColors.textMuted)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PrivateChatDetailScreen(
                          currentUser: currentUser,
                          otherUserUid: teacherUid,
                          otherUserName: teacherName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('فتح المحادثة الخاصة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChatColors.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}

// ==========================================
// 3. شاشة المحادثة الخاصة (طالب ↔ معلم)
// ==========================================
class PrivateChatDetailScreen extends StatefulWidget {
  final AppUser currentUser;
  final String otherUserUid;
  final String otherUserName;

  const PrivateChatDetailScreen({
    super.key,
    required this.currentUser,
    required this.otherUserUid,
    required this.otherUserName,
  });

  @override
  State<PrivateChatDetailScreen> createState() => _PrivateChatDetailScreenState();
}

class _PrivateChatDetailScreenState extends State<PrivateChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();

  String get _chatId {
    final uids = [widget.currentUser.uid, widget.otherUserUid]..sort();
    return uids.join('_');
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    await FirebaseFirestore.instance.collection('private_chats').add({
      'chatId': _chatId,
      'senderUid': widget.currentUser.uid,
      'receiverUid': widget.otherUserUid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'deletedFor': [],
    });
  }

  void _showOptionsModal(BuildContext context, String docId, String text) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: ChatColors.primary),
              title: const Text('نسخ الرسالة'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص 📋')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('حذف من عندي فقط'),
              onTap: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('private_chats').doc(docId).update({
                  'deletedFor': FieldValue.arrayUnion([widget.currentUser.uid]),
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('حذف عند الجميع (للجميع)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('private_chats').doc(docId).delete();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatColors.background,
      appBar: AppBar(
        title: Text(widget.otherUserName, style: const TextStyle(color: ChatColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: ChatColors.textDark,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('private_chats')
                  .where('chatId', isEqualTo: _chatId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: ChatColors.primary));
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((doc) {
                  final raw = doc.data();
                  if (raw is Map) {
                    final deletedFor = List<String>.from(raw['deletedFor'] ?? []);
                    return !deletedFor.contains(widget.currentUser.uid);
                  }
                  return true;
                }).toList();

                filteredDocs.sort((a, b) {
                  final aRaw = a.data();
                  final bRaw = b.data();
                  final aTime = (aRaw is Map) ? aRaw['createdAt'] as Timestamp? : null;
                  final bTime = (bRaw is Map) ? bRaw['createdAt'] as Timestamp? : null;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('لا توجد رسائل بينكما حتى الآن. ابدأ المحادثة!', style: TextStyle(color: ChatColors.textMuted)));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final raw = doc.data();
                    final Map<String, dynamic> data = (raw is Map) ? raw.cast<String, dynamic>() : {};
                    final msgText = data['text']?.toString() ?? '';
                    final isMe = data['senderUid'] == widget.currentUser.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: GestureDetector(
                        onLongPress: () => _showOptionsModal(context, doc.id, msgText),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isMe ? ChatColors.primary : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 0 : 16),
                              bottomRight: Radius.circular(isMe ? 16 : 0),
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                          ),
                          child: Text(
                            msgText,
                            style: TextStyle(
                              color: isMe ? Colors.white : ChatColors.textDark,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // مربع إرسال الرسائل
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك هنا...',
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: ChatColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
