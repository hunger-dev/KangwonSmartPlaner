// lib/screens/prompt_options_page.dart
import 'package:flutter/material.dart';
import '../widgets/glass.dart';
import 'plan_generating_page.dart';
import 'dart:io';

/// 공통 색상
const kTextColor = Color(0xCCFFFFFF);
const kBlue      = Color(0xFF4361EE);
const kGary      = Color(0x89000000);

/// 프롬프트에 넘길 사용자 선택값
class PromptOptions {
  final Budget budget;
  final List<String> categories;
  final bool avoidCrowded;
  final String startTime;
  final String endTime;
  final String? notes;

  const PromptOptions({
    required this.budget,
    required this.categories,
    required this.avoidCrowded,
    required this.startTime,
    required this.endTime,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'budget': budget.name,
    'categories': categories,
    'avoid_crowded': avoidCrowded,
    'start_time': startTime,
    'end_time': endTime,
    // ⬇️ 여기 수정: 비어 있어도 항상 notes 키 포함
    //     (null → "", "   " → "")
    'notes': (notes ?? '').trim(),
  };
}

/// 예산
enum Budget { low, normal, high }

extension _BudgetLabel on Budget {
  String get label => switch (this) {
    Budget.low => '낮음',
    Budget.normal => '보통',
    Budget.high => '여유',
  };
}

/// ===========================
/// 페이지
/// ===========================
class PromptOptionsPage extends StatefulWidget {
  final Map<String, dynamic> scheduleJson;
  final PromptOptions? initial; // 수정 모드일 때

  const PromptOptionsPage({super.key, required this.scheduleJson, this.initial});

  @override
  State<PromptOptionsPage> createState() => _PromptOptionsPageState();
}

class _PromptOptionsPageState extends State<PromptOptionsPage> {
  Budget _budget = Budget.normal;
  bool _avoidCrowded = false;

  // 활동 시간
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 18, minute: 0);

  // 특이 사항
  final _notesCtrl = TextEditingController();

