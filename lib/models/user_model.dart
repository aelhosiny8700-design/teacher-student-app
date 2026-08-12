class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // teacher / student
  final String? classId;
  final String? stage;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
    this.stage,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'classId': classId,
      'stage': stage,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'student',
      classId: map['classId']?.toString(),
      stage: map['stage']?.toString(),
    );
  }

  bool get isTeacher => role == 'teacher';
}
