import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../theme_controller.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('서버 주소'),
            subtitle: Text(ApiClient.baseUrl),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('테마'),
            subtitle: Text('라이트/다크/시스템'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeMode,
              builder: (context, mode, _) {
                return SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('라이트')),
                    ButtonSegment(value: ThemeMode.dark,  icon: Icon(Icons.dark_mode),  label: Text('다크')),
                    ButtonSegment(value: ThemeMode.system,icon: Icon(Icons.phone_iphone),label: Text('시스템')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) => themeMode.value = s.first,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('앱 정보'),
            subtitle: Text('Festival App (MVP)'),
          ),
        ],
      ),
    );
  }
}
