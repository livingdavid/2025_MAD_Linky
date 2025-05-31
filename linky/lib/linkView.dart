import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'linkUpdate.dart';
import 'modals/deleteFolder.dart';

class LinkViewPage extends StatefulWidget {
  final Map<String, dynamic> linkData;
  const LinkViewPage({super.key, required this.linkData});

  @override
  State<LinkViewPage> createState() => _LinkViewPageState();
}

class _LinkViewPageState extends State<LinkViewPage> {
  late Map<String, dynamic> linkData;

  @override
  void initState() {
    super.initState();
    linkData = widget.linkData;
  }

  void _shareLink(String link) {
    Share.share(link);
  }

  void _openOriginal(String link) async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _refreshLinkData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final folder = linkData['name'];
    final docId = linkData['docId'];
    if (folder == null || docId == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('folders')
            .doc(folder)
            .collection('links')
            .doc(docId)
            .get();
    Navigator.pop(context, true);

    if (doc.exists) {
      setState(() {
        final data = doc.data()!;
        linkData = {
          'lastAddedUrl': data['url'] ?? '',
          'lastMemo': data['memo'] ?? '',
          'lastTags': data['tags'] ?? [],
          'createdAt': data['createdAt'] ?? Timestamp.now(),
          'name': folder,
          'docId': docId,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String link = linkData['lastAddedUrl'] ?? '';
    final String folderName = linkData['name'] ?? '';
    final List<String> tags =
        (linkData['lastTags'] is List)
            ? List<String>.from(linkData['lastTags'])
            : (linkData['lastTags'] as String)
                .split(',')
                .map((e) => e.trim())
                .toList();

    final String memo = linkData['lastMemo'] ?? '';
    final String docId = linkData['docId'] ?? '';
    final DateTime uploadDate =
        linkData['createdAt'] is Timestamp
            ? (linkData['createdAt'] as Timestamp).toDate()
            : DateTime.now();

    final String faviconUrl =
        'https://www.google.com/s2/favicons?sz=64&domain_url=$link';
    final String pageTitle = Uri.parse(link).host;

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: () => _openOriginal(link),
            backgroundColor: Colors.green,
            label: const Text('원문 보기'),
            icon: const Icon(Icons.open_in_new),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/Linky.png',
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.45),
                    colorBlendMode: BlendMode.darken,
                  ),
                  SafeArea(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 5,
                            left: 16,
                            right: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                ),
                                color: Colors.white,
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => LinkUpdatePage(
                                              linkData: linkData,
                                            ),
                                      ),
                                    );

                                    if (result == true || result is Map) {
                                      await _refreshLinkData();
                                      Navigator.pop(context, true);
                                    }
                                  } else if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder:
                                          (_) => DeleteFolderModal(
                                            onDelete: () async {
                                              Navigator.pop(
                                                context,
                                              ); // 다이얼로그 닫기

                                              final uid =
                                                  FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.uid;
                                              if (uid == null) return;

                                              final folder = linkData['name'];
                                              final docId = linkData['docId'];
                                              if (folder == null ||
                                                  docId == null)
                                                return;

                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(uid)
                                                    .collection('folders')
                                                    .doc(folder)
                                                    .collection('links')
                                                    .doc(docId)
                                                    .delete();

                                                if (mounted)
                                                  Navigator.pop(context, true);
                                              } catch (e) {
                                                print('🔥 삭제 오류: $e');
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      '링크 삭제에 실패했어요.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                    );
                                  }
                                },
                                itemBuilder:
                                    (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('링크 수정'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          '링크 삭제',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 84,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(
                                faviconUrl,
                                width: 24,
                                height: 24,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.link,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                pageTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${uploadDate.year}.${uploadDate.month.toString().padLeft(2, '0')}.${uploadDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: IconButton(
                            icon: const Icon(
                              Icons.ios_share,
                              color: Colors.white,
                            ),
                            onPressed: () => _shareLink(link),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '폴더',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(folderName),
                    backgroundColor: const Color(0xFFF0F0F0),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '링크',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(link, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '태그',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children:
                        tags
                            .map<Widget>(
                              (tag) => Chip(
                                label: Text(tag),
                                backgroundColor: const Color(0xFFF0F0F0),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '메모',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(memo, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
