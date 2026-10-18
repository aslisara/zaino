import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Şehir fotoğrafları: Vikipedi'nin açık API'sinden (anahtar gerekmez) alınır.
/// Görseller Wikimedia Commons kaynaklıdır, altta kaynak belirtilir.
class CityPhotos extends StatefulWidget {
  const CityPhotos({super.key, required this.city, required this.country});
  final String city;
  final String country;

  @override
  State<CityPhotos> createState() => _CityPhotosState();
}

class _CityPhotosState extends State<CityPhotos> {
  static final Map<String, List<String>> _cache = {};
  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch(widget.city, widget.country);
  }

  static String _big(String url) {
    var u = url.startsWith('//') ? 'https:$url' : url;
    u = u.replaceFirstMapped(RegExp(r'/\d+px-'), (_) => '/960px-');
    return u;
  }

  static String _baseName(String url) {
    final parts = url.split('/');
    for (var i = parts.length - 1; i >= 0; i--) {
      final p = parts[i];
      if (RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false).hasMatch(p) &&
          !RegExp(r'^\d+px-').hasMatch(p)) {
        return p.toLowerCase();
      }
    }
    return url.toLowerCase();
  }

  static Future<Map<String, dynamic>?> _getJson(String url) async {
    try {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      return j is Map<String, dynamic> ? j : null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> _fetch(String city, String country) async {
    final key = '$city|$country';
    final hit = _cache[key];
    if (hit != null) return hit;

    final urls = <String>[];
    final seen = <String>{};
    final titleSet = <String>[
      city,
      '$city, $country',
    ];
    final bad = RegExp(
      r'map|harita|flag|bayrak|logo|coat|arms|seal|locator|icon|diagram|chart|plan|svg',
      caseSensitive: false,
    );

    for (final lang in ['tr', 'en']) {
      for (final t in titleSet) {
        final title = Uri.encodeComponent(t.replaceAll(' ', '_'));
        final sum = await _getJson('https://$lang.wikipedia.org/api/rest_v1/page/summary/$title');
        if (sum == null) continue;
        final thumb = (sum['thumbnail'] is Map) ? sum['thumbnail']['source'] as String? : null;
        if (thumb != null) {
          final u = _big(thumb);
          if (seen.add(_baseName(u))) urls.add(u);
        }
        final list = await _getJson('https://$lang.wikipedia.org/api/rest_v1/page/media-list/$title');
        final items = (list?['items'] is List) ? list!['items'] as List : const [];
        for (final it in items) {
          if (it is! Map || it['type'] != 'image') continue;
          final name = '${it['title'] ?? ''}';
          if (!RegExp(r'\.jpe?g$', caseSensitive: false).hasMatch(name)) continue;
          if (bad.hasMatch(name)) continue;
          final srcset = it['srcset'];
          if (srcset is! List || srcset.isEmpty) continue;
          final src = (srcset.first as Map)['src'] as String?;
          if (src == null) continue;
          final u = _big(src);
          if (seen.add(_baseName(u))) urls.add(u);
          if (urls.length >= 8) break;
        }
        if (urls.isNotEmpty) break;
      }
      if (urls.isNotEmpty) break;
    }
    _cache[key] = urls;
    return urls;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            height: 190,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(),
          );
        }
        final urls = snap.data ?? const <String>[];
        if (urls.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: urls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: i == 0 ? 320 : 260,
                    child: Image.network(
                      urls[i],
                      fit: BoxFit.cover,
                      loadingBuilder: (c, child, p) => p == null
                          ? child
                          : Container(
                              color: Theme.of(c).colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            ),
                      errorBuilder: (c, e, s) => Container(
                        color: Theme.of(c).colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fotoğraflar: Vikipedi / Wikimedia Commons',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        );
      },
    );
  }
}
