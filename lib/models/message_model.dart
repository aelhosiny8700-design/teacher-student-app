import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementMessage {
  final String id;
  final String text;
  final String senderName;
  final String senderId;
  final bool isAnnouncement; // true = تنبيه عام من المدرس
  final DateTime createdAt;

  AnnouncementMessage({
    required this.id,
    required this.text,
    required this.senderName,
    required this.senderId,
    required this.isAnnouncement,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderName': senderName,
      'senderId': senderId,
      'isAnnouncement': isAnnouncement,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AnnouncementMessage.fromMap(String id, Map<String, dynamic> map) {
    return AnnouncementMessage(
      id: id,
      text: map['text'] ?? '',
      senderName: map['senderName'] ?? '',
      senderId: map['senderId'] ?? '',
      isAnnouncement: map['isAnnouncement'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
