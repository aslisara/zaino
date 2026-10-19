import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama dili: 'tr' veya 'en'.
final ValueNotifier<String> appLang = ValueNotifier<String>('tr');

/// Kısa çeviri yardımcısı: t('Merhaba', 'Hello')
String t(String tr, String en) => appLang.value == 'en' ? en : tr;

/// Dil değişince bütün ekranları yeniden çizer (durum kaybolmaz).
void rebuildAll() {
  void rebuild(Element el) {
    el.markNeedsBuild();
    el.visitChildren(rebuild);
  }

  final root = WidgetsBinding.instance.rootElement;
  if (root != null) {
    root.visitChildren(rebuild);
  }
}

/// Kaydedilmiş dil ve tema tercihini okur (uygulama açılışında).
/// Döndürdüğü değer: tema modu adı ('system' | 'light' | 'dark').
Future<String> loadPrefs() async {
  try {
    final p = await SharedPreferences.getInstance();
    final lang = p.getString('lang');
    if (lang == 'tr' || lang == 'en') appLang.value = lang!;
    return p.getString('theme') ?? 'system';
  } catch (_) {
    return 'system';
  }
}

Future<void> savePref(String key, String value) async {
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, value);
  } catch (_) {}
}
