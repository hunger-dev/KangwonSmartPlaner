// lib/screens/plan_setup_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/festival.dart';
import '../widgets/glass.dart';
import 'address_search_page.dart';
import 'prompt_options_page.dart' show PromptOptionsPage, PromptOptions;

const kTextColor = Color(0xCCFFFFFF);
const kBlue      = Color(0xFF4361EE);

String _toRfc3339WithOffset(DateTime dt) {
  final local = dt.isUtc ? dt.toLocal() : dt;
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final ss = local.second.toString().padLeft(2, '0');
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final totalMinutes = offset.inMinutes.abs();
  final oh = (totalMinutes ~/ 60).toString().padLeft(2, '0');
  final om = (totalMinutes % 60).toString().padLeft(2, '0');
  return '$y-$m-${d}T$hh:$mm:$ss$sign$oh:$om';
}

/// 서버 전송용 DTO (⟵ festivalAddress 추가)
class ScheduleDraft {
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String? originAddress;
  final String? destinationAddress; // 실사용 도착지(없으면 축제주소 fallback)
  final String festivalAddress;     // ✅ 축제 공식 주소(필수)
  final int? stayMinutes;
  final int? festivalId;
  final String? festivalTitle;
  final String? festivalDetailUrl;

  ScheduleDraft({
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.festivalAddress,  // ✅ 필수
    this.originAddress,
    this.destinationAddress,
    this.stayMinutes,
    this.festivalId,
    this.festivalTitle,
    this.festivalDetailUrl,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'start_at': _toRfc3339WithOffset(startAt),
    'end_at':   _toRfc3339WithOffset(endAt),

    if (originAddress != null && originAddress!.isNotEmpty)
      'origin_address': originAddress,

    if (destinationAddress != null && destinationAddress!.isNotEmpty)
      'destination_address': destinationAddress,

    // ✅ 새 필드: 축제 주소(필수)
    'festival_address': festivalAddress,

    if (stayMinutes != null) 'stay_minutes': stayMinutes,
    if (festivalId != null) 'festival_id': festivalId,
    if (festivalTitle != null) 'festival_title': festivalTitle,
    if (festivalDetailUrl != null) 'festival_detail_url': festivalDetailUrl,
  };
}

class PlanSetupPage extends StatefulWidget {
  final Festival? festival;
  final ScheduleDraft? initial;
  const PlanSetupPage({super.key, this.festival, this.initial});
  @override
  State<PlanSetupPage> createState() => _PlanSetupPageState();
}

class _PlanSetupPageState extends State<PlanSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _originCtrl = TextEditingController();
  final _destCtrl   = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  bool _sameAsOrigin = false;
  Duration _stay = const Duration(hours: 2);

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final d = widget.initial!;
      _titleCtrl.text  = d.title;
      _originCtrl.text = d.originAddress ?? '';
      _destCtrl.text   = d.destinationAddress ?? '';
      _start = d.startAt;
      _end   = d.endAt;
      if (_start != null && _end != null && !_end!.isBefore(_start!)) {
        _stay = _end!.difference(_start!);
      }
    } else {
      if (widget.festival != null) {
        _titleCtrl.text = widget.festival!.title;
        // ✅ 축제 주소를 도착지에 자동 주입
        final addr = widget.festival!.address;
        if (addr != null && addr.isNotEmpty) {
          _destCtrl.text = addr;
        }
      }
      final now = DateTime.now();
      _start = DateTime(now.year, now.month, now.day, 10, 0);
      _end   = _start!.add(_stay);
    }
    _originCtrl.addListener(() {
      if (_sameAsOrigin) _destCtrl.text = _originCtrl.text;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _originCtrl.dispose(); _destCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime? dt) => dt == null ? '' : DateFormat('yyyy.MM.dd').format(dt);
  String _fmtTime(DateTime? dt) => dt == null ? '' : DateFormat('HH:mm').format(dt);

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) =>
      showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100));

  Future<TimeOfDay?> _pickTime(BuildContext context, DateTime initial) =>
      showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));

  Future<void> _pickStart() async {
    if (_start == null) return;
    final base = _start!;
    final d = await _pickDate(context, base); if (d == null) return;
    final t = await _pickTime(context, base);
    setState(() {
      _start = DateTime(d.year, d.month, d.day, t?.hour ?? base.hour, t?.minute ?? base.minute);
      _end   = _start!.add(_stay);
    });
  }

  Future<void> _pickEnd() async {
    if (_end == null) return;
    final base = _end!;
    final d = await _pickDate(context, base); if (d == null) return;
    final t = await _pickTime(context, base);
    final newEnd = DateTime(d.year, d.month, d.day, t?.hour ?? base.hour, t?.minute ?? base.minute);
    if (_start != null && newEnd.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('끝나는 시각이 시작보다 빠를 수 없습니다.'))); return;
    }
    setState(() {
      _end = newEnd;
      if (_start != null) { _stay = _end!.difference(_start!); if (_stay.isNegative) _stay = Duration.zero; }
    });
  }

  void _toggleSameAsOrigin(bool v) { setState(() { _sameAsOrigin = v; if (v) _destCtrl.text = _originCtrl.text; }); }

  Future<void> _pickAddress({required bool forOrigin}) async {
    FocusScope.of(context).unfocus();
    final DaumAddress? sel = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddressSearchPage()),
    );
    if (sel == null) return;
    final text = sel.display;
    setState(() {
      if (forOrigin) { _originCtrl.text = text; if (_sameAsOrigin) _destCtrl.text = text; }
      else { _destCtrl.text = text; }
    });
  }

  Future<void> _goNext() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.'))); return;
    }

    // ✅ 축제 주소(필수)
    final festAddr = widget.festival?.address?.trim() ?? '';
    if (festAddr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('축제 주소 정보가 없습니다. 연결된 축제의 주소를 확인해주세요.'))); return;
    }

    // 도착지 보정: 비어있으면 축제 주소로
    String dest = _sameAsOrigin ? _originCtrl.text.trim() : _destCtrl.text.trim();
    if (dest.isEmpty) dest = festAddr;

    final originOk = _originCtrl.text.trim().isNotEmpty;
    final destOk   = dest.isNotEmpty;
    if (!originOk || !destOk) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('출발지/도착지 주소를 입력해주세요.'))); return;
    }
    if (_start == null || _end == null || _end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('시작/종료 일시를 확인해주세요.'))); return;
    }

    final f = widget.festival;
    final draft = ScheduleDraft(
      title: _titleCtrl.text.trim(),
      startAt: _start!, endAt: _end!,
      originAddress: _originCtrl.text.trim(),
      destinationAddress: dest,
      festivalAddress: festAddr,              // ✅ 반드시 포함
      stayMinutes: _end!.difference(_start!).inMinutes,
      festivalId: f?.id,
      festivalTitle: f?.title,
      festivalDetailUrl: f?.detailUrl,
    );

    final options = await Navigator.of(context).push<PromptOptions?>(
      MaterialPageRoute(builder: (_) => PromptOptionsPage(scheduleJson: draft.toJson())),
    );
    if (!mounted || options == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('옵션 선택이 완료되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF3A0CA3), Color(0xFF4361EE), Color(0xFF5E60CE)],),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('방문 계획 시작'),
          backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
          foregroundColor: kTextColor, elevation: 0, scrolledUnderElevation: 0,),
        body: SafeArea(
          child: Form(
            key: _formKey, autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (widget.festival != null) ...[
                  const Text('연결된 축제', style: TextStyle(color: kTextColor, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  _ConnectedFestivalCard(festival: widget.festival!),
                  const SizedBox(height: 16),
                ],
                _GlassGroup(
                  opacity: 0.15,
                  child: TextFormField(
                    controller: _titleCtrl, style: const TextStyle(color: kTextColor),
                    decoration: const InputDecoration(labelText: '제목 *', labelStyle: TextStyle(color: kTextColor),
                        hintText: '예: OO축제 관람', hintStyle: TextStyle(color: kTextColor), border: InputBorder.none),
                    validator: (v) => (v == null || v.trim().isEmpty) ? '제목을 입력해주세요.' : null,
                  ),
                ),
                const SizedBox(height: 16),
                _GlassGroup(
                  opacity: 0.15,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _DateTimeRow(label: '시작', dateText: _fmtDate(_start), timeText: _fmtTime(_start), onTap: _pickStart),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _originCtrl, readOnly: true, onTap: () => _pickAddress(forOrigin: true),
                      style: const TextStyle(color: kTextColor),
                      decoration: const InputDecoration(
                          labelText: '시작 위치', labelStyle: TextStyle(color: kTextColor),
                          hintText: '주소 검색으로 선택', hintStyle: TextStyle(color: kTextColor),
                          prefixIcon: Icon(Icons.directions_walk, color: kTextColor), border: InputBorder.none),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _GlassGroup(
                  opacity: 0.15,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _DateTimeRow(label: '종료', dateText: _fmtDate(_end), timeText: _fmtTime(_end), onTap: _pickEnd),
                    const SizedBox(height: 10),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('시작 위치와 동일', style: TextStyle(color: kTextColor)),
                      const SizedBox(width: 8),
                      Switch(value: _sameAsOrigin, onChanged: _toggleSameAsOrigin, activeColor: kBlue),
                    ]),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _destCtrl, readOnly: _sameAsOrigin, enabled: !_sameAsOrigin,
                      onTap: !_sameAsOrigin ? () => _pickAddress(forOrigin: false) : null,
                      style: const TextStyle(color: kTextColor),
                      decoration: InputDecoration(
                        labelText: '종료 위치', labelStyle: const TextStyle(color: kTextColor),
                        hintText: _sameAsOrigin ? '시작 위치와 동기화됩니다.' : '탭하여 주소 검색',
                        hintStyle: const TextStyle(color: kTextColor),
                        prefixIcon: const Icon(Icons.flag_outlined, color: kTextColor),
                        helperText: _sameAsOrigin ? '시작 위치와 동기화됩니다.' : null,
                        helperStyle: const TextStyle(color: kTextColor),
                        border: InputBorder.none,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _goNext, icon: const Icon(Icons.check), label: const Text('만들기'),
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ),
      ),
    );
  }
}

class _GlassGroup extends StatelessWidget {
  final Widget child; final double opacity;
  const _GlassGroup({required this.child, this.opacity = 0.15});
  @override
  Widget build(BuildContext context) => GlassContainer(
      blur: 20, opacity: opacity, borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12), child: child);
}

