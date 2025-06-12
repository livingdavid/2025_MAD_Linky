import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home.dart'; // HomePage가 정의된 파일을 정확히 import

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<User?> _signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Google 로그인 에러: $e");
      return null;
    }
  }

  Future<User?> _signInAnonymously() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      debugPrint("익명 로그인 에러: $e");
      return null;
    }
  }

  void _navigateToHome(BuildContext context, User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => HomePage(
              userName: user.isAnonymous ? '익명 사용자' : user.displayName ?? '사용자',
              email: user.isAnonymous ? '' : user.email ?? '',
              photoUrl: user.isAnonymous ? null : user.photoURL,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                final user = await _signInWithGoogle();
                if (user != null) {
                  _navigateToHome(context, user);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google 로그인 실패')),
                  );
                }
              },
              child: const Text('Google 로그인'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final user = await _signInAnonymously();
                if (user != null) {
                  _navigateToHome(context, user);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('익명 로그인 실패')));
                }
              },
              child: const Text('익명 로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
