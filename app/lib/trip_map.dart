import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'l10n.dart';

class _Pin {
  final int day;
  final int order;
  final String name;
  final String? note;
  LatLng? pos;
  bool approx = false;
  _Pin(this.day, this.order, this.name, this.note, this.pos);
}

/// Gezideki durakları harita üzerinde gösterir (OpenStreetMap).
/// Konumu olmayan duraklar Nominatim ile aranır.
class TripMapPage extends StatefulWidget {
  const TripMapPage({super.key, required this.trip});
  final Map<String, dynamic> trip;

  @override
  State<TripMapPage> createState() => _TripMapPageState();
}

class _TripMapPageState extends State<TripMapPage> {
  static final Map<String, LatLng?> _geoCache = {};
  static const _colors = [
    Color(0xFF00897B),
    Color(0xFFF57C00),
    Color(0xFF7B1FA2),
    Color(0xFF1976D2),
    Color(0xFFC2185B),
    Color(0xFF5D4037),
    Color(0xFF388E3C),
  ];

  final MapController _mc = MapController();
  final List<_Pin> _pins = [];
  bool _ready = false;
  bool _geocoding = false;
  bool _disposed = false;
  int _day = 0; // 0 = hepsi
  _Pin? _sel;

  Color _color(int day) => _colors[(day - 1) % _colors.length];

  List<_Pin> _visible() =>
      _pins.where((p) => p.pos != null && (_day == 0 || p.day == _day)).toList();

  @override
  void initState() {
    super.initState();
    final days = (widget.trip['days'] as List?) ?? const [];
    for (final d in days) {
      final dayNo = (d['dayNumber'] as num).toInt();
      final stops = (d['stops'] as List?) ?? const [];
      for (var i = 0; i < stops.length; i++) {
        final s = stops[i];
        final lat = (s['latitude'] as num?)?.toDouble();
        final lon = (s['longitude'] as num?)?.toDouble();
        final note = '${s['note'] ?? ''}'.trim();
        _pins.add(_Pin(
          dayNo,
          i + 1,
          '${s['name']}',
          note.isEmpty ? null : note,
          (lat != null && lon != null) ? LatLng(lat, lon) : null,
        ));
      }
    }
    _geocodeMissing();
  }

  @override
  void dispose() {
    _disposed = true;
    _mc.dispose();
    super.dispose();
  }

  Future<LatLng?> _nominatim(String q) async {
    try {
      final res = await http
          .get(
            Uri.parse('https://nominatim.openstreetmap.org/search'
                '?format=json&limit=1&q=${Uri.encodeQueryComponent(q)}'),
            headers: kIsWeb ? null : {'User-Agent': 'ExploreWorld/1.0'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      if (j is List && j.isNotEmpty) {
        final lat = double.tryParse('${j.first['lat']}');
        final lon = double.tryParse('${j.first['lon']}');
        if (lat != null && lon != null) return LatLng(lat, lon);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _geocodeMissing() async {
    final todo = _pins.where((p) => p.pos == null).toList();
    if (todo.isEmpty) return;
    setState(() => _geocoding = true);
    for (final p in todo) {
      if (_disposed) return;
      final q = '${p.name}, ${widget.trip['city'] ?? ''}, ${widget.trip['country'] ?? ''}';
      if (_geoCache.containsKey(q)) {
        p.pos = _geoCache[q];
      } else {
        final pos = await _nominatim(q);
        _geoCache[q] = pos;
        p.pos = pos;
        await Future.delayed(const Duration(milliseconds: 1100)); // Nominatim kuralı: saniyede 1 istek
      }
      p.approx = true;
      if (!mounted) return;
      setState(() {});
      _fit();
    }
    if (mounted) setState(() => _geocoding = false);
  }

  void _fit() {
    if (!_ready) return;
    final pts = _visible().map((p) => p.pos!).toList();
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _mc.move(pts.first, 14);
      return;
    }
    _mc.fitCamera(CameraFit.coordinates(
      coordinates: pts,
      padding: const EdgeInsets.fromLTRB(48, 110, 48, 150),
      maxZoom: 16,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dayCount = ((widget.trip['days'] as List?) ?? const []).length;
    final visible = _visible();
    final lines = <Polyline>[];
    for (var d = 1; d <= dayCount; d++) {
      if (_day != 0 && _day != d) continue;
      final pts = visible.where((p) => p.day == d).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      if (pts.length >= 2) {
        lines.add(Polyline(
          points: pts.map((p) => p.pos!).toList(),
          strokeWidth: 4,
          color: _color(d).withValues(alpha: 0.8),
        ));
      }
    }
    final unlocated = _pins.where((p) => p.pos == null).length;

    return Scaffold(
      appBar: AppBar(title: Text(t('Gezi haritası', 'Trip map'))),
      body: _pins.isEmpty
          ? Center(child: Text(t('Bu gezide henüz durak yok.', 'This trip has no stops yet.')))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mc,
                  options: MapOptions(
                    initialCenter: const LatLng(20, 0),
                    initialZoom: 2,
                    onMapReady: () {
                      _ready = true;
                      _fit();
                    },
                    onTap: (_, __) => setState(() => _sel = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.exploreworld.app',
                    ),
                    PolylineLayer(polylines: lines),
                    MarkerLayer(
                      markers: [
                        for (final p in visible)
                          Marker(
                            point: p.pos!,
                            width: 38,
                            height: 38,
                            child: GestureDetector(
                              onTap: () => setState(() => _sel = p),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _color(p.day),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
                                ),
                                child: Text(
                                  '${p.order}',
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t('Tümü', 'All')),
                            selected: _day == 0,
                            onSelected: (_) {
                              setState(() {
                                _day = 0;
                                _sel = null;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
                            },
                          ),
                        ),
                        for (var d = 1; d <= dayCount; d++)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: CircleAvatar(backgroundColor: _color(d), radius: 6),
                              label: Text(t('$d. Gün', 'Day $d')),
                              selected: _day == d,
                              onSelected: (_) {
                                setState(() {
                                  _day = d;
                                  _sel = null;
                                });
                                WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_geocoding)
                  Positioned(
                    top: 58,
                    left: 12,
                    right: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('Duraklar haritada aranıyor...', 'Looking up stops on the map...'),
                                style: tt.bodySmall),
                            const SizedBox(height: 6),
                            const LinearProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!_geocoding && unlocated > 0)
                  Positioned(
                    top: 58,
                    left: 12,
                    right: 12,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          t('$unlocated durak haritada bulunamadı.', '$unlocated stop(s) could not be located.'),
                          style: tt.bodySmall,
                        ),
                      ),
                    ),
                  ),
                if (_sel != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Card(
                      color: cs.surfaceContainerHigh,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _color(_sel!.day),
                          child: Text('${_sel!.order}', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(_sel!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([
                          t('${_sel!.day}. Gün', 'Day ${_sel!.day}'),
                          if (_sel!.note != null) _sel!.note!,
                          if (_sel!.approx) t('yaklaşık konum', 'approximate location'),
                        ].join(' · ')),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
