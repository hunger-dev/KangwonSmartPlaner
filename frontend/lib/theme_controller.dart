import 'package:flutter/material.dart';

// 앱 어디서나 접근할 수 있는 전역 테마모드 노티파이어
final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);