  // 다중 선택 카테고리
  final List<String> _allCategories = const [
    '공연', '체험', '포토', '먹거리', '야간', '지역투어', '자연', '전통', '핫한 스팟'
  ];
  final Set<String> _selectedCats = <String>{};

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _budget = init.budget;
      _avoidCrowded = init.avoidCrowded;
      _selectedCats
        ..clear()
        ..addAll(init.categories);
      _notesCtrl.text = init.notes ?? '';
      _start = _parseTime(init.startTime) ?? _start;
      _end   = _parseTime(init.endTime)   ?? _end;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // ===== 시간 유틸 =====
  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay? _parseTime(String? s) {
    if (s == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return null;
    final hh = int.parse(s.substring(0, 2));
    final mm = int.parse(s.substring(3, 5));
    if (hh < 0 || hh > 23 || mm < 0 || mm > 59) return null;
    return TimeOfDay(hour: hh, minute: mm);
  }

  Future<void> _pick(bool isStart) async {
    final init = isStart ? _start : _end;
    final t = await showTimePicker(context: context, initialTime: init);
    if (t == null) return;
    setState(() {
      if (isStart) {
        _start = t;
        // 시작이 종료와 같거나 늦으면 종료를 시작+1시간으로 보정
        if (_toMinutes(_end) <= _toMinutes(_start)) {
          final plus60 = (_start.hour * 60 + _start.minute + 60) % (24 * 60);
          _end = TimeOfDay(hour: plus60 ~/ 60, minute: plus60 % 60);
        }
      } else {
        _end = t;
        // 종료가 시작보다 이르면 시작을 종료-1시간으로 보정
        if (_toMinutes(_end) <= _toMinutes(_start)) {
          final minus60 = (_end.hour * 60 + _end.minute - 60 + 24 * 60) % (24 * 60);
          _start = TimeOfDay(hour: minus60 ~/ 60, minute: minus60 % 60);
        }
      }
    });
  }

  Future<void> _goGenerate(Map<String, dynamic> payload) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlanGeneratingPage(payload: payload),
      ),
    );
    // ⬆️ 여기서는 SnackBar 등 후처리 제거 (결과 화면에서 처리)
  }


  void _submit() {
    if (_toMinutes(_end) <= _toMinutes(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('활동 종료 시간이 시작 시간보다 늦어야 합니다.')),
      );
      return;
    }

    final options = PromptOptions(
      budget: _budget,
      categories: _selectedCats.toList(),
      avoidCrowded: _avoidCrowded,
      startTime: _fmt(_start),
      endTime: _fmt(_end),
      notes: _notesCtrl.text,
    );

    final payload = {
      "schema_data": "itinerary_request_v1",

      "client": {
        "app": "kangwon_sw",
        "platform": Platform.isAndroid ? "android" : (Platform.isIOS ? "ios" : "other"),
        "version": "1.0.0",
      },
      "schedule": widget.scheduleJson,
      "options": options.toJson(),
    };

    _goGenerate(payload); // ← 그대로 사용
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
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const Text('추가 옵션 선택', style: TextStyle(color: kTextColor)),
          iconTheme: const IconThemeData(color: kTextColor),
          titleTextStyle: const TextStyle(
              color: kTextColor, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // 활동 시간 (정확한 시간)
              _SectionCard(
                title: '활동 시간',
                child: Row(
                  children: [
                    Expanded(
                      child: _TimeBox(
                        label: '시작',
                        value: _fmt(_start),
                        onTap: () => _pick(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeBox(
                        label: '종료',
                        value: _fmt(_end),
                        onTap: () => _pick(false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 예산
              _SectionCard(
                title: '예산',
                child: buildChipRow(
                  items: Budget.values.map((e) => e.label).toList(),
                  selectedIndex: Budget.values.indexOf(_budget),
                  onChanged: (i) => setState(() => _budget = Budget.values[i]),
                ),
              ),
              const SizedBox(height: 12),

              // 관심 카테고리
              _SectionCard(
                title: '관심 카테고리',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: _allCategories.map((c) {
                    final sel = _selectedCats.contains(c);
                    return buildFilterChip(
                      label: c,
                      selected: sel,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _selectedCats.add(c);
                        } else {
                          _selectedCats.remove(c);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // 혼잡 회피
              _SectionCard(
                title: '포함 여부',
                child: Row(
                  children: [
                    const Icon(Icons.groups_2_outlined, color: kTextColor),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '혼잡 시간대 피하기',
                        style: TextStyle(color: kTextColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Switch(
                      value: _avoidCrowded,
                      onChanged: (v) => setState(() => _avoidCrowded = v),
                      activeColor: kBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 특이 사항(자유 입력)
              _SectionCard(
                title: '특이 사항',
                child: TextField(
                  controller: _notesCtrl,
                  style: const TextStyle(color: kTextColor),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '예) 아이와 함께, 휠체어 접근 가능, 매운 음식 제외 등',
                    hintStyle: TextStyle(color: kTextColor),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '프롬프트 생성',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

/// ===========================
/// 시간 박스(글라스 버튼 느낌)
/// ===========================
class _TimeBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeBox({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GlassContainer(
        blur: 20,
        opacity: 0.15,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                label,
                style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.schedule, size: 18, color: kTextColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===========================
/// 섹션 카드(글라스)
/// ===========================
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 20,
      opacity: 0.18,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: kTextColor, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// ===========================
/// 칩 공통 스타일
/// ===========================
Widget buildChoiceChip({
  required String label,
  required bool selected,
  required ValueChanged<bool> onSelected,
}) {
  final Color bgUnselected = Colors.white.withOpacity(0.12);
  final Color textUnselected = kGary;
  final Color textSelected = Colors.white;

  return ChoiceChip(
    label: Text(
      label,
      style: TextStyle(
        color: selected ? textSelected : textUnselected,
        fontWeight: FontWeight.w600,
      ),
    ),
    selected: selected,
    showCheckmark: true,
    checkmarkColor: Colors.white,
    backgroundColor: bgUnselected,
    selectedColor: kBlue.withOpacity(0.95),
    side: BorderSide(
      color: selected ? Colors.white.withOpacity(0.40)
          : Colors.white.withOpacity(0.25),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onSelected: onSelected,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
  );
}

Widget buildChipRow({
  required List<String> items,
  required int selectedIndex,
  required ValueChanged<int> onChanged,
}) {
  return Wrap(
    spacing: 10,
    runSpacing: 8,
    children: List.generate(items.length, (i) {
      return buildChoiceChip(
        label: items[i],
        selected: selectedIndex == i,
        onSelected: (_) => onChanged(i),
      );
    }),
  );
}

/// 다중 선택용(카테고리)
Widget buildFilterChip({
  required String label,
  required bool selected,
  required ValueChanged<bool> onSelected,
}) {
  final Color bgUnselected = Colors.white.withOpacity(0.12);
  final Color textUnselected = kGary;
  final Color textSelected = Colors.white;

  return FilterChip(
    label: Text(
      label,
      style: TextStyle(
        color: selected ? textSelected : textUnselected,
        fontWeight: FontWeight.w600,
      ),
    ),
    selected: selected,
    showCheckmark: true,
    checkmarkColor: Colors.white,
    backgroundColor: bgUnselected,
    selectedColor: kBlue.withOpacity(0.95),
    side: BorderSide(
      color: selected ? Colors.white.withOpacity(0.40)
          : Colors.white.withOpacity(0.25),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onSelected: onSelected,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
  );
}
