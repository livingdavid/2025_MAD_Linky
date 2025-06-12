import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'modals/addTag.dart';
import 'modals/createFolder.dart';
import 'QrScanpage.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<String?> summarizeTextWithHuggingFace(String text) async {
  const apiUrl =
      'https://api-inference.huggingface.co/models/sshleifer/distilbart-cnn-12-6';
  const apiToken = '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';

  try {
    final shortened = text.length > 1000 ? text.substring(0, 1000) : text;
    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'inputs': shortened}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result is List && result.isNotEmpty && result[0] is Map) {
        return result[0]['summary_text'];
      }
    }
  } catch (e) {
    debugPrint('❌ 요약 실패: $e');
  }
  return null;
}

String? extractedTitle;

Future<String?> extractTextFromUrl(String url) async {
  final extractUrl = 'https://api.microlink.io/?url=$url';

  try {
    final response = await http.get(Uri.parse(extractUrl));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'];
      final title = data['title'] ?? '';
      final description = data['description'] ?? '';
      final content = data['content'] ?? '';
      extractedTitle = title;

      final combined = [
        title,
        description,
        content,
      ].where((e) => e.trim().isNotEmpty).join('. ');
      return combined.length > 30 ? combined : null;
    }
  } catch (e) {
    debugPrint('❌ Microlink 실패: $e');
  }
  return null;
}

class LinkUploadPage extends StatefulWidget {
  final String? initialUrl;
  const LinkUploadPage({super.key, this.initialUrl});

  @override
  State<LinkUploadPage> createState() => _LinkUploadPageState();
}

class _LinkUploadPageState extends State<LinkUploadPage> {
  String selectedFolder = '';
  List<String> folderList = [];
  List<String> tags = [];

  final linkController = TextEditingController();
  final memoController = TextEditingController();

  bool isReminderSet = false;
  DateTime? scheduledDateTime;

  @override
  void initState() {
    super.initState();

    if (widget.initialUrl != null) {
      linkController.text = widget.initialUrl!;
    }

    _loadFolders();
    _initNotifications();

    linkController.addListener(() async {
      final url = linkController.text.trim();
      if (!url.startsWith('http')) return;

      final extractedText = await extractTextFromUrl(url);
      if (extractedText == null || extractedText.length < 30) return;

      final summary = await summarizeTextWithHuggingFace(extractedText);
      if (summary != null && mounted) {
        memoController.text = summary;
        setState(() {});
      }
    });
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    tz.initializeTimeZones();
    await flutterLocalNotificationsPlugin.initialize(initSettings);
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

  void _uploadChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || selectedFolder.isEmpty) return;

    final folderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('folders')
        .doc(selectedFolder);
    final folderSnapshot = await folderRef.get();

    final url = linkController.text.trim();
    final title = extractedTitle ?? Uri.parse(url).host;

    if (!folderSnapshot.exists) {
      await folderRef.set({
        'name': selectedFolder,
        'lastAddedUrl': url,
        'lastMemo': memoController.text.trim(),
        'lastTags': tags,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await folderRef.collection('links').add({
      'url': url,
      'title': title,
      'memo': memoController.text.trim(),
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (isReminderSet && scheduledDateTime != null) {
      final delay = scheduledDateTime!.difference(DateTime.now());
      if (!delay.isNegative) {
        await _scheduleReminder(title, delay);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('업로드 되었습니다.')));
      Navigator.pop(context, true);
    }
  }

  Future<void> _scheduleReminder(String title, Duration delay) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '저장한 링크 다시 보기',
      '\"$title\" 링크를 다시 확인해보세요!',
      tz.TZDateTime.now(tz.local).add(delay),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          '링크 리마인더',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void _showCreateFolderModal() {
    showDialog(
      context: context,
      builder:
          (ctx) =>
              CreateFolderModal(onCreate: (name) => Navigator.pop(ctx, name)),
    ).then((value) {
      if (value is String) {
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
      ).showSnackBar(const SnackBar(content: Text('태그는 최대 3개까지')));
      return;
    }
    showDialog(context: context, builder: (_) => const AddTagModal()).then((
      value,
    ) {
      if (value is String) {
        setState(() => tags.add(value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('업로드'), leading: BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('링크', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: linkController,
              decoration: const InputDecoration(
                hintText: '링크를 붙여넣어주세요',
                filled: true,
                fillColor: Color(0xFFF0F0F0),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text("QR 코드로 링크 입력"),
              onPressed: () async {
                final scanned = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrScanPage()),
                );
                if (scanned is String) linkController.text = scanned;
              },
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
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: folderList.length,
                itemBuilder: (_, i) {
                  final folder = folderList[i];
                  final isSelected = folder == selectedFolder;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFolder = folder),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
                          Text(folder, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text('태그', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                ...tags.map((tag) => Chip(label: Text(tag))),
                ActionChip(
                  label: const Text('+ 태그 추가'),
                  onPressed: _showAddTagModal,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('메모', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: memoController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '링크에 대한 메모',
                filled: true,
                fillColor: Color(0xFFF0F0F0),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: isReminderSet,
              onChanged: (v) => setState(() => isReminderSet = v!),
              title: const Text('리마인더 알림 설정'),
            ),
            if (isReminderSet)
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  scheduledDateTime != null
                      ? '${scheduledDateTime!.toLocal()}'.split('.')[0]
                      : '날짜 및 시간 선택',
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 5),
                  );
                  if (date == null) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time == null) return;
                  setState(
                    () =>
                        scheduledDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ),
                  );
                },
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploadChanges,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('업로드'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
