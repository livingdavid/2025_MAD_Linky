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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<String?> summarizeTextWithHuggingFace(String text) async {
  const apiUrl =
      'https://api-inference.huggingface.co/models/sshleifer/distilbart-cnn-12-6';
  // const apiToken = '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'; // 주석 해제 후 사용

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
      } else {
        debugPrint('⚠️ 예상치 못한 응답 형식: $result');
      }
    } else {
      debugPrint('❌ 요청 실패: ${response.statusCode}');
      debugPrint('❌ 응답 본문: ${response.body}');
    }
  } on TimeoutException {
    debugPrint('❌ 요청 타임아웃 발생');
  } catch (e) {
    debugPrint('❌ 요약 예외 발생: $e');
  }

  return null;
}

String? extractedTitle;
String? extractedImageUrl; // 추가

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
      final imageUrl = data['image']?['url'] ?? ''; // ✅ 대표 이미지

      final combined = [
        title,
        description,
        content,
      ].where((e) => e.trim().isNotEmpty).join('. ');

      debugPrint('📄 추출된 제목: $title');
      debugPrint('🖼️ 대표 이미지 URL: $imageUrl');

      extractedTitle = title;
      extractedImageUrl = imageUrl; // ✅ 전역 변수에 저장

      return combined.length > 30 ? combined : null;
    }
  } catch (e) {
    debugPrint('❌ Microlink 예외: $e');
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
  DateTime? scheduledDateTime;

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _initNotifications();

    bool containsKorean(String text) {
      final koreanRegex = RegExp(r'[가-힣]');
      return koreanRegex.hasMatch(text);
    }

    linkController.addListener(() async {
      final url = linkController.text.trim();
      if (!url.startsWith('http')) return;

      debugPrint('🟡 URL 감지됨: $url');

      final extractedText = await extractTextFromUrl(url);
      debugPrint('📄 추출된 텍스트 길이: ${extractedText?.length}');

      if (extractedText == null || extractedText.length < 30) {
        debugPrint('⚠️ 추출된 텍스트가 너무 짧아서 요약 생략');
        return;
      }

      // ✅ 한국어 포함 시 요약 생략
      if (containsKorean(extractedText)) {
        debugPrint('🛑 한국어 포함되어 있어 요약 생략');
        return;
      }

      final trimmed =
          extractedText.length > 1000
              ? extractedText.substring(0, 1000)
              : extractedText;

      final summary = await summarizeTextWithHuggingFace(trimmed);
      debugPrint('📝 요약 결과: $summary');

      if (summary != null && mounted) {
        memoController.text = summary;
        setState(() {});
        debugPrint('✅ 메모에 요약 적용됨');
      } else {
        memoController.text = '⚠️ 요약 실패: 내용을 직접 입력해 주세요.';
        setState(() {});
        debugPrint('❌ 요약 실패, fallback 메모 표시');
      }
    });
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
    print('🧪 Firestore에 저장할 imageUrl: $extractedImageUrl');
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
        'imageUrl': extractedImageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await folderRef.update({
        'lastAddedUrl': url,
        'lastMemo': memoController.text.trim(),
        'lastTags': tags,
        'imageUrl': extractedImageUrl ?? '',

        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await folderRef.collection('links').add({
      'url': url,
      'title': title,
      'memo': memoController.text.trim(),
      'tags': tags,
      'imageUrl': extractedImageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (isReminderSet && scheduledDateTime != null) {
      final delay = scheduledDateTime!.difference(DateTime.now());
      if (delay.isNegative) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('과거 시간은 선택할 수 없습니다.')));
        return;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      scheduledDateTime != null
                          ? '${scheduledDateTime!.year}-${scheduledDateTime!.month.toString().padLeft(2, '0')}-${scheduledDateTime!.day.toString().padLeft(2, '0')} '
                              '${scheduledDateTime!.hour.toString().padLeft(2, '0')}:${scheduledDateTime!.minute.toString().padLeft(2, '0')}'
                          : '날짜 및 시간 선택',
                    ),
                    onPressed: () async {
                      final now = DateTime.now();
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                      );
                      if (pickedDate == null) return;
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          now.add(const Duration(minutes: 1)),
                        ),
                      );
                      if (pickedTime == null) return;
                      final pickedDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      setState(() {
                        scheduledDateTime = pickedDateTime;
                      });
                    },
                  ),
                ],
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
