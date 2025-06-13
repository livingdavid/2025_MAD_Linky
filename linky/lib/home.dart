import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'linkUpload.dart';
import 'folder.dart';
import 'modals/deleteFolder.dart';
import 'LinkListByDatePage.dart';
import 'login.dart';

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
          return const LoginPage(); // 로그인 페이지는 기존 파일 참조
        }
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final String? initialLink;
  final String? userName;
  final String? email;
  final String? photoUrl;

  const HomePage({
    super.key,
    this.initialLink,
    this.userName,
    this.email,
    this.photoUrl,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> filteredFolders = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LinkUploadPage(initialUrl: widget.initialLink!),
          ),
        );
      });
    }

    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('folders')
              .orderBy('createdAt', descending: false)
              .get();

      List<Map<String, dynamic>> temp = [];
      for (var doc in snapshot.docs) {
        final folderName = doc['name'] as String;
        final linksSnap =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('folders')
                .doc(doc.id)
                .collection('links')
                .get();

        final links =
            linksSnap.docs.map((e) {
              final data = e.data();
              return {
                'url': data['url'] ?? '',
                'title': data['title'] ?? '',
                'memo': data['memo'] ?? '',
                'tags': (data['tags'] as List<dynamic>?)?.join(',') ?? '',
                'createdAt': data['createdAt'] ?? Timestamp.now(),
                'docId': e.id,
              };
            }).toList();

        temp.add({
          'name': folderName,
          'linkCount': links.length,
          'docId': doc.id,
          'links': links,
        });
      }

      setState(() {
        folders = temp;
        filteredFolders = temp;
      });
    } catch (e) {
      print("🔥 오류 발생: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.userName ?? '사용자'),
              accountEmail: Text(widget.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage:
                    widget.photoUrl != null
                        ? NetworkImage(widget.photoUrl!)
                        : null,
              ),
            ),
            const ListTile(title: Text('이용 약관')),
            const ListTile(title: Text('개인정보 처리방침')),
            const ListTile(title: Text('도움말')),
            ListTile(
              title: const Text('로그아웃'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              },
            ),
            ListTile(
              title: const Text('회원탈퇴', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('정말 탈퇴하시겠습니까?'),
                        content: const Text('모든 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.'),
                        actions: [
                          TextButton(
                            child: const Text('취소'),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          TextButton(
                            child: const Text(
                              '확인',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                );
                if (confirm != true) return;

                _showLoadingDialog();
                final user = FirebaseAuth.instance.currentUser;
                final uid = user?.uid;
                try {
                  if (uid != null) {
                    final userDoc = FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid);
                    final foldersSnap =
                        await userDoc.collection('folders').get();
                    for (var doc in foldersSnap.docs) {
                      final linksSnap =
                          await doc.reference.collection('links').get();
                      for (var link in linksSnap.docs) {
                        await link.reference.delete();
                      }
                      await doc.reference.delete();
                    }
                    await userDoc.delete();
                  }
                  await user?.delete();
                  await FirebaseAuth.instance.signOut();
                } catch (e) {
                  print('회원탈퇴 오류: $e');
                } finally {
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundImage:
                  widget.photoUrl != null
                      ? NetworkImage(widget.photoUrl!)
                      : null,
            ),
            const SizedBox(height: 12),
            Text(
              widget.userName ?? '사용자',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '폴더를 검색하세요',
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.green,
                      ),
                      onPressed: () {
                        if (filteredFolders.isNotEmpty) {
                          final folderName = filteredFolders.first['name'];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LinkListByDatePage(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('먼저 폴더를 선택하거나 검색하세요.'),
                            ),
                          );
                        }
                      },
                    ),
                    const Icon(Icons.search),
                  ],
                ),
                fillColor: Colors.grey[200],
                filled: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (query) {
                final results =
                    folders
                        .where(
                          (folder) => folder['name']
                              .toString()
                              .toLowerCase()
                              .contains(query.toLowerCase()),
                        )
                        .toList();
                setState(() => filteredFolders = results);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredFolders.isEmpty
                      ? const Center(child: Text('일치하는 폴더가 없습니다.'))
                      : ListView.builder(
                        itemCount: filteredFolders.length,
                        itemBuilder: (context, index) {
                          final folder = filteredFolders[index];
                          Map<String, List<Map<String, dynamic>>>
                          allFolderData = {};
                          for (var f in filteredFolders) {
                            allFolderData[f['name']] =
                                List<Map<String, dynamic>>.from(f['links']);
                          }
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: const Icon(
                                  Icons.folder,
                                  color: Colors.green,
                                ),
                              ),
                              title: Text(
                                folder['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('링크 ${folder['linkCount']}개'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    // delete logic...
                                  }
                                },
                                itemBuilder:
                                    (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('삭제'),
                                      ),
                                    ],
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => FolderPage(
                                          initialFolder: folder['name'],
                                          folderData: allFolderData,
                                        ),
                                  ),
                                );
                                if (result == true) {
                                  _loadFolders();
                                }
                              },
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('업로드'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LinkUploadPage()),
          );
          if (result == true) _loadFolders();
        },
      ),
    );
  }
}
