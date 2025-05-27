import 'package:flutter/material.dart';
import 'package:linky/folder.dart';
import 'linkView.dart';
import 'modals/deleteFolder.dart';
import 'modals/linkDelete.dart';
import 'modals/addTag.dart';
import 'modals/updateFolder.dart';
import 'modals/createFolder.dart';
import 'linkUpload.dart';
import 'folder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linky',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Linky Linky'),
      // home: const LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _showModal(BuildContext context, Widget child) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder:
          (_) =>
              Center(child: Material(color: Colors.transparent, child: child)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),

            // 폴더 삭제 모달
            ElevatedButton(
              onPressed:
                  () => _showModal(
                    context,
                    DeleteFolderModal(
                      onDelete: () {
                        print('폴더 삭제 완료');
                      },
                    ),
                  ),
              child: const Text('폴더 삭제 모달'),
            ),

            // 링크 삭제 모달
            ElevatedButton(
              onPressed:
                  () => _showModal(
                    context,
                    LinkDeleteModal(
                      onDelete: () {
                        print('링크 삭제 완료');
                      },
                    ),
                  ),
              child: const Text('링크 삭제 모달'),
            ),

            // 태그 추가 모달
            ElevatedButton(
              onPressed:
                  () => _showModal(
                    context,
                    const AddTagModal(), // 이건 콜백 필요 없음
                  ),
              child: const Text('태그 추가 모달'),
            ),

            // 폴더명 변경 모달
            ElevatedButton(
              onPressed:
                  () => _showModal(
                    context,
                    UpdateFolderModal(
                      folderName: '기존폴더명',
                      onUpdate: (newName) {
                        print('폴더명 변경됨: $newName');
                      },
                    ),
                  ),
              child: const Text('폴더명 변경 모달'),
            ),

            // 폴더 생성 모달
            ElevatedButton(
              onPressed:
                  () => _showModal(
                    context,
                    CreateFolderModal(
                      onCreate: (folderName) {
                        print('생성된 폴더명: $folderName');
                      },
                    ),
                  ),
              child: const Text('폴더 생성 모달'),
            ),

            const SizedBox(height: 20),

            // 링크 페이지로 이동
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const LinkViewPage(
                          link: 'https://m.sports.naver.com/kbaseball/index',
                        ),
                  ),
                );
              },
              child: const Text('링크 페이지로 이동'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LinkUploadPage(),
                  ),
                );
              },
              child: const Text('링크 업로드 페이지로 이동'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FolderPage(
                          initialFolder: '취업 준비',
                          folderData: {
                            '취업 준비': [
                              {
                                'title': '웹 페이지 접근성 메뉴',
                                'content': 'iOS 앱 개발자를 위한 플러터 강의 링크',
                                'tags': '플러터,ios',
                              },
                            ],
                            '코딩테스트': [],
                            '자격증': [],
                            '인사이트': [],
                            '인': [],
                            '사': [],
                          },
                        ),
                  ),
                );
              },
              child: const Text('폴더 페이지로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}
