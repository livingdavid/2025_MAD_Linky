// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'home.dart'; // 이 파일 import 필요

// class LoginPage extends StatelessWidget {
//   const LoginPage({super.key});

//   Future<User?> _signInWithGoogle() async {
//     try {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) return null;

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       final UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithCredential(credential);

//       return userCredential.user;
//     } catch (e) {
//       print("로그인 에러: $e");
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('로그인')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             final user = await _signInWithGoogle();
//             if (user != null) {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => HomePage(userName: user.displayName),
//                 ),
//               );
//             } else {
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(const SnackBar(content: Text('로그인 실패')));
//             }
//           },
//           child: const Text('Google 로그인'),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home.dart'; // 이 파일 import 필요

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print("Google 로그인 에러: $e");
      return null;
    }
  }

  Future<User?> _signInWithAnonymous() async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print("익명 로그인 에러: $e");
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
                final user = await _signInWithAnonymous();
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
