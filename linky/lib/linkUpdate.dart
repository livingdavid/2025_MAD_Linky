import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'modals/addTag.dart';
import 'modals/createFolder.dart';

class LinkUpdatePage extends StatefulWidget {
  final String link;
  const LinkUpdatePage({super.key, required this.link});

  @override
  State<LinkUpdatePage> createState() => _LinkUpdatePageState();
}

class _LinkUpdatePageState extends State<LinkUpdatePage> {
  String selectedFolder = '취업준비';
  List<String> folderList = ['김지원', '지석영', '이민규'];
  List<String> tags = ['태그1', '태그2', '태그3'];
  TextEditingController memoController = TextEditingController();

  void _showCreateFolderModal() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => CreateFolderModal(
            onCreate: (newFolder) {
              setState(() {
                folderList.add(newFolder);
                selectedFolder = newFolder;
              });
              Navigator.pop(context);
            },
          ),
    );
  }

  void _showAddTagModal() {
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

  void _uploadChanges() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('업로드 되었습니다.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('링크 수정'),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.link, style: const TextStyle(fontSize: 13)),
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
                    onTap: () {
                      setState(() {
                        selectedFolder = folder;
                      });
                    },
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
            const Text(
              '태그 *최대 3개까지 생성 가능',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
