// lib/screens/festival_detail_page.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/festival.dart';
import 'plan_setup_page.dart';
import '../widgets/glass.dart';

const kTextOnGlass = Color(0xCCFFFFFF);
const kBlue        = Color(0xFF4361EE);

class FestivalDetailPage extends StatelessWidget {
  final Festival festival;
  const FestivalDetailPage({super.key, required this.festival});

  Future<void> _openLink(BuildContext context) async {
    final url = festival.detailUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('상세 링크가 없습니다.')));
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('링크를 열 수 없습니다.')));
    }
  }

  void _previewPoster(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.85),
        pageBuilder: (_, __, ___) => GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Hero(
                tag: 'poster_${festival.id}',
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: (c, _, __) => const Icon(
                        Icons.broken_image, color: Colors.white, size: 64),
                  ),
                ),
              ),
            ),
          ),
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  // 상단 포스터를 글라스 프레임으로 감싼 위젯
  Widget _posterGlass(BuildContext context) {
    final img = festival.imageSrc;
    if (img == null || img.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: GestureDetector(
        onTap: () => _previewPoster(context, img),
        child: GlassContainer(
          blur: 24,
          opacity: 0.10,
          borderRadius: BorderRadius.circular(22),
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Hero(
              tag: 'poster_${festival.id}',
              child: CachedNetworkImage(
                imageUrl: img,
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
                placeholder: (c, _) =>
                    Container(height: 220, color: Colors.black12),
                errorWidget: (c, _, __) =>
                const Icon(Icons.broken_image, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3A0CA3), Color(0xFF4361EE), Color(0xFF5E60CE)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            festival.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: kTextOnGlass, // 아이콘/제목 색
          elevation: 0,
          scrolledUnderElevation: 0,
        ),

        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _posterGlass(context),

            // 축제 정보 글라스 카드
            GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(18),
              blur: 20,
              opacity: 0.15,
              child: IconTheme(
                data: const IconThemeData(color: kTextOnGlass, size: 18),
                child: DefaultTextStyle(
                  style: const TextStyle(color: kTextOnGlass, fontSize: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        festival.title,
                        style: const TextStyle(
                          color: kTextOnGlass,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if ((festival.periodRaw ?? '').isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.event),
                            const SizedBox(width: 8),
                            Expanded(child: Text(festival.periodRaw!)),
                          ],
                        ),
                      if ((festival.address ?? '').isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.place),
                            const SizedBox(width: 8),
                            Expanded(child: Text(festival.address!)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),

        // ▼ 하단 액션: 오른쪽에 “방문 계획 시작” 단일 버튼 (흰 배경 + 파란 글씨)
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final draft = await Navigator.of(context).push<ScheduleDraft>(
                  MaterialPageRoute(
                    builder: (_) => PlanSetupPage(festival: festival),
                  ),
                );
                if (!context.mounted) return;
                if (draft != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('임시 계획이 준비되었습니다. (서버 전송 예정)')),
                  );
                }
              },
              icon: const Icon(Icons.event_available),
              label: const Text('방문 계획 시작'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,   // ✅ 셋업 페이지와 동일
                foregroundColor: kBlue,           // ✅ 셋업 페이지와 동일
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: Colors.white.withOpacity(0.25)), // (선택) 살짝 테두리
              ),
            ),
          ),
        ),
      ),
    );
  }
}
