// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preference_app_group/shared_preference_app_group.dart';
import 'auth_gate.dart';
import 'linkUpload.dart'; // LinkUploadPage 선언부 import
import 'login.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 앱이 백그라운드 상태에서 알림을 탭했을 때 실행되는 콜백 (entry-point로 표시)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  final link = response.payload;
  if (link?.isNotEmpty ?? false) {
    // 백그라운드에서 탭 시 공유 링크 저장
    await SharedPreferenceAppGroup.setAppGroup('group.com.linky');
    await SharedPreferenceAppGroup.setString('sharedLink', link!);
  }
}

/// onDidReceiveNotificationResponse에서 호출되는 내부 함수
void _handleNotificationTap(NotificationResponse resp) async {
  final link = resp.payload;
  if (link?.isNotEmpty ?? false) {
    await SharedPreferenceAppGroup.setAppGroup('group.com.linky');
    await SharedPreferenceAppGroup.setString('sharedLink', link!);
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => LinkUploadPage(initialUrl: link!)),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // App Group 설정
  await SharedPreferenceAppGroup.setAppGroup('group.com.linky');
  tz.initializeTimeZones();

  // 알림 초기 설정
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  final initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _handleNotificationTap,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // iOS 권한 요청
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >()
      ?.requestPermissions(alert: true, sound: true, badge: true);

  // 앱 종료 상태에서 알림 탭으로 시작했는지 확인
  final details =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  String? initialLink;

  if (details?.didNotificationLaunchApp ?? false) {
    initialLink = details!.notificationResponse?.payload;
  }

  // 이외에 Share Extension에서 전달된 링크도 통합 처리
  final sharedLink = await SharedPreferenceAppGroup.getString('sharedLink');
  if (sharedLink != null) {
    await SharedPreferenceAppGroup.remove('sharedLink');
    initialLink ??= sharedLink;
  }

  runApp(MyApp(initialLink: initialLink));
}

class MyApp extends StatefulWidget {
  final String? initialLink;
  const MyApp({super.key, this.initialLink});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 초기 링크는 AuthGate를 통해 자동 처리
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // **백그라운드→포그라운드 복귀** 시 링크 체크
    if (state == AppLifecycleState.resumed) {
      _checkSharedLink();
    }
  }

  Future<void> _checkSharedLink() async {
    final link = await SharedPreferenceAppGroup.getString('sharedLink');
    if (link != null) {
      await SharedPreferenceAppGroup.remove('sharedLink');
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => LinkUploadPage(initialUrl: link)),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Linky',
      debugShowCheckedModeBanner: false,
      home: AuthGate(initialLink: widget.initialLink),
      routes: {
        '/login': (context) => const LoginPage(), // ✅ 이거 추가
      },
    );
  }
}
