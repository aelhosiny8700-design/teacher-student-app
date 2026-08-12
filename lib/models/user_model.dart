class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? classId;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
  });

  bool get isTeacher => role == 'teacher';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'classId': classId,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      classId: map['classId'],
    );
  }
}
