import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'l10n.dart';
import 'main.dart' show TripDetailPage, baseUrl, authHeaders;

String _extractText(dynamic json) {
  if (json is String) return json;
  if (json is Map) {
    for (final k in ['answer', 'text', 'content', 'response', 'reply', 'message', 'result']) {
      if (json[k] is String) return json[k] as String;
    }
    for (final v in json.values) {
      if (v is String) return v;
    }
  }
  return jsonEncode(json);
}

Map<String, dynamic> _parsePlan(String text) {
  final a = text.indexOf('{');
  final b = text.lastIndexOf('}');
  if (a < 0 || b <= a) {
    throw Exception(t('Yapay zekâ geçerli bir plan döndürmedi.', 'The AI did not return a valid plan.'));
  }
  try {
    final j = jsonDecode(text.substring(a, b + 1));
    if (j is Map<String, dynamic> && j['days'] is List && (j['days'] as List).isNotEmpty) {
      return j;
    }
  } catch (_) {}
  throw Exception(t(
    'Plan eksik geldi. Gün sayısını azaltıp tekrar dene.',
    'The plan came back incomplete. Try fewer days.',
  ));
}

Future<Map<String, dynamic>> _askPlan(String city, String country, int days, String interests) async {
  final en = appLang.value == 'en';
  final lang = en ? 'English' : 'Turkish';
  final prompt = 'Plan a $days-day trip to $city, $country. '
      '${interests.isEmpty ? '' : 'Interests: $interests. '}'
      'Answer ONLY with valid JSON, no markdown, no explanation. Format: '
      '{"title":"short trip title","days":[{"day":1,"stops":[{"name":"place name","lat":41.8902,"lon":12.4922,"note":"max 12 words"}]}]}. '
      'Use exactly $days days, 3 or 4 stops per day, in visiting order, '
      'put geographically close places on the same day. '
      'lat and lon are approximate decimal degrees. Write title, names and notes in $lang.';
  final res = await http
      .post(Uri.parse('$baseUrl/api/ai'), headers: authHeaders(), body: jsonEncode({'prompt': prompt}))
      .timeout(const Duration(seconds: 90));
  if (res.statusCode != 200) {
    throw Exception(t('Yapay zekâ yanıt vermedi (${res.statusCode}).', 'The AI did not respond (${res.statusCode}).'));
  }
  return _parsePlan(_extractText(jsonDecode(utf8.decode(res.bodyBytes))));
}

double? _num(dynamic v) => v is num ? v.toDouble() : null;

String _cut(String s, int max) => s.length <= max ? s : s.substring(0, max);

Future<dynamic> _createTrip(String city, String country, Map<String, dynamic> plan) async {
  final dayList = (plan['days'] as List).whereType<Map>().toList();
  final dayCount = dayList.length.clamp(1, 30);
  final title = _cut(
    ('${plan['title'] ?? ''}'.trim().isEmpty) ? t('$city gezisi', '$city trip') : '${plan['title']}'.trim(),
    80,
  );
  final res = await http.post(
    Uri.parse('$baseUrl/api/trips'),
    headers: authHeaders(),
    body: jsonEncode({'title': title, 'city': city, 'country': country, 'dayCount': dayCount}),
  );
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception(t('Gezi oluşturulamadı (${res.statusCode}).', 'Could not create the trip (${res.statusCode}).'));
  }
  final tripId = jsonDecode(utf8.decode(res.bodyBytes))['id'];
  for (var i = 0; i < dayCount; i++) {
    final stops = (dayList[i]['stops'] is List) ? (dayList[i]['stops'] as List).whereType<Map>().toList() : const <Map>[];
    for (final s in stops) {
      final name = _cut('${s['name'] ?? ''}'.trim(), 100);
      if (name.isEmpty) continue;
      var lat = _num(s['lat']);
      var lon = _num(s['lon']);
      if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
        lat = null;
        lon = null;
      }
      final note = '${s['note'] ?? ''}'.trim();
      await http.post(
        Uri.parse('$baseUrl/api/trips/$tripId/stops'),
        headers: authHeaders(),
        body: jsonEncode({
          'dayNumber': i + 1,
          'name': name,
          'latitude': lat,
          'longitude': lon,
          'note': note.isEmpty ? null : _cut(note, 250),
        }),
      );
    }
  }
  return tripId;
}

/// Yapay zekâya şehir için gün gün gezi planı yaptırır ve gezi olarak kaydeder.
Future<void> planTripWithAi(BuildContext context, String city, String country) async {
  final days = ValueNotifier<double>(3);
  final interests = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t('Yapay zekâ ile gezi planı', 'Plan a trip with AI')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$city, $country', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ValueListenableBuilder<double>(
            valueListenable: days,
            builder: (_, v, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('${v.round()} gün', '${v.round()} days')),
                Slider(
                  value: v,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${v.round()}',
                  onChanged: (x) => days.value = x,
                ),
              ],
            ),
          ),
          TextField(
            controller: interests,
            decoration: InputDecoration(
              labelText: t('İlgi alanları (isteğe bağlı)', 'Interests (optional)'),
              hintText: t('müze, yemek, doğa...', 'museums, food, nature...'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('Vazgeç', 'Cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t('Planla', 'Plan'))),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(t('Plan hazırlanıyor... Yarım dakika sürebilir.',
                  'Preparing your plan... This may take up to 30 seconds.')),
            ),
          ],
        ),
      ),
    ),
  );

  try {
    final plan = await _askPlan(city, country, days.value.round(), interests.text.trim());
    final tripId = await _createTrip(city, country, plan);
    nav.pop(); // ilerleme penceresi
    nav.push(MaterialPageRoute(builder: (_) => TripDetailPage(tripId: tripId)));
  } catch (e) {
    nav.pop();
    final msg = '$e'.replaceFirst('Exception: ', '');
    messenger.showSnackBar(SnackBar(content: Text(msg.contains('TimeoutException')
        ? t('Yapay zekâ çok geç yanıt verdi, tekrar dene.', 'The AI took too long, please try again.')
        : msg)));
  }
}
