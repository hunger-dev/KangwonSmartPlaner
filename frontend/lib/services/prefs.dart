import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static const _kSeenIntro = 'seen_intro';

  static Future<bool> get seenIntro async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kSeenIntro) ?? false;
  }

  static Future<void> setSeenIntro(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kSeenIntro, v);
  }
}
