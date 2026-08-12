class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // teacher أو student
  final String? stage; // المرحلة الدراسية

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.stage,
  });

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'stage': stage,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'student',
      stage: map['stage']?.toString(),
    );
  }
}
