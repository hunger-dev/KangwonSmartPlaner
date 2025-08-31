// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'root_nav_scaffold.dart';
import 'screens/intro_splash_page.dart'; // ← 인트로 화면
import 'services/prefs.dart';            // ← 첫 실행 여부 저장

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  // 상태바/내비바 아이콘 색상 고정 (밝은 아이콘)
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  // 첫 실행 여부 로드
  final seenIntro = await Prefs.seenIntro;

  runApp(MyApp(seenIntro: seenIntro));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.seenIntro = true});
  final bool seenIntro;

  @override
  Widget build(BuildContext context) {
    final light = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, // 라이트 모드 고정
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8EF5F4),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor:
      Colors.transparent, // 각 화면에서 그라데이션 보이도록 투명
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white, // 타이틀/아이콘 흰색
      ),
      cardTheme: const CardThemeData(
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.transparent,
      ),
    );

    return MaterialApp(
      title: 'Festival App',
      debugShowCheckedModeBanner: false,
      theme: light, // 라이트 테마만 사용
      // ✅ 첫 실행이면 인트로, 아니면 메인으로
      home: seenIntro ? const RootNavScaffold() : const IntroSplashPage(),
    );
  }
}
