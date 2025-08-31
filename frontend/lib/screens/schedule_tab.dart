import 'package:flutter/material.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  final List<_ScheduleItem> _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('일정')),
      body: _items.isEmpty
          ? const Center(child: Text('아직 일정이 없습니다.'))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final it = _items[i];
          return Dismissible(
            key: ValueKey(it.id),
            onDismissed: (_) => setState(() => _items.removeAt(i)),
            background: Container(color: Colors.redAccent),
            child: ListTile(
              title: Text(it.title),
              subtitle: Text(it.when ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final updated = await _editSchedule(context, it);
                if (updated != null) setState(() => _items[i] = updated);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await _editSchedule(context, null);
          if (created != null) setState(() => _items.add(created));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<_ScheduleItem?> _editSchedule(BuildContext context, _ScheduleItem? item) async {
    final ctrlTitle = TextEditingController(text: item?.title ?? '');
    final ctrlWhen = TextEditingController(text: item?.when ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? '일정 추가' : '일정 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: ctrlTitle, decoration: const InputDecoration(labelText: '제목')),
            const SizedBox(height: 8),
            TextField(controller: ctrlWhen, decoration: const InputDecoration(labelText: '일시/기간(메모)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('저장')),
        ],
      ),
    );
    if (ok != true) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    return _ScheduleItem(
      id: item?.id ?? now,
      title: ctrlTitle.text.trim().isEmpty ? '제목 없음' : ctrlTitle.text.trim(),
      when: ctrlWhen.text.trim().isEmpty ? null : ctrlWhen.text.trim(),
    );
  }
}

class _ScheduleItem {
  final int id;
  final String title;
  final String? when;
  _ScheduleItem({required this.id, required this.title, this.when});
}