class _DateTimeRow extends StatelessWidget {
  final String label, dateText, timeText; final VoidCallback onTap;
  const _DateTimeRow({required this.label, required this.dateText, required this.timeText, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(children: [
        SizedBox(width: 48, child: Text(label, style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Expanded(child: Text(dateText.isEmpty ? '날짜 선택' : dateText, style: const TextStyle(color: kTextColor))),
        const SizedBox(width: 12),
        const Icon(Icons.schedule, size: 18, color: kTextColor),
        const SizedBox(width: 6),
        Text(timeText.isEmpty ? '--:--' : timeText, style: const TextStyle(color: kTextColor)),
      ]),
    ),
  );
}

class _ConnectedFestivalCard extends StatelessWidget {
  final Festival festival;
  const _ConnectedFestivalCard({required this.festival});
  @override
  Widget build(BuildContext context) {
    final img = festival.imageSrc;
    return GlassContainer(
      blur: 20, opacity: 0.15, borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.all(10),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 56, height: 56,
            child: (img == null || img.isEmpty)
                ? Container(color: Colors.white.withOpacity(0.10),
                child: const Icon(Icons.image_not_supported, color: kTextColor))
                : CachedNetworkImage(imageUrl: img, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(festival.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kTextColor, fontWeight: FontWeight.w600)),
            if ((festival.address ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(festival.address!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kTextColor)),
            ],
          ]),
        )
      ]),
    );
  }
}
