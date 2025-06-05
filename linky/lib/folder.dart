import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'linkView.dart';
import 'linkUpload.dart';

class FolderPage extends StatefulWidget {
  final String initialFolder;
  final Map<String, List<Map<String, dynamic>>> folderData;

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
  late Map<String, List<Map<String, dynamic>>> folderData;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    selectedFolder = widget.initialFolder;
    folderList = widget.folderData.keys.toList();
    folderData = widget.folderData;
  }

  Future<void> _loadLinks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('folders')
            .doc(selectedFolder)
            .collection('links')
            .orderBy('createdAt', descending: true)
            .get();

    final links =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'url': data['url'] ?? '',
            'title': data['title'] ?? '',
            'memo': data['memo'] ?? '',
            'tags': (data['tags'] as List<dynamic>?)?.join(',') ?? '',
            'createdAt': data['createdAt'] ?? Timestamp.now(),
            'docId': doc.id,
          };
        }).toList();

    setState(() {
      folderData[selectedFolder] = links;
    });
  }

  TextSpan highlightQuery(String source, String query) {
    if (query.isEmpty) return TextSpan(text: source);

    final matches = RegExp(
      RegExp.escape(query),
      caseSensitive: false,
    ).allMatches(source);

    if (matches.isEmpty) return TextSpan(text: source);

    final spans = <TextSpan>[];
    int currentIndex = 0;

    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: source.substring(currentIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: source.substring(match.start, match.end),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
      currentIndex = match.end;
    }

    if (currentIndex < source.length) {
      spans.add(TextSpan(text: source.substring(currentIndex)));
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final links = folderData[selectedFolder] ?? [];
    final filteredLinks =
        links.where((link) {
          final title = (link['title'] ?? '').toString().toLowerCase();
          final memo = (link['memo'] ?? '').toString().toLowerCase();
          final tags = (link['tags'] ?? '').toString().toLowerCase();
          final url = (link['url'] ?? '').toString();
          final domain = Uri.tryParse(url)?.host.toLowerCase() ?? '';
          final query = searchQuery.toLowerCase();
          return title.contains(query) ||
              memo.contains(query) ||
              tags.contains(query) ||
              domain.contains(query);
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedFolder,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '링크 ${links.length}개',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: folderList.length,
                itemBuilder: (context, index) {
                  final folderName = folderList[index];
                  final isSelected = selectedFolder == folderName;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFolder = folderName),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color:
                                isSelected ? Colors.green : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        folderName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  filteredLinks.isEmpty
                      ? const Center(child: Text('일치하는 링크가 없습니다.'))
                      : ListView.builder(
                        itemCount: filteredLinks.length,
                        itemBuilder: (context, index) {
                          final link = filteredLinks[index];
                          final tagList =
                              (link['tags'] ?? '')
                                  .toString()
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();

                          return GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => LinkViewPage(
                                        linkData: {
                                          'lastAddedUrl': link['url'] ?? '',
                                          'lastTags': tagList,
                                          'lastMemo': link['memo'] ?? '',
                                          'createdAt':
                                              link['createdAt'] ??
                                              Timestamp.now(),
                                          'name': selectedFolder,
                                          'docId': link['docId'] ?? '',
                                        },
                                      ),
                                ),
                              );
                              if (result == true) {
                                await _loadLinks();
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Image.network(
                                        'https://www.google.com/s2/favicons?sz=64&domain_url=${link['url'] ?? ''}',
                                        width: 24,
                                        height: 24,
                                        errorBuilder:
                                            (_, __, ___) =>
                                                const Icon(Icons.link),
                                      ),
                                      const SizedBox(width: 8),
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: [
                                            highlightQuery(
                                              Uri.parse(link['url'] ?? '').host,
                                              searchQuery,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        highlightQuery(
                                          link['title'] ?? '',
                                          searchQuery,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RichText(
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                      children: [
                                        highlightQuery(
                                          link['memo'] ?? '',
                                          searchQuery,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (tagList.isNotEmpty)
                                    Wrap(
                                      spacing: 8,
                                      children:
                                          tagList.map((tag) {
                                            return Chip(
                                              label: Text(tag),
                                              backgroundColor: const Color(
                                                0xFFF0F0F0,
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LinkUploadPage()),
          );
          if (result == true) {
            await _loadLinks();
            Navigator.pop(context, true);
          }
        },
        label: const Text('+ 업로드'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
