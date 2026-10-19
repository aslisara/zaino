import 'package:flutter/widgets.dart';

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
