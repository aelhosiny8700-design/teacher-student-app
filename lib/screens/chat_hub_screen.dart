import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

class ChatHubScreen extends StatelessWidget {
  final AppUser user;

  const ChatHubScreen({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرسائل'),
        backgroundColor:
            const Color(0xFF2E5AAC),
        foregroundColor: Colors.white,
      ),
      body: user.isTeacher
          ? _TeacherChats(user: user)
          : _StudentChats(user: user),
    );
  }
}

// ============================================================
// الطالب
// ============================================================

class _StudentChats extends StatelessWidget {
  final AppUser user;

  const _StudentChats({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final stage = user.stage;
    final teacherUid = user.linkedTeacherUid;

    if (stage == null ||
        stage.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'لم يتم تحديد المرحلة الدراسية لحسابك',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (teacherUid == null || teacherUid.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'لا يوجد معلم مرتبط بحسابك حاليًا',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'الشات العام',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        _ChatCard(
          icon: Icons.groups,
          title: 'شات $stage',
          subtitle:
              'المحادثة العامة لطلاب $stage',
          color:
              const Color(0xFF2E5AAC),
          onTap: () {
            final chatId =
                FirestoreService
                    .buildGeneralChatId(
              teacherUid,
              stage,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ChatScreen(
                  user: user,
                  chatId: chatId,
                  title: 'شات $stage',
                  isGeneral: true,
                  stage: stage,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 28),

        const Text(
          'الشات الخاص',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        StreamBuilder<List<AppUser>>(
          stream: FirestoreService()
              .getLinkedTeacherStream(teacherUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
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

            final teachers =
                snapshot.data ?? [];

            if (teachers.isEmpty) {
              return const _EmptyCard(
                text:
                    'لا يوجد مدرسون متاحون حاليًا',
              );
            }

            return Column(
              children: teachers.map(
                (teacher) {
                  final chatId =
                      FirestoreService
                          .buildPrivateChatId(
                    user.uid,
                    teacher.uid,
                  );

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: _ChatCard(
                      icon:
                          Icons.person,
                      title:
                          'مستر ${teacher.name}',
                      subtitle:
                          'محادثة خاصة مع المدرس',
                      color:
                          const Color(
                        0xFF43A047,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(
                              user: user,
                              chatId: chatId,
                              title:
                                  'مستر ${teacher.name}',
                              isGeneral: false,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// المدرس
// ============================================================

class _TeacherChats extends StatelessWidget {
  final AppUser user;

  const _TeacherChats({
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        const Text(
          'الشات العام للمراحل',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        ...FirestoreService.stages.map(
          (stage) {
            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: _ChatCard(
                icon: Icons.groups,
                title: 'شات $stage',
                subtitle:
                    'الشات العام للمرحلة',
                color:
                    const Color(0xFF2E5AAC),
                onTap: () {
                  final chatId =
                      FirestoreService
                          .buildGeneralChatId(
                    user.uid,
                    stage,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(
                        user: user,
                        chatId: chatId,
                        title:
                            'شات $stage',
                        isGeneral: true,
                        stage: stage,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 18),

        const Text(
          'الشات الخاص بالطلاب',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        StreamBuilder<List<AppUser>>(
          stream: FirestoreService()
              .getStudentsStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Text(
                'حدث خطأ: ${snapshot.error}',
              );
            }

            final students =
                snapshot.data ?? [];

            if (students.isEmpty) {
              return const _EmptyCard(
                text:
                    'لا يوجد طلاب مسجلون',
              );
            }

            return Column(
              children: students.map(
                (student) {
                  final chatId =
                      FirestoreService
                          .buildPrivateChatId(
                    user.uid,
                    student.uid,
                  );

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: _ChatCard(
                      icon:
                          Icons.person,
                      title:
                          student.name,
                      subtitle:
                          student.stage ??
                              'مرحلة غير محددة',
                      color:
                          const Color(
                        0xFF43A047,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(
                              user: user,
                              chatId: chatId,
                              title:
                                  student.name,
                              isGeneral: false,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// كارت
// ============================================================

class _ChatCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration:
                    BoxDecoration(
                  color:
                      color.withOpacity(
                    0.12,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .arrow_forward_ios,
                size: 16,
                color:
                    Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard
    extends StatelessWidget {
  final String text;

  const _EmptyCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          style:
              const TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}


