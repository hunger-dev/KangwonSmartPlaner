import 'package:flutter/material.dart';
import '../root_nav_scaffold.dart';
import '../services/prefs.dart'; // shared_preferences 래퍼(앞서 만든 것)
//
// 배경은 기존 앱의 그라데이션 컬러를 그대로 사용합니다.
// 이미지는 assets/intro/intro.png (원하는 파일명으로 교체해도 OK)

const kBlue = Color(0xFF4361EE);
const kTextColor = Color(0xCCFFFFFF);

class IntroSplashPage extends StatelessWidget {
  const IntroSplashPage({super.key});

  Future<void> _start(BuildContext context) async {
    await Prefs.setSeenIntro(true); // 처음 1회만 보이도록
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RootNavScaffold()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 앱에서 쓰는 그라데이션 배경
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3A0CA3), Color(0xFF4361EE), Color(0xFF5E60CE)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Spacer(),
              // 가운데 이미지 영역 — 원하는 이미지만 교체하세요.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 360, // 태블릿/대화면에서 너무 커지지 않도록 제한
                      maxHeight: 360,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,      // 정사각형 캔버스에
                      child: Image.asset(  // ✅ 여기 파일만 교체하면 끝!
                        'assets/intro/intro.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // 하단 버튼 (앱 일관 스타일)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _start(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '시작하기',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
