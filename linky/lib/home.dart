import 'package:flutter/material.dart';
import 'folder.dart';
import 'linkUpload.dart';
import 'updateFolder.dart';
import 'deleteFolder.dart';
import 'profile.dart';
import 'search.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final folders = [
      {'name': '취업 준비', 'count': 2},
      {'name': '코딩 공부', 'count': 3},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("링크 아카이브"),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                ),
          ),
        ],
      ),
      drawer: const ProfileDrawer(),
      body: ListView.builder(
        itemCount: folders.length,
        itemBuilder:
            (context, index) => ListTile(
              leading: const Icon(Icons.folder, size: 40, color: Colors.green),
              title: Text(folders[index]['name']!),
              subtitle: Text('링크 ${folders[index]['count']}개'),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed:
                    () => showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      builder:
                          (context) => SizedBox(
                            height: 150,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit),
                                  title: const Text('폴더 이름 변경'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (_) => const UpdateFolderModal(),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                    '폴더 삭제',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (_) => const DeleteFolderModal(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                    ),
              ),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FolderPage()),
                  ),
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LinkUploadPage()),
            ),
        label: const Text("+ 업로드"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
