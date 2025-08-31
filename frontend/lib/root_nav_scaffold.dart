import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/schedule_tab.dart';
import 'screens/settings_tab.dart';

class RootNavScaffold extends StatefulWidget {
  const RootNavScaffold({super.key});

  @override
  State<RootNavScaffold> createState() => _RootNavScaffoldState();
}

class _RootNavScaffoldState extends State<RootNavScaffold> {
  int _index = 0;

  LinearGradient get _bgGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3A0CA3),
      Color(0xFF4361EE),
      Color(0xFF5E60CE),
    ],
  );

  LinearGradient get _navGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF2F6FF), // 라이트한 톤
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = const [
      HomePage(),
      ScheduleTab(),
      SettingsTab(),
    ];

    return Container(
      decoration: BoxDecoration(gradient: _bgGradient), // ✅ 배경 그라데이션
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: false,
        extendBodyBehindAppBar: true,

        body: pages[_index],

        // ✅ 네비게이션바
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
              )
                  : _navGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor:
                  const Color(0x334361EE), // 선택된 탭 배경 (연한 파랑)
                  labelTextStyle:
                  MaterialStateProperty.resolveWith<TextStyle>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return const TextStyle(
                        color: Color(0xFF4361EE), // ✅ 선택된 라벨 파란색
                        fontWeight: FontWeight.bold,
                      );
                    }
                    return const TextStyle(
                      color: Colors.black87, // ✅ 기본 라벨 (라이트 모드)
                    );
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) =>
                      setState(() => _index = i),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon:
                      Icon(Icons.search, color: Color(0xFF4361EE)),
                      label: '축제',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.event_note_outlined),
                      selectedIcon: Icon(Icons.event_note,
                          color: Color(0xFF4361EE)),
                      label: '일정',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings,
                          color: Color(0xFF4361EE)),
                      label: '설정',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
