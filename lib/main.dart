import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/teacher_home.dart';
import 'screens/student_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق المدرسين والطلبة',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        primaryColor: const Color(0xFF0062E6),
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0062E6)),
        textTheme: GoogleFonts.tajawalTextTheme(Theme.of(context).textTheme),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF0062E6))),
          );
        }

        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        return FutureBuilder<AppUser?>(
          future: authService.getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Color(0xFF0062E6))),
              );
            }

            final appUser = userSnapshot.data;
            if (appUser == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('حصل خطأ')),
                body: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      const Text(
                        'تعذر تحميل بيانات المستخدم',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        AuthService.lastError ?? 'لا توجد تفاصيل إضافية',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('تسجيل الخروج والمحاولة تاني'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return appUser.isTeacher
                ? TeacherHome(user: appUser)
                : StudentHome(user: appUser);
          },
        );
      },
    );
  }
}
