import 'package:flutter/material.dart';
import 'linkUpload.dart';
import 'modals/updateFolder.dart';
import 'modals/deleteFolder.dart';

class FolderPage extends StatefulWidget {
  final String initialFolder;
  final Map<String, List<Map<String, String>>> folderData;

  const FolderPage({
    super.key,
    required this.initialFolder,
    required this.folderData,
  });

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  late String selectedFolder;
  late List<String> folderList;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    selectedFolder = widget.initialFolder;
    folderList = widget.folderData.keys.toList();
  }

  void _showUpdateFolderModal() {
    showDialog(
      context: context,
      builder:
          (_) => UpdateFolderModal(
            folderName: selectedFolder,
            onUpdate: (newName) {
              setState(() {
                final links = widget.folderData.remove(selectedFolder)!;
                widget.folderData[newName] = links;
                folderList = widget.folderData.keys.toList();
                selectedFolder = newName;
              });
            },
          ),
    );
  }

  void _showDeleteFolderModal() {
    showDialog(
      context: context,
      builder:
          (_) => DeleteFolderModal(
            onDelete: () {
              setState(() {
                widget.folderData.remove(selectedFolder);
                folderList = widget.folderData.keys.toList();
                selectedFolder = folderList.isNotEmpty ? folderList[0] : '';
              });
              Navigator.pop(context);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final links = widget.folderData[selectedFolder] ?? [];
    final filteredLinks =
        links.where((link) {
          final title = link['title']?.toLowerCase() ?? '';
          final content = link['content']?.toLowerCase() ?? '';
          final query = searchQuery.toLowerCase();
          return title.contains(query) || content.contains(query);
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedFolder),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onSelected: (value) {
              if (value == 'rename') {
                showDialog(
                  context: context,
                  builder:
                      (_) => UpdateFolderModal(
                        folderName: selectedFolder,
                        onUpdate: (newName) {
                          setState(() {
                            final oldIndex = folderList.indexOf(selectedFolder);

                            folderList[oldIndex] = newName;

                            final links = widget.folderData.remove(
                              selectedFolder,
                            );
                            if (links != null) {
                              widget.folderData[newName] = links;
                            }

                            selectedFolder = newName;
                          });
                        },
                      ),
                );
              } else if (value == 'delete') {}
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('폴더명 변경')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('폴더 삭제', style: TextStyle(color: Colors.red)),
                  ),
                ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '링크 ${filteredLinks.length}개',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: folderList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final folderName = folderList[index];
                  final isSelected = selectedFolder == folderName;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFolder = folderName),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.green : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        folderName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredLinks.length,
                itemBuilder: (context, index) {
                  final link = filteredLinks[index];
                  return Dismissible(
                    key: Key(link['title'] ?? index.toString()),
                    background: Container(
                      padding: const EdgeInsets.only(left: 20),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.push_pin, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        final confirmed = await showDialog(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text('삭제 확인'),
                                content: const Text('정말로 이 링크를 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: const Text(
                                      '삭제',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        );
                        if (confirmed) {
                          setState(() {
                            widget.folderData[selectedFolder]?.removeAt(index);
                          });
                        }
                        return confirmed;
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('고정되었습니다.')),
                        );
                        return false;
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            link['content'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children:
                                (link['tags']?.split(',') ?? [])
                                    .map(
                                      (tag) => Chip(
                                        label: Text(tag),
                                        backgroundColor: const Color(
                                          0xFFE0E0E0,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LinkUploadPage()),
                  );
                },
                backgroundColor: Colors.green,
                label: const Text('업로드'),
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
