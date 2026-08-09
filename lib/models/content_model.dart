import 'package:cloud_firestore/cloud_firestore.dart';

class ContentItem {
  final String id;
  final String title;
  final String description;
  final String type; // "file", "image", "video"
  final String url;
  final String uploadedBy; // اسم المدرس
  final String teacherId;
  final DateTime createdAt;

  ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required this.uploadedBy,
    required this.teacherId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'url': url,
      'uploadedBy': uploadedBy,
      'teacherId': teacherId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ContentItem.fromMap(String id, Map<String, dynamic> map) {
    return ContentItem(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'file',
      url: map['url'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      teacherId: map['teacherId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
