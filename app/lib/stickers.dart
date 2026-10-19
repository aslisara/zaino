import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'explore.dart' show Country, kCountries, countryShape;
import 'l10n.dart';
import 'main.dart' show baseUrl, authHeaders;
import 'names_en.dart';

// ---------------- VERİ ----------------
/// Kullanıcının topladığı stickerlar (sunucudan gelir).
final ValueNotifier<List<Map<String, dynamic>>> myStickers =
    ValueNotifier<List<Map<String, dynamic>>>(<Map<String, dynamic>>[]);

/// Sticker alınmış ülkelerin (Türkçe veri adıyla) kümesi.
Set<String> visitedCountryNames() =>
    myStickers.value.map((s) => '${s['country']}').toSet();

String _two(int n) => n.toString().padLeft(2, '0');
String _iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String? _fmtDate(dynamic iso) {
  if (iso == null) return null;
  final p = '$iso'.split('-');
  if (p.length != 3) return null;
  return '${p[2]}.${p[1]}.${p[0]}';
}

Future<void> loadStickers() async {
  try {
    final res = await http.get(
      Uri.parse('$baseUrl/api/stickers?_=${DateTime.now().millisecondsSinceEpoch}'),
      headers: authHeaders(),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      myStickers.value =
          list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  } catch (_) {}
}

/// Başarıda null, hatada gösterilecek metni döndürür.
Future<String?> addSticker(String country, {String? city, DateTime? date, String? note}) async {
  try {
    final res = await http.post(
      Uri.parse('$baseUrl/api/stickers'),
      headers: authHeaders(),
      body: jsonEncode({
        'country': country,
        'city': city,
        'visitedOn': date == null ? null : _iso(date),
        'note': note,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      await loadStickers();
      return null;
    }
    if (res.statusCode == 409) {
      return t('Bu sticker zaten koleksiyonunda.', 'You already have this sticker.');
    }
    return t('Eklenemedi (${res.statusCode})', 'Could not add (${res.statusCode})');
  } catch (_) {
    return t('Sunucuya ulaşılamadı', 'Could not reach the server');
  }
}

Future<String?> removeSticker(dynamic id) async {
  try {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/stickers/$id'),
      headers: authHeaders(),
    );
    if (res.statusCode == 200 || res.statusCode == 204) {
      await loadStickers();
      return null;
    }
    return t('Silinemedi (${res.statusCode})', 'Could not delete (${res.statusCode})');
  } catch (_) {
    return t('Sunucuya ulaşılamadı', 'Could not reach the server');
  }
}

// ---------------- ROZET ----------------
const List<Color> _badgeColors = [
  Color(0xFF00897B),
  Color(0xFFF57C00),
  Color(0xFF7B1FA2),
  Color(0xFF1976D2),
  Color(0xFFC2185B),
  Color(0xFF5D4037),
  Color(0xFF388E3C),
  Color(0xFFD32F2F),
  Color(0xFF455A64),
  Color(0xFF6A1B9A),
];

int _hash(String s) {
  var h = 0;
  for (final r in s.runes) {
    h = (h * 31 + r) & 0x7fffffff;
  }
  return h;
}

/// Ülkenin silüetini içeren, hafif eğik duran yuvarlak köşeli sticker.
class StickerBadge extends StatelessWidget {
  const StickerBadge({
    super.key,
    required this.country,
    this.city,
    this.date,
    this.size = 112,
  });

  final String country;
  final String? city;
  final String? date;
  final double size;

  @override
  Widget build(BuildContext context) {
    final h = _hash(country);
    final base = _badgeColors[h % _badgeColors.length];
    final angle = ((h % 9) - 4) * 0.018;
    final shape = countryShape(country);
    final hasCity = city != null && city!.isNotEmpty;
    final label = hasCity ? cityn(city!) : cn(country);
    final sub = hasCity ? cn(country) : null;

    Widget line(String text, double fs, FontWeight fw, double alpha) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              color: Colors.white.withValues(alpha: alpha),
              fontSize: fs,
              fontWeight: fw,
            ),
          ),
        );

    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.08),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, Color.lerp(base, Colors.black, 0.38)!],
          ),
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(color: Colors.white, width: size * 0.03),
          boxShadow: [
            BoxShadow(
              blurRadius: 6,
              offset: const Offset(0, 3),
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: shape == null
                  ? Center(child: Icon(Icons.public, color: Colors.white70, size: size * 0.4))
                  : CustomPaint(painter: _SilhouettePainter(shape), size: Size.infinite),
            ),
            SizedBox(height: size * 0.03),
            line(label, size * 0.12, FontWeight.w800, 1),
            if (sub != null) line(sub, size * 0.085, FontWeight.w500, 0.85),
            if (date != null) line(date!, size * 0.08, FontWeight.w500, 0.75),
          ],
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter(this.rings);
  final List<List<double>> rings;

  double _meanLon(List<double> r) {
    final n = r.length ~/ 2;
    var s = 0.0;
    for (var i = 0; i < n; i++) {
      s += r[2 * i + 1];
    }
    return n == 0 ? 0 : s / n;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (rings.isEmpty || size.width <= 0 || size.height <= 0) return;
    var ref = rings.first;
    for (final r in rings) {
      if (r.length > ref.length) ref = r;
    }
    final refMean = _meanLon(ref);

    // her halkayı ±180° çizgisini aşmayacak biçimde ortak bir boylama taşı
    final polys = <List<Offset>>[];
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final r in rings) {
      final n = r.length ~/ 2;
      if (n < 3) continue;
      var shift = 0.0;
      final m = _meanLon(r);
      while (m + shift - refMean > 180) {
        shift -= 360;
      }
      while (m + shift - refMean < -180) {
        shift += 360;
      }
      final pts = <Offset>[];
      double? prev;
      for (var i = 0; i < n; i++) {
        var lon = r[2 * i + 1] + shift;
        if (prev != null) {
          while (lon - prev > 180) {
            lon -= 360;
          }
          while (lon - prev < -180) {
            lon += 360;
          }
        }
        prev = lon;
        final lat = r[2 * i];
        pts.add(Offset(lon, lat));
        minX = math.min(minX, lon);
        maxX = math.max(maxX, lon);
        minY = math.min(minY, lat);
        maxY = math.max(maxY, lat);
      }
      polys.add(pts);
    }
    if (polys.isEmpty) return;

    final midLat = (minY + maxY) / 2 * math.pi / 180;
    final kx = math.cos(midLat).clamp(0.25, 1.0).toDouble();
    final w = math.max((maxX - minX) * kx, 0.0001);
    final h = math.max(maxY - minY, 0.0001);
    final scale = math.min(size.width / w, size.height / h);
    final ox = (size.width - w * scale) / 2;
    final oy = (size.height - h * scale) / 2;

    final fill = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final edge = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeJoin = StrokeJoin.round;
    for (final pts in polys) {
      final path = Path();
      for (var i = 0; i < pts.length; i++) {
        final x = ox + (pts[i].dx - minX) * kx * scale;
        final y = oy + (maxY - pts[i].dy) * scale;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, edge);
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter old) => !identical(old.rings, rings);
}

