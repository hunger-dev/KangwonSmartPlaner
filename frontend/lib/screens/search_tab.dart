import 'package:flutter/material.dart';
import 'home_page.dart';

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 이미 만들어 둔 HomePage가 축제 검색/목록 화면이므로 그대로 씁니다.
    return const HomePage();
  }
}
