import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementMessage {
  final String id;
  final String chatId;
  final String text;
  final String senderName;
  final String senderId;
  final bool isAnnouncement;
  final String? stage;
  final DateTime createdAt;

  AnnouncementMessage({
    required this.id,
    required this.chatId,
    required this.text,
    required this.senderName,
    required this.senderId,
    required this.isAnnouncement,
    this.stage,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'text': text,
      'senderName': senderName,
      'senderId': senderId,
      'isAnnouncement': isAnnouncement,
      'stage': stage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AnnouncementMessage.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final createdAt = map['createdAt'];

    DateTime date = DateTime.now();

    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    }

    return AnnouncementMessage(
      id: id,
      chatId: map['chatId']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      isAnnouncement: map['isAnnouncement'] == true,
      stage: map['stage']?.toString(),
      createdAt: date,
    );
  }
}
