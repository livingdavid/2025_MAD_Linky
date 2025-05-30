import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      // Google 로그인이면 로그아웃 처리
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        await GoogleSignIn().signOut();
      }
      await FirebaseAuth.instance.signOut();

      // 로그인 페이지로 이동 (스택 초기화)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Logout failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            accountName: Text(
              user?.isAnonymous == true
                  ? '익명 사용자'
                  : user?.displayName ?? '로그인 사용자',
            ),
            accountEmail: Text(user?.email ?? ''),
          ),
          ListTile(title: const Text('이용 약관'), onTap: () {}),
          ListTile(title: const Text('개인정보 처리방침'), onTap: () {}),
          ListTile(title: const Text('도움말'), onTap: () {}),
          ListTile(title: const Text('로그아웃'), onTap: () => _signOut(context)),
          ListTile(
            title: const Text('회원탈퇴', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
