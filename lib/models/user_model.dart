class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // teacher / student
  final String? classId;
  final String? stage;
  final String? parentPhone; // رقم ولي الأمر

  // نظام تعدد المعلمين
  final String? teacherCode;
  final String? linkedTeacherUid;
  final String status; // approved / pending / rejected

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.classId,
    this.stage,
    this.parentPhone,
    this.teacherCode,
    this.linkedTeacherUid,
    this.status = 'approved',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'classId': classId,
      'stage': stage,
      'parentPhone': parentPhone,
      'teacherCode': teacherCode,
      'linkedTeacherUid': linkedTeacherUid,
      'status': status,
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
      parentPhone: map['parentPhone']?.toString(),
      teacherCode: map['teacherCode']?.toString(),
      linkedTeacherUid: map['linkedTeacherUid']?.toString(),
      status: map['status']?.toString() ?? 'approved',
    );
  }

  bool get isTeacher => role == 'teacher';
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
}