// ---------------- İSTATİSTİK + ÖZET ----------------
class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: tt.bodySmall),
      ],
    );
  }
}

Widget _statsRow(BuildContext context, List<Map<String, dynamic>> list) {
  final countries = list.map((s) => '${s['country']}').toSet().length;
  final cities = list
      .where((s) => s['city'] != null && '${s['city']}'.isNotEmpty)
      .map((s) => '${s['country']}|${s['city']}')
      .toSet()
      .length;
  final total = kCountries.length;
  final pct = total == 0 ? 0.0 : countries * 100 / total;
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat('$countries/$total', t('Ülke', 'Countries')),
          _Stat('$cities', t('Şehir', 'Cities')),
          _Stat('%${pct.toStringAsFixed(pct < 10 && countries > 0 ? 1 : 0)}', t('Dünya', 'World')),
        ],
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(value: total == 0 ? 0 : countries / total, minHeight: 8),
      ),
    ],
  );
}

/// Profilde gösterilen kısa sticker özeti.
class StickerSummary extends StatelessWidget {
  const StickerSummary({super.key, required this.stickers});
  final List<Map<String, dynamic>> stickers;

  void _open(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const StickerAlbumPage()));

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(t('Sticker koleksiyonum', 'My sticker collection'),
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              _statsRow(context, stickers),
              const SizedBox(height: 14),
              if (stickers.isEmpty)
                Text(
                  t('Gittiğin yerlerin stickerlarını burada biriktir. Başlamak için dokun.',
                      'Collect stickers of the places you have been. Tap to start.'),
                  style: tt.bodySmall,
                )
              else
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      for (final s in stickers.take(10))
                        Padding(
                          padding: const EdgeInsets.only(right: 12, top: 4),
                          child: StickerBadge(
                            country: '${s['country']}',
                            city: s['city'] == null ? null : '${s['city']}',
                            size: 88,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- ALBÜM ----------------
class StickerAlbumPage extends StatelessWidget {
  const StickerAlbumPage({super.key});

  void _detail(BuildContext context, Map<String, dynamic> s) {
    final city = s['city'] == null ? null : '${s['city']}';
    final date = _fmtDate(s['visitedOn']);
    final note = s['note'] == null ? '' : '${s['note']}';
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StickerBadge(country: '${s['country']}', city: city, date: date, size: 168),
              const SizedBox(height: 16),
              if (note.isNotEmpty)
                Text(note, textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.bodyLarge),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: Text(t('Stickerı sil', 'Delete sticker')),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final err = await removeSticker(s['id']);
                  if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('Sticker koleksiyonum', 'My sticker collection'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddStickerDialog(context),
        icon: const Icon(Icons.add),
        label: Text(t('Sticker ekle', 'Add sticker')),
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: myStickers,
        builder: (context, list, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _statsRow(context, list),
              ),
            ),
            const SizedBox(height: 20),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  t('Henüz sticker yok. Gittiğin bir ülkeyi ekleyerek başla.',
                      'No stickers yet. Start by adding a country you have visited.'),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 18,
                children: [
                  for (final s in list)
                    GestureDetector(
                      onTap: () => _detail(context, s),
                      child: StickerBadge(
                        country: '${s['country']}',
                        city: s['city'] == null ? null : '${s['city']}',
                        date: _fmtDate(s['visitedOn']),
                        size: 104,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- EKLEME DİYALOĞU ----------------
String _fold(String text) {
  const from = 'İIıÇçĞğÖöŞşÜü';
  const to = 'iiiccggoossuu';
  final b = StringBuffer();
  for (final r in text.runes) {
    final ch = String.fromCharCode(r);
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch.toLowerCase());
  }
  return b.toString();
}

Future<void> showAddStickerDialog(BuildContext context, {Country? initial}) async {
  Country? country = initial;
  final city = TextEditingController();
  final note = TextEditingController();
  DateTime? date;
  String? error;
  final messenger = ScaffoldMessenger.of(context);

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Text(t('Sticker ekle', 'Add sticker')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<Country>(
                initialValue: TextEditingValue(text: initial == null ? '' : cn(initial.name)),
                displayStringForOption: (c) => cn(c.name),
                optionsBuilder: (v) {
                  final q = _fold(v.text.trim());
                  if (q.isEmpty) return const Iterable<Country>.empty();
                  return kCountries
                      .where((c) =>
                          _fold(cn(c.name)).contains(q) || _fold(c.name).contains(q))
                      .take(8);
                },
                onSelected: (c) => setS(() {
                  country = c;
                  error = null;
                }),
                fieldViewBuilder: (ctx, controller, focus, onSubmit) => TextField(
                  controller: controller,
                  focusNode: focus,
                  decoration: InputDecoration(
                    labelText: t('Ülke', 'Country'),
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: city,
                decoration: InputDecoration(
                  labelText: t('Şehir (isteğe bağlı)', 'City (optional)'),
                  prefixIcon: const Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(date == null
                      ? t('Tarih seç (isteğe bağlı)', 'Pick a date (optional)')
                      : '${_two(date!.day)}.${_two(date!.month)}.${date!.year}'),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: date ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setS(() => date = d);
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLength: 200,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: t('Not (isteğe bağlı)', 'Note (optional)'),
                  prefixIcon: const Icon(Icons.edit_note),
                ),
              ),
              if (error != null)
                Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('Vazgeç', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (country == null) {
                setS(() => error = t('Listeden bir ülke seç.', 'Pick a country from the list.'));
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: Text(t('Ekle', 'Add')),
          ),
        ],
      ),
    ),
  );

  final picked = country;
  if (ok != true || picked == null) return;
  final cityText = city.text.trim();
  final noteText = note.text.trim();
  final err = await addSticker(
    picked.name,
    city: cityText.isEmpty ? null : cityText,
    date: date,
    note: noteText.isEmpty ? null : noteText,
  );
  messenger.showSnackBar(SnackBar(
    content: Text(err ?? t('Sticker koleksiyonuna eklendi!', 'Added to your collection!')),
  ));
}
