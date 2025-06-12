// auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart'; // ← LoginPage 정의된 파일
import 'home.dart';

class AuthGate extends StatelessWidget {
  final String? initialLink;
  const AuthGate({super.key, this.initialLink});

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
            initialLink: initialLink,
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
