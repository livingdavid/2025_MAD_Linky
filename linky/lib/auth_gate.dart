// 상태변경 설정 페이지
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          return HomePage(
            userName: user.isAnonymous ? '익명 사용자' : user.displayName ?? '사용자',
            email: user.isAnonymous ? '' : user.email ?? '',
            photoUrl: user.isAnonymous ? null : user.photoURL,
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
