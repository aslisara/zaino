import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'l10n.dart';
import 'main.dart' show baseUrl, authHeaders;

const Color kDefaultAccent = Color(0xFF00897B);

/// Kullanıcının seçtiği vurgu rengi; uygulamanın bütün teması buna göre boyanır.
final ValueNotifier<Color> accentColor = ValueNotifier<Color>(kDefaultAccent);

const List<Color> kAccentChoices = [
  Color(0xFF00897B),
  Color(0xFF1976D2),
  Color(0xFF7B1FA2),
  Color(0xFFC2185B),
  Color(0xFFD32F2F),
  Color(0xFFF57C00),
  Color(0xFF388E3C),
  Color(0xFF455A64),
];

String colorToHex(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

Color? colorFromHex(dynamic hex) {
  if (hex is! String || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) return null;
  return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
}

/// Profili sunucudan alır ve vurgu rengini uygular.
Future<Map<String, dynamic>?> fetchProfile() async {
  try {
    final res = await http.get(Uri.parse('$baseUrl/api/profile'), headers: authHeaders());
    if (res.statusCode == 200) {
      final map = Map<String, dynamic>.from(jsonDecode(utf8.decode(res.bodyBytes)) as Map);
      accentColor.value = colorFromHex(map['accentColor']) ?? kDefaultAccent;
      return map;
    }
  } catch (_) {}
  return null;
}

/// Düzenleme diyaloğu. Kaydedilirse güncel profili döndürür.
Future<Map<String, dynamic>?> showEditProfileDialog(
    BuildContext context, Map<String, dynamic> profile) {
  final name = TextEditingController(text: '${profile['displayName'] ?? ''}');
  final bio = TextEditingController(text: '${profile['bio'] ?? ''}');
  var color = colorFromHex(profile['accentColor']) ?? accentColor.value;
  var saving = false;
  String? error;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text(t('Profili düzenle', 'Edit profile')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: name,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: t('Adın', 'Your name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bio,
                maxLength: 160,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: t('Kısa söz', 'Short bio'),
                  hintText: t('Dünyayı geziyorum...', 'Exploring the world...'),
                  prefixIcon: const Icon(Icons.format_quote),
                ),
              ),
              const SizedBox(height: 12),
              Text(t('Renk', 'Color'), style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in kAccentChoices)
                    GestureDetector(
                      onTap: () => setS(() => color = c),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: c,
                        child: color.toARGB32() == c.toARGB32()
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(ctx),
            child: Text(t('Vazgeç', 'Cancel')),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setS(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      final res = await http.put(
                        Uri.parse('$baseUrl/api/profile'),
                        headers: authHeaders(),
                        body: jsonEncode({
                          'displayName': name.text.trim(),
                          'bio': bio.text.trim(),
                          'accentColor': colorToHex(color),
                        }),
                      );
                      if (res.statusCode == 200) {
                        final map = Map<String, dynamic>.from(
                            jsonDecode(utf8.decode(res.bodyBytes)) as Map);
                        accentColor.value = colorFromHex(map['accentColor']) ?? kDefaultAccent;
                        if (ctx.mounted) Navigator.pop(ctx, map);
                        return;
                      }
                      setS(() {
                        saving = false;
                        error = t('Kaydedilemedi (${res.statusCode})',
                            'Could not save (${res.statusCode})');
                      });
                    } catch (_) {
                      setS(() {
                        saving = false;
                        error = t('Sunucuya ulaşılamadı', 'Could not reach the server');
                      });
                    }
                  },
            child: Text(saving ? t('Kaydediliyor...', 'Saving...') : t('Kaydet', 'Save')),
          ),
        ],
      ),
    ),
  );
}
