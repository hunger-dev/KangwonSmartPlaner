// lib/screens/plan_result_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';


import '../widgets/glass.dart';
import '../services/api_client.dart' as api; // savePlanWithTicket 사용
import '../main.dart';

const kTextColor = Color(0xCCFFFFFF);
const kBlue      = Color(0xFF4361EE);

class PlanResultPage extends StatefulWidget {
  /// 서버 응답: { "result": { "itinerary":[...], "totals":{...} } }
  final Map<String, dynamic> result;

  const PlanResultPage({super.key, required this.result});

  @override
  State<PlanResultPage> createState() => _PlanResultPageState();
}

class _PlanResultPageState extends State<PlanResultPage> {
  late final List<Map<String, dynamic>> _items;
  late final Map<String, dynamic> _totals;
  bool _saving = false;

  // 임시 티켓 (서버에서 별도 /plan/sign 발급이 있다면 그걸 받아서 넣으세요)
  static const String _devTicket = 'dev';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ko_KR', null);

    // 항상 result를 연다
    final Map<String, dynamic> root =
    Map<String, dynamic>.from(widget.result['result'] ?? const {});

    final rawList = (root['itinerary'] as List?) ?? const [];

    _items = rawList
        .whereType<Map>() // 안전
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) => _asInt(a['index']).compareTo(_asInt(b['index'])));

    _totals = Map<String, dynamic>.from(root['totals'] ?? const {});
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  DateTime? _parseIso(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(dt.toLocal());
  }

  String _fmtTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm', 'ko_KR').format(dt.toLocal());
  }

  Color _typeDotColor(String type) {
    switch (type) {
      case 'festival':
        return const Color(0xFFB8F24E);
      case 'restaurant':
        return const Color(0xFFFFD166);
      case 'cafe':
        return const Color(0xFF7DD3FC);
      default:
        return const Color(0xFFA5B4FC); // place 등
    }
  }

  Future<void> _saveCurrentPlan() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // root 열기
      final Map<String, dynamic> root =
      Map<String, dynamic>.from(widget.result['result'] ?? const {});
      final items = (root['itinerary'] as List? ?? [])
          .whereType<Map>()
          .map((e) {
        return {
          'index': _asInt(e['index']),
          'type': (e['type'] ?? 'place').toString(),
          'title': (e['title'] ?? '').toString(),
          'start_time': e['start_time']?.toString(), // ISO(+09:00) 그대로
          'end_time': e['end_time']?.toString(),
          'description': (e['description'] ?? '').toString(),
        };
      })
          .toList();

      // ✅ PlanCommitPayload (ticket + itinerary)
      final payload = {
        'ticket': _devTicket, // TODO: 실제 sign_ticket() 결과로 교체
        'itinerary': items,
      };

      final resp = await api.ApiClient.savePlanWithTicket(payload);
      final savedId = resp['id']?.toString() ?? '';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 완료! id=$savedId')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MyApp()), // 시작 화면
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A0CA3), Color(0xFF4361EE), Color(0xFF5E60CE)],
    );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: kTextColor,
          elevation: 0,
          title: const Text('추천 일정'),
          actions: [
            IconButton(
              tooltip: '원문 JSON 복사',
              icon: const Icon(Icons.copy_all_rounded),
              onPressed: () async {
                final pretty = const JsonEncoder.withIndent('  ').convert(widget.result);
                await Clipboard.setData(ClipboardData(text: pretty));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('JSON을 클립보드에 복사했습니다.')),
                );
              },
            ),
            IconButton(
              tooltip: '원문 JSON 보기',
              icon: const Icon(Icons.data_object),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _JsonViewerPage(map: widget.result),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: _items.isEmpty
              ? const Center(
            child: Text(
              '표시할 일정이 없습니다.\n응답 맵의 키를 확인해 주세요. (result.itinerary)',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextColor),
            ),
          )
              : CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final it = _items[i];
                    final type = (it['type'] ?? 'place').toString();
                    final title = (it['title'] ?? '').toString();
                    final desc = (it['description'] ?? '').toString();
                    final start = _parseIso(it['start_time']?.toString());
                    final end = _parseIso(it['end_time']?.toString());

                    return _TimelineRow(
                      dotColor: _typeDotColor(type),
                      child: GlassContainer(
                        blur: 20,
                        opacity: 0.18,
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius:
                                    BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    type.toUpperCase(),
                                    style: const TextStyle(
                                        color: kTextColor, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: kTextColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 16, color: kTextColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${_fmtDate(start)} ${_fmtTime(start)} ~ ${_fmtTime(end)}',
                                    style: const TextStyle(
                                        color: kTextColor, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(desc,
                                  style: const TextStyle(
                                      color: kTextColor)),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_totals.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                  sliver: SliverToBoxAdapter(
                    child: GlassContainer(
                      blur: 20,
                      opacity: 0.18,
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.insights_outlined,
                              color: kTextColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '예상 비용: ${_totals['estimated_cost_krw'] ?? '-'}원 · 이동 시간: ${_totals['estimated_travel_time_minutes'] ?? '-'}분',
                              style:
                              const TextStyle(color: kTextColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kTextColor, // 버튼 배경
                foregroundColor: kBlue,      // 텍스트·아이콘
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saving ? null : _saveCurrentPlan, // 저장 연결
              icon: _saving
                  ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.download_outlined),
              label: Text(_saving ? '저장 중...' : '이 일정 저장하기'),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final Color dotColor;
  final Widget child;

  const _TimelineRow({required this.dotColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 64,
                margin: const EdgeInsets.only(top: 6),
                color: Colors.white.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

/// JSON 원문 뷰어
class _JsonViewerPage extends StatelessWidget {
  final Map<String, dynamic> map;
  const _JsonViewerPage({required this.map});

  @override
  Widget build(BuildContext context) {
    final pretty = const JsonEncoder.withIndent('  ').convert(map);

    return Scaffold(
      appBar: AppBar(title: const Text('원문 JSON')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: SelectableText(
            pretty,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}
