import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LinkListByDatePage extends StatefulWidget {
  final String folderName;

  const LinkListByDatePage({required this.folderName, super.key});

  @override
  State<LinkListByDatePage> createState() => _LinkListByDatePageState();
}

class _LinkListByDatePageState extends State<LinkListByDatePage>
    with SingleTickerProviderStateMixin {
  Map<String, List<Map<String, dynamic>>> groupedLinks = {};
  bool isLoading = true;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchLinks();
  }

  Future<void> _fetchLinks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('folders')
            .doc(widget.folderName)
            .collection('links')
            .orderBy('createdAt', descending: true)
            .get();

    final links =
        snapshot.docs.map((doc) {
          final data = doc.data();
          final date = (data['createdAt'] as Timestamp).toDate();
          return {
            'url': data['url'],
            'memo': data['memo'],
            'tags': List<String>.from(data['tags'] ?? []),
            'date': DateFormat('yyyy-MM-dd').format(date),
            'rawDate': date,
          };
        }).toList();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var link in links) {
      grouped.putIfAbsent(link['date'], () => []);
      grouped[link['date']]!.add(link);
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
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.folderName} 링크 목록'),
          bottom: const TabBar(
            tabs: [Tab(text: '날짜별 보기'), Tab(text: '선택 날짜 보기')],
          ),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                  children: [
                    _buildGroupedListView(), // A안
                    _buildFilteredListView(), // B안
                  ],
                ),
      ),
    );
  }

  Widget _buildGroupedListView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children:
          groupedLinks.entries.map((entry) {
            final date = entry.key;
            final links = entry.value;
            return ExpansionTile(
              title: Text(
                '📅 $date',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              children: links.map((link) => _buildLinkCard(link)).toList(),
            );
          }).toList(),
    );
  }

  Widget _buildFilteredListView() {
    final dateKey =
        selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
            : null;

    final filteredLinks =
        dateKey != null && groupedLinks.containsKey(dateKey)
            ? groupedLinks[dateKey]!
            : [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                  : '날짜 선택',
            ),
          ),
        ),
        if (selectedDate == null)
          const Center(child: Text('날짜를 선택해주세요.'))
        else if (filteredLinks.isEmpty)
          const Center(child: Text('해당 날짜에 저장된 링크가 없습니다.'))
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children:
                  filteredLinks.map((link) => _buildLinkCard(link)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLinkCard(Map<String, dynamic> link) {
    return Card(
      child: ListTile(
        title: Text(link['url']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((link['memo'] as String).isNotEmpty) Text('📝 ${link['memo']}'),
            if ((link['tags'] as List).isNotEmpty)
              Wrap(
                spacing: 6,
                children:
                    (link['tags'] as List)
                        .map<Widget>(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Colors.grey.shade200,
                          ),
                        )
                        .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
