import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'chat_hub_screen.dart';
import 'content_list_screen.dart';
import 'quiz_list_screen.dart';

class StudentHome extends StatefulWidget {
  final AppUser user;

  const StudentHome({super.key, required this.user});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _newCodeController = TextEditingController();
  bool _isSubmittingCode = false;

  @override
  void dispose() {
    _newCodeController.dispose();
    super.dispose();
  }

  void _submitNewTeacherCode() async {
    final code = _newCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أدخل كود المعلم')),
      );
      return;
    }

    setState(() => _isSubmittingCode = true);

    try {
      final teacher = await _firestoreService.findTeacherByCode(code);
      if (teacher == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('كود المعلم غير صحيح، تأكد منه وحاول ثانياً'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isSubmittingCode = false);
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'linkedTeacherUid': teacher.uid,
        'status': 'pending',
      });

      _newCodeController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال طلب الانضمام للمعلم بنجاح! في انتظار الموافقة.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingCode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F7FC),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF0062E6))),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data?.data() == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F7FC),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('تعذر تحميل البيانات'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _authService.signOut(),
                    child: const Text('تسجيل الخروج'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final currentUserData = AppUser.fromMap(data);

        final String? teacherUid = currentUserData.linkedTeacherUid;
        final String status = currentUserData.status ?? 'approved';

        // 1. حالة إذا تم حذف الربط أو نقل الطالب للأرشيف
        if (teacherUid == null || teacherUid.isEmpty || status == 'archived') {
          return _buildLinkNewTeacherScreen(currentUserData);
        }

        // 2. حالة إذا كان الحساب قيد الانتظار لموافقة المعلم
        if (status == 'pending') {
          return _buildPendingScreen(currentUserData);
        }

        // 3. حالة الطالب المعتمد (Approved) - شاشة الطالب الطبيعية
        final pages = [
          ContentListScreen(user: currentUserData),
          QuizListScreen(user: currentUserData),
          ChatHubScreen(user: currentUserData),
          _buildProfileTab(currentUserData),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF4F7FC),
          body: SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF0062E6),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_rounded),
                  label: 'المحتوى',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.assignment_rounded),
                  label: 'الاختبارات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.forum_rounded),
                  label: 'المحادثات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'حسابي',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLinkNewTeacherScreen(AppUser user) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('ربط حساب المعلم', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0062E6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'تسجيل الخروج',
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0062E6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, size: 48, color: Color(0xFF0062E6)),
                ),
                const SizedBox(height: 16),
                Text(
                  'أهلاً بك يا ${user.name}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أنت غير مربوط بأي معلم حالياً. أدخل كود المعلم الجديد للانضمام لمجموعته ومتابعة الدروس.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _newCodeController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'أدخل كود المعلم هنا',
                    prefixIcon: const Icon(Icons.vpn_key_rounded, color: Color(0xFF0062E6)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0062E6), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmittingCode ? null : _submitNewTeacherCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0062E6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmittingCode
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('إرسال الطلب', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingScreen(AppUser user) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('طلب الانضمام', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0062E6),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'تسجيل الخروج',
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 64, color: Colors.amber),
              ),
              const SizedBox(height: 20),
              const Text(
                'طلبك قيد المراجعة',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 10),
              Text(
                'تم إرسال طلب انضمامك إلى المعلم بنجاح.\nسيتم تفعيل حسابك فور قبول المعلم للطلب.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(AppUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF0062E6).withOpacity(0.12),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF0062E6), size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.stage ?? 'الصف الدراسي غير محدد',
                        style: const TextStyle(color: Color(0xFF0062E6), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF0062E6)),
                  title: const Text('تغيير المعلم'),
                  subtitle: const Text('إدخال كود معلم آخر والانتقال إليه', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('تغيير المعلم'),
                        content: const Text('هل تريد فك الارتباط بالمعلم الحالي لإدخال كود معلم جديد؟'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0062E6)),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('نعم', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'linkedTeacherUid': null,
                        'status': 'approved',
                      });
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent)),
                  onTap: () => _authService.signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
