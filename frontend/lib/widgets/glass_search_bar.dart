import 'package:flutter/material.dart';
import 'glass.dart'; // 네가 만든 GlassContainer
const kTextColor = Color(0xCCFFFFFF);

class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String query) onSearch;

  const GlassSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.hintText = '제목 검색 (예: 강원, 춘천)',
  });

  @override
  Widget build(BuildContext context) {
    // 전체 캡슐 높이 고정 → AppBar.bottom과 정확히 맞추기
    return SizedBox(
      height: 52,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        blur: 20,
        opacity: 0.16,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 20, color: kTextColor), // ✅ 아이콘 흰색
            const SizedBox(width: 8),

            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  return TextField(
                    controller: controller,
                    style: const TextStyle(color: kTextColor), // ✅ 입력 텍스트 흰색
                    cursorColor: kTextColor, // ✅ 커서도 흰색
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSearch,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: kTextColor.withOpacity(0.6), // ✅ 힌트는 연한 흰색
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 8),

            // 글라스 버튼 (텍스트만)
            SizedBox(
              height: 36,
              child: GlassContainer(
                blur: 20,
                opacity: 0.14,
                borderRadius: BorderRadius.circular(18),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onTap: () => onSearch(controller.text),
                child: const Center(
                  child: Text(
                    '검색',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: kTextColor, // ✅ 버튼 글자도 흰색
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
