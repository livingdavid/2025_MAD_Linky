import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkViewPage extends StatelessWidget {
  final String link;
  const LinkViewPage({super.key, required this.link});

  void _shareLink(BuildContext context) {
    Share.share(link);
  }

  void _openOriginal() async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadDate = DateTime.now();

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: _openOriginal,
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
                          padding: const EdgeInsets.only(top: 5.0, left: 16, right: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_horiz, color: Colors.white),
                                color: Colors.white,
                                position: PopupMenuPosition.under,
                                onSelected: (value) {},
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('링크 수정'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('링크 삭제', style: TextStyle(color: Colors.red)),
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
                                'https://sports.naver.com/favicon.ico',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                '네이버 스포츠 야구',
                                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${uploadDate.year}.${uploadDate.month.toString().padLeft(2, '0')}.${uploadDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: IconButton(
                            icon: const Icon(Icons.ios_share, color: Colors.white),
                            onPressed: () => _shareLink(context),
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('폴더', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Chip(label: Text('스포츠'), backgroundColor: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),

                  const Text('링크', style: TextStyle(fontWeight: FontWeight.bold)),
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

                  const Text('태그', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: const [
                      Chip(label: Text('야구'), backgroundColor: Color(0xFFF0F0F0)),
                      Chip(label: Text('한화'), backgroundColor: Color(0xFFF0F0F0)),
                      Chip(label: Text('가을야구'), backgroundColor: Color(0xFFF0F0F0)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('메모', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '한화 이글스는 오랜 기다림 끝에 가을야구 진출을 목표로 하고 있습니다. 팬들의 기대가 점점 높아지는 가운데, 최근 경기력 또한 향상되고 있으며, 젊은 선수들의 활약이 돋보이고 있습니다. 특히 이번 시즌은 투타의 밸런스가 안정적이라는 평가를 받고 있으며, 팀워크와 사기 진작이 중요한 시점입니다. 남은 경기 일정과 맞대결 팀들과의 전략적 대응이 관건이 될 것입니다. 팬들로부터의 응원 또한 선수들에게 큰 힘이 되고 있으며, 한화의 상승세가 얼마나 이어질지 기대를 모으고 있습니다.',
                      style: TextStyle(fontSize: 14),
                    ),
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