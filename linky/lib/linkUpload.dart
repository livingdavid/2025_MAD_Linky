import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'modals/addTag.dart';
import 'modals/createFolder.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<String?> summarizeTextWithHuggingFace(String text) async {
  const apiUrl =
      'https://api-inference.huggingface.co/models/facebook/bart-large-cnn';
  const apiToken = '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';

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer $apiToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'inputs': text}),
  );

  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);
    if (result is List && result.isNotEmpty) {
      return result[0]['summary_text'];
    }
  } else {
    print('❌ 요청 실패: ${response.statusCode}');
    print('❌ 응답 본문: ${response.body}');
  }

  return null;
}

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

  bool isReminderSet = false;
  String selectedInterval = '1분 후';

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _initNotifications();

    linkController.addListener(() async {
      final url = linkController.text.trim();
      if (url.startsWith('http')) {
        final extractedText = await extractTextFromUrl(url);
        if (extractedText != null && extractedText.length > 30) {
          final summary = await summarizeTextWithHuggingFace(extractedText);
          if (summary != null && mounted) {
            setState(() {
              memoController.text = summary;
            });
          }
        }
      }
    });
  }

  Future<String?> extractTextFromUrl(String url) async {
    const apiKey = 'a9d7166be40af6f13dc201e457fb2271';
    final apiUrl = 'https://api.linkpreview.net/?key=$apiKey&q=$url';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('📥 LinkPreview 응답: $json');
        return json['description'];
      } else {
        print('❌ LinkPreview 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ LinkPreview 오류: $e');
    }
    return null;
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    tz.initializeTimeZones();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Future<void> _testNotification() async {
  //   await flutterLocalNotificationsPlugin.zonedSchedule(
  //     999,
  //     '테스트 알림',
  //     '이건 리마인더 알림 테스트입니다.',
  //     tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
  //     const NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         'test_channel',
  //         '테스트 채널',
  //         channelDescription: '테스트용 알림입니다.',
  //         importance: Importance.max,
  //         priority: Priority.high,
  //       ),
  //       iOS: DarwinNotificationDetails(),
  //     ),
  //     androidAllowWhileIdle: true,
  //     uiLocalNotificationDateInterpretation:
  //         UILocalNotificationDateInterpretation.absoluteTime,
  //   );
  // }

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

  Future<void> _scheduleReminder(String title, Duration delay) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '저장한 링크 다시 보기',
      '"$title" 링크를 다시 확인해보세요!',
      tz.TZDateTime.now(tz.local).add(delay),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          '링크 리마인더',
          channelDescription: '링크 리마인더 알림',
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

  void _uploadChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || selectedFolder.isEmpty) return;

    final folderRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('folders')
        .doc(selectedFolder);

    final folderSnapshot = await folderRef.get();
    final title = linkController.text.trim();

    if (!folderSnapshot.exists) {
      await folderRef.set({
        'name': selectedFolder,
        'lastAddedUrl': title,
        'lastMemo': memoController.text.trim(),
        'lastTags': tags,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await folderRef.update({
        'lastAddedUrl': title,
        'lastMemo': memoController.text.trim(),
        'lastTags': tags,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await folderRef.collection('links').add({
      'url': title,
      'memo': memoController.text.trim(),
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (isReminderSet) {
      Duration delay;
      switch (selectedInterval) {
        case '3분 후':
          delay = const Duration(minutes: 3);
          break;
        case '7분 후':
          delay = const Duration(minutes: 7);
          break;
        case '1분 후':
        default:
          delay = const Duration(minutes: 1);
      }
      await _scheduleReminder(title, delay);
    }

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
            const SizedBox(height: 16),
            // ElevatedButton(
            //   onPressed: _testNotification,
            //   child: const Text('🔔 알림 테스트'),
            // ),
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
            const SizedBox(height: 24),
            CheckboxListTile(
              value: isReminderSet,
              onChanged: (val) => setState(() => isReminderSet = val!),
              title: const Text('리마인더 알림 설정'),
            ),
            if (isReminderSet)
              DropdownButton<String>(
                value: selectedInterval,
                onChanged: (val) => setState(() => selectedInterval = val!),
                items:
                    ['1분 후', '3분 후', '7분 후']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
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
