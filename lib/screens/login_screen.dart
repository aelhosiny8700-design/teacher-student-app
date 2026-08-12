import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'student_home.dart';
import 'teacher_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _teacherCodeController = TextEditingController();

  bool _isSignUp = false;

  String _role = 'student';

  String? _stage;

  bool _loading = false;

  String? _error;
  String? _info; // رسائل نجاح غير خطأ (زي "حسابك قيد المراجعة")

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSignUp && _role == 'student' && (_stage == null || _stage!.isEmpty)) {
      setState(() {
        _error = 'اختار المرحلة الدراسية';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    String? error;

    if (_isSignUp) {
      error = await _authService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _role,
        stage: _role == 'student' ? _stage : null,
        teacherCode: _role == 'student' ? _teacherCodeController.text.trim() : null,
      );
// لو التسجيل نجح لكن الطالب معلق، signUp بترجع رسالة نجاح مش خطأ حقيقي
      if (error != null && error.contains('تم إنشاء حسابك بنجاح')) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _info = error;
          _error = null;
          _isSignUp = false;
        });
        // دلوقتي، وبعد ما الرسالة اتعرضت فعلاً على الشاشة (setState اتنفذت)،
        // نعمل signOut. بكده الرسالة مضمون ظهورها قبل أي rebuild
        // ناتج عن تغيّر حالة تسجيل الدخول.
        await _authService.signOut();
        return;
      }
    } else {
      error = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }

    if (!mounted) {
      return;
    }

    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    final uid = _authService.currentUser?.uid;

    if (uid == null) {
      setState(() {
        _loading = false;
        _error = 'حصل خطأ غير متوقع، حاول تاني';
      });
      return;
    }

    final userData = await _authService.getUserData(uid);

    if (!mounted) {
      return;
    }

    if (userData == null) {
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل بيانات المستخدم';
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => userData.isTeacher
            ? TeacherHome(user: userData)
            : StudentHome(user: userData),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    final dialogFormKey = GlobalKey<FormState>();
    bool sending = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('نسيت كلمة السر'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'اكتب إيميلك، وهيتبعتلك رابط لإعادة تعيين كلمة السر.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || !v.contains('@')
                          ? 'إيميل غير صحيح'
                          : null,
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending ? null : () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            sending = true;
                            dialogError = null;
                          });

                          final error = await _authService
                              .sendPasswordResetEmail(
                                  resetEmailController.text.trim());

                          if (error != null) {
                            setDialogState(() {
                              sending = false;
                              dialogError = error;
                            });
                            return;
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تم إرسال رابط إعادة التعيين، افحص بريدك الإلكتروني',
                                ),
                              ),
                            );
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('إرسال'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _teacherCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.school,
                    size: 72,
                    color: Color(0xFF2E5AAC),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _isSignUp ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'اكتب اسمك' : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'إيميل غير صحيح' : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'كلمة السر',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.length < 6
                        ? 'كلمة السر 6 حروف على الأقل'
                        : null,
                  ),

                  if (!_isSignUp) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _loading ? null : _showForgotPasswordDialog,
                        child: const Text('نسيت كلمة السر؟'),
                      ),
                    ),
                  ],

                  if (_isSignUp) ...[
                    const SizedBox(height: 16),

                    const Text(
                      'نوع الحساب',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('طالب'),
                            value: 'student',
                            groupValue: _role,
                            onChanged: (value) {
                              setState(() {
                                _role = value!;
                                _stage = null;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('مدرس'),
                            value: 'teacher',
                            groupValue: _role,
                            onChanged: (value) {
                              setState(() {
                                _role = value!;
                                _stage = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    if (_role == 'student') ...[
                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        value: _stage,
                        decoration: const InputDecoration(
                          labelText: 'المرحلة الدراسية',
                          border: OutlineInputBorder(),
                        ),
                        items: FirestoreService.stages.map((stage) {
                          return DropdownMenuItem<String>(
                            value: stage,
                            child: Text(stage),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _stage = value;
                          });
                        },
                        validator: (value) {
                          if (_role == 'student' &&
                              (value == null || value.isEmpty)) {
                            return 'اختار المرحلة';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _teacherCodeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'كود المعلم',
                          hintText: 'اطلبه من المدرس بتاعك',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key),
                        ),
                        validator: (v) {
                          if (_role == 'student' &&
                              (v == null || v.trim().isEmpty)) {
                            return 'أدخل كود المعلم';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  if (_info != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _info!,
                        style: const TextStyle(color: Color(0xFF2E7D32)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2E5AAC),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isSignUp ? 'إنشاء الحساب' : 'دخول',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _error = null;
                        _info = null;
                      });
                    },
                    child: Text(
                      _isSignUp ? 'عندك حساب؟ سجل دخول' : 'مفيش حساب؟ اعمل واحد جديد',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


