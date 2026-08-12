import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'student_home.dart';
import 'teacher_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final _authService =
      AuthService();

  final _formKey =
      GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  bool _isSignUp = false;

  String _role = 'student';

  String? _stage;

  bool _loading = false;

  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (_isSignUp &&
        _role == 'student' &&
        (_stage == null ||
            _stage!.isEmpty)) {
      setState(() {
        _error =
            'اختار المرحلة الدراسية';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    String? error;

    if (_isSignUp) {
      error =
          await _authService.signUp(
        name:
            _nameController.text
                .trim(),
        email:
            _emailController.text
                .trim(),
        password:
            _passwordController.text
                .trim(),
        role: _role,
        stage: _role == 'student'
            ? _stage
            : null,
      );
    } else {
      error =
          await _authService.signIn(
        email:
            _emailController.text
                .trim(),
        password:
            _passwordController.text
                .trim(),
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

    final uid =
        _authService
            .currentUser
            ?.uid;

    if (uid == null) {
      setState(() {
        _loading = false;
        _error =
            'حصل خطأ غير متوقع، حاول تاني';
      });
      return;
    }

    final userData =
        await _authService
            .getUserData(uid);

    if (!mounted) {
      return;
    }

    if (userData == null) {
      setState(() {
        _loading = false;
        _error =
            'تعذر تحميل بيانات المستخدم';
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            userData.isTeacher
                ? TeacherHome(
                    user: userData,
                  )
                : StudentHome(
                    user: userData,
                  ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                children: [
                  const Icon(
                    Icons.school,
                    size: 72,
                    color:
                        Color(0xFF2E5AAC),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    _isSignUp
                        ? 'إنشاء حساب جديد'
                        : 'تسجيل الدخول',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  if (_isSignUp) ...[
                    TextFormField(
                      controller:
                          _nameController,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'الاسم',
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null ||
                                  v.trim()
                                      .isEmpty
                              ? 'اكتب اسمك'
                              : null,
                    ),

                    const SizedBox(
                      height: 12,
                    ),
                  ],

                  TextFormField(
                    controller:
                        _emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'البريد الإلكتروني',
                      border:
                          OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null ||
                                !v.contains(
                                  '@',
                                )
                            ? 'إيميل غير صحيح'
                            : null,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextFormField(
                    controller:
                        _passwordController,
                    obscureText:
                        true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'كلمة السر',
                      border:
                          OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null ||
                                v.length <
                                    6
                            ? 'كلمة السر 6 حروف على الأقل'
                            : null,
                  ),

                  if (_isSignUp) ...[
                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      'نوع الحساب',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child:
                              RadioListTile<
                                  String>(
                            title:
                                const Text(
                              'طالب',
                            ),
                            value:
                                'student',
                            groupValue:
                                _role,
                            onChanged:
                                (value) {
                              setState(() {
                                _role =
                                    value!;
                                _stage =
                                    null;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child:
                              RadioListTile<
                                  String>(
                            title:
                                const Text(
                              'مدرس',
                            ),
                            value:
                                'teacher',
                            groupValue:
                                _role,
                            onChanged:
                                (value) {
                              setState(() {
                                _role =
                                    value!;
                                _stage =
                                    null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    if (_role ==
                        'student') ...[
                      const SizedBox(
                        height: 8,
                      ),

                      DropdownButtonFormField<
                          String>(
                        value: _stage,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'المرحلة الدراسية',
                          border:
                              OutlineInputBorder(),
                        ),
                        items:
                            FirestoreService
                                .stages
                                .map(
                          (stage) {
                            return DropdownMenuItem<
                                String>(
                              value:
                                  stage,
                              child:
                                  Text(
                                stage,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            (value) {
                          setState(() {
                            _stage =
                                value;
                          });
                        },
                        validator:
                            (value) {
                          if (_role ==
                                  'student' &&
                              (value ==
                                      null ||
                                  value
                                      .isEmpty)) {
                            return 'اختار المرحلة';
                          }

                          return null;
                        },
                      ),
                    ],
                  ],

                  if (_error != null) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      _error!,
                      style:
                          const TextStyle(
                        color:
                            Colors.red,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 20,
                  ),

                  ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : _submit,
                    style:
                        ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 16,
                      ),
                      backgroundColor:
                          const Color(
                        0xFF2E5AAC,
                      ),
                    ),
                    child:
                        _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      Colors.white,
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : Text(
                                _isSignUp
                                    ? 'إنشاء الحساب'
                                    : 'دخول',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      16,
                                  color:
                                      Colors.white,
                                ),
                              ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp =
                            !_isSignUp;
                        _error =
                            null;
                      });
                    },
                    child: Text(
                      _isSignUp
                          ? 'عندك حساب؟ سجل دخول'
                          : 'مفيش حساب؟ اعمل واحد جديد',
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
