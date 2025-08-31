// lib/screens/plan_generating_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/glass.dart';
import '../services/api_client.dart';
import 'plan_result_page.dart';

const kTextColor = Color(0xCCFFFFFF);
const kBlue      = Color(0xFF4361EE);

class PlanGeneratingPage extends StatefulWidget {
  /// 서버에 보낼 전체 페이로드: { "schema_version": "...", "client": {...}, "schedule": {...}, "options": {...} }
  final Map<String, dynamic> payload;

  const PlanGeneratingPage({super.key, required this.payload});

  @override
  State<PlanGeneratingPage> createState() => _PlanGeneratingPageState();
}

class _PlanGeneratingPageState extends State<PlanGeneratingPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final result = await ApiClient.generatePlan(widget.payload);
      if (!mounted) return;

      // ⬇️ 성공: 결과 보기 화면으로 이동 (현재 페이지 교체)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PlanResultPage(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 앱 전체 그라데이션과 통일
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3A0CA3), Color(0xFF4361EE), Color(0xFF5E60CE)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassContainer(
                blur: 20,
                opacity: 0.15,
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error == null) ...[
                      const SizedBox(height: 8),
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        '인공지능이 일정을 만드는 중입니다…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '잠시만 기다려 주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kTextColor),
                      ),
                    ] else ...[
                      const Icon(Icons.error_outline, color: Colors.white, size: 42),
                      const SizedBox(height: 12),
                      const Text(
                        '생성에 실패했어요',
                        style: TextStyle(
                          color: kTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kTextColor),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('닫기'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _start,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: kBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('다시 시도'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
