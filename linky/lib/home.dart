import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'linkUpload.dart';
import 'folder.dart';
import 'modals/deleteFolder.dart';

class HomePage extends StatefulWidget {
  final String? userName;
  final String? email;
  final String? photoUrl;

  const HomePage({super.key, this.userName, this.email, this.photoUrl});

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
                backgroundImage: NetworkImage(widget.photoUrl ?? ''),
              ),
            ),
            const ListTile(title: Text('이용 약관')),
            const ListTile(title: Text('개인정보 처리방침')),
            const ListTile(title: Text('도움말')),
            ListTile(
              title: const Text('로그아웃'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            const ListTile(
              title: Text('회원탈퇴', style: TextStyle(color: Colors.red)),
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
              backgroundImage: NetworkImage(widget.photoUrl ?? ''),
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
                prefixIcon: const Icon(Icons.search),
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
                                    final uid =
                                        FirebaseAuth.instance.currentUser?.uid;
                                    final folderDocId = folder['docId'];

                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => DeleteFolderModal(
                                            onDelete: () async {
                                              final links =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(uid)
                                                      .collection('folders')
                                                      .doc(folderDocId)
                                                      .collection('links')
                                                      .get();

                                              for (var doc in links.docs) {
                                                await doc.reference.delete();
                                              }

                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(uid)
                                                  .collection('folders')
                                                  .doc(folderDocId)
                                                  .delete();

                                              Navigator.pop(context, true);
                                            },
                                          ),
                                    ).then((value) {
                                      if (value == true) _loadFolders();
                                    });
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
                                if (result == true) _loadFolders();
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
