import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'linkView.dart';

class LinkListByDatePage extends StatefulWidget {
  const LinkListByDatePage({super.key});

  @override
  State<LinkListByDatePage> createState() => _LinkListByDatePageState();
}

class _LinkListByDatePageState extends State<LinkListByDatePage> {
  Map<String, List<Map<String, dynamic>>> groupedLinks = {};
  bool isLoading = true;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchAllLinks();
  }

  Future<void> _fetchAllLinks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final foldersSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('folders')
            .get();

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var folderDoc in foldersSnapshot.docs) {
      final folderName = folderDoc.id;
      final linksSnapshot =
          await folderDoc.reference
              .collection('links')
              .orderBy('createdAt', descending: true)
              .get();

      for (var doc in linksSnapshot.docs) {
        final data = doc.data();
        final ts = data['createdAt'] as Timestamp?;
        final date = ts?.toDate() ?? DateTime.now();
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        final item = {
          'lastAddedUrl': data['url'] as String? ?? '',
          'lastMemo': data['memo'] as String? ?? '',
          'lastTags':
              (data['tags'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[],
          'folder': folderName,
          'createdAt': date,
          'title': data['title'] as String? ?? '',
          'docId': doc.id,
          'name': folderName, // linkViewPage에서 'name' 필드 기대
        };

        grouped.putIfAbsent(dateKey, () => []).add(item);
      }
    }

    setState(() {
      groupedLinks = grouped;
      isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('전체 링크 목록'),
          bottom: const TabBar(
            tabs: [Tab(text: '날짜별 보기'), Tab(text: '선택 날짜 보기')],
          ),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                  children: [_buildGroupedListView(), _buildFilteredListView()],
                ),
      ),
    );
  }

  Widget _buildGroupedListView() {
    final entries =
        groupedLinks.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final dateKey = entries[i].key;
        final list = entries[i].value;
        return ExpansionTile(
          title: Text(
            '📅 $dateKey (${list.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: list.map(_buildRichLinkCard).toList(),
        );
      },
    );
  }

  Widget _buildFilteredListView() {
    final dateKey =
        selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
            : null;
    final list =
        dateKey != null && groupedLinks.containsKey(dateKey)
            ? groupedLinks[dateKey]!
            : [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ActionChip(
            onPressed: _pickDate,
            avatar: const Icon(
              Icons.calendar_today,
              size: 20,
              color: Colors.black,
            ),
            label: Text(
              dateKey ?? '날짜 선택',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: const Color(0xFFF0F0F0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Expanded(
          child:
              list.isEmpty
                  ? Center(
                    child: Text(
                      selectedDate == null ? '날짜를 선택해주세요.' : '해당 날짜에 링크가 없습니다.',
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    itemBuilder: (_, idx) => _buildRichLinkCard(list[idx]),
                  ),
        ),
      ],
    );
  }

  Widget _buildRichLinkCard(Map<String, dynamic> link) {
    final raw = link['createdAt'] as DateTime;
    final time = DateFormat('HH:mm').format(raw);
    final tags = link['lastTags'] as List<String>;
    final url = link['lastAddedUrl'] as String;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LinkViewPage(linkData: link)),
        );
        if (result == true) {
          await _fetchAllLinks();
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.network(
                    'https://www.google.com/s2/favicons?sz=64&domain_url=$url',
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) => const Icon(Icons.link),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      url,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                link['title'] as String,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              if ((link['lastMemo'] as String).isNotEmpty)
                Text(
                  link['lastMemo'] as String,
                  style: const TextStyle(fontSize: 14),
                ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children:
                      tags
                          .map(
                            (t) => Chip(
                              label: Text(t),
                              backgroundColor: Colors.grey.shade200,
                            ),
                          )
                          .toList(),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📂 ${link['folder']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(time, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
