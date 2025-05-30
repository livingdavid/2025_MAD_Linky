import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'modals/addTag.dart';
import 'modals/createFolder.dart';

class LinkUploadPage extends StatefulWidget {
  const LinkUploadPage({super.key});

  @override
  State<LinkUploadPage> createState() => _LinkUploadPageState();
}

class _LinkUploadPageState extends State<LinkUploadPage> {
  String selectedFolder = '';
  List<String> folderList = [];
  List<String> tags = [];

  TextEditingController linkController = TextEditingController();
  TextEditingController memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  void _loadFolders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('folders')
            .get();

    final names = snapshot.docs.map((doc) => doc.id).toList();
    setState(() {
      folderList = names;
      if (names.isNotEmpty) selectedFolder = names.first;
    });
  }

  void _showCreateFolderModal() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => CreateFolderModal(
            onCreate: (newFolder) {
              Navigator.pop(dialogContext, newFolder);
            },
          ),
    ).then((value) {
      if (value != null && value is String && value.isNotEmpty) {
        setState(() {
          folderList.add(value);
          selectedFolder = value;
        });
      }
    });
  }

  void _showAddTagModal() {
    if (tags.length >= 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('태그는 최대 3개까지 추가할 수 있습니다.')));
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => const AddTagModal(),
    ).then((value) {
      if (value != null && value is String && value.isNotEmpty) {
        setState(() {
          tags.add(value);
        });
      }
    });
  }

  void _uploadChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || selectedFolder.isEmpty) return;

    final folderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('folders')
        .doc(selectedFolder);

    final folderSnapshot = await folderRef.get();

    if (!folderSnapshot.exists) {
      // 새 폴더일 경우에만 문서 생성
      await folderRef.set({
        'name': selectedFolder,
        'lastAddedUrl': linkController.text.trim(),
        'lastMemo': memoController.text.trim(),
        'lastTags': tags,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // 기존 폴더일 경우 last 정보만 업데이트
      await folderRef.update({
        'lastAddedUrl': linkController.text.trim(),
        'lastMemo': memoController.text.trim(),
        'lastTags': tags,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 링크 추가는 항상 links 서브컬렉션에
    await folderRef.collection('links').add({
      'url': linkController.text.trim(),
      'memo': memoController.text.trim(),
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('업로드 되었습니다.')));

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('업로드'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('링크', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(
                hintText: '링크를 붙여넣어주세요',
                fillColor: Color(0xFFF0F0F0),
                filled: true,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '폴더 선택',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _showCreateFolderModal,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: folderList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final folder = folderList[index];
                  final isSelected = selectedFolder == folder;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFolder = folder),
                    child: Container(
                      width: 64,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.green.shade100
                                : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            isSelected
                                ? Border.all(color: Colors.green, width: 2)
                                : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder, color: Colors.green),
                          const SizedBox(height: 4),
                          Text(
                            folder,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            const Text('태그', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...tags.map(
                    (tag) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(tag),
                        backgroundColor: const Color(0xFFF0F0F0),
                      ),
                    ),
                  ),
                  ActionChip(
                    label: const Text('+ 태그 추가'),
                    onPressed: _showAddTagModal,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('메모', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: memoController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '링크에 대한 내용을 입력해보세요',
                fillColor: Color(0xFFF0F0F0),
                filled: true,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _uploadChanges,
                child: const Text('업로드'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
