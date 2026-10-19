import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'l10n.dart';

class _DayWeather {
  final DateTime date;
  final int code;
  final double max;
  final double min;
  _DayWeather(this.date, this.code, this.max, this.min);
}

class _WeatherData {
  final String place;
  final double temp;
  final double feels;
  final int code;
  final double wind;
  final List<_DayWeather> days;
  _WeatherData(this.place, this.temp, this.feels, this.code, this.wind, this.days);
}

class _Look {
  final IconData icon;
  final String tr;
  final String en;
  const _Look(this.icon, this.tr, this.en);
}

_Look _look(int code) {
  if (code == 0) return const _Look(Icons.wb_sunny, 'Açık', 'Clear');
  if (code == 1 || code == 2) return const _Look(Icons.cloud_queue, 'Parçalı bulutlu', 'Partly cloudy');
  if (code == 3) return const _Look(Icons.cloud, 'Bulutlu', 'Cloudy');
  if (code == 45 || code == 48) return const _Look(Icons.foggy, 'Sisli', 'Foggy');
  if (code >= 51 && code <= 57) return const _Look(Icons.grain, 'Çiseleme', 'Drizzle');
  if (code >= 61 && code <= 67) return const _Look(Icons.water_drop, 'Yağmurlu', 'Rain');
  if (code >= 71 && code <= 77) return const _Look(Icons.ac_unit, 'Karlı', 'Snow');
  if (code >= 80 && code <= 82) return const _Look(Icons.umbrella, 'Sağanak', 'Showers');
  if (code == 85 || code == 86) return const _Look(Icons.ac_unit, 'Kar sağanağı', 'Snow showers');
  if (code >= 95) return const _Look(Icons.thunderstorm, 'Gök gürültülü fırtına', 'Thunderstorm');
  return const _Look(Icons.cloud_queue, 'Değişken', 'Mixed');
}

String _fold(String s) => s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

Future<_WeatherData?> _fetchWeather(String city, String country) async {
  try {
    final lang = appLang.value;
    final g = await http
        .get(Uri.parse('https://geocoding-api.open-meteo.com/v1/search'
            '?name=${Uri.encodeQueryComponent(city)}&count=5&language=$lang&format=json'))
        .timeout(const Duration(seconds: 12));
    if (g.statusCode != 200) return null;
    final gj = jsonDecode(utf8.decode(g.bodyBytes));
    final results = (gj is Map && gj['results'] is List) ? gj['results'] as List : const [];
    if (results.isEmpty) return null;
    var pick = results.first as Map;
    final want = _fold(country);
    for (final r in results) {
      if (r is Map && _fold('${r['country'] ?? ''}') == want) {
        pick = r;
        break;
      }
    }
    final lat = (pick['latitude'] as num).toDouble();
    final lon = (pick['longitude'] as num).toDouble();

    final w = await http
        .get(Uri.parse('https://api.open-meteo.com/v1/forecast'
            '?latitude=$lat&longitude=$lon'
            '&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m'
            '&daily=weather_code,temperature_2m_max,temperature_2m_min'
            '&timezone=auto&forecast_days=5'))
        .timeout(const Duration(seconds: 12));
    if (w.statusCode != 200) return null;
    final wj = jsonDecode(utf8.decode(w.bodyBytes)) as Map<String, dynamic>;
    final cur = wj['current'] as Map<String, dynamic>;
    final daily = wj['daily'] as Map<String, dynamic>;
    final times = daily['time'] as List;
    final codes = daily['weather_code'] as List;
    final maxs = daily['temperature_2m_max'] as List;
    final mins = daily['temperature_2m_min'] as List;
    final days = <_DayWeather>[];
    for (var i = 0; i < times.length; i++) {
      days.add(_DayWeather(
        DateTime.parse('${times[i]}'),
        (codes[i] as num).toInt(),
        (maxs[i] as num).toDouble(),
        (mins[i] as num).toDouble(),
      ));
    }
    return _WeatherData(
      '${pick['name'] ?? city}',
      (cur['temperature_2m'] as num).toDouble(),
      (cur['apparent_temperature'] as num).toDouble(),
      (cur['weather_code'] as num).toInt(),
      (cur['wind_speed_10m'] as num).toDouble(),
      days,
    );
  } catch (_) {
    return null;
  }
}

/// Şehrin güncel hava durumu ve 5 günlük tahmini (Open-Meteo, anahtar gerekmez).
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key, required this.city, required this.country});
  final String city;
  final String country;

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  late final Future<_WeatherData?> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchWeather(widget.city, widget.country);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return FutureBuilder<_WeatherData?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(
            margin: EdgeInsets.zero,
            child: SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        final w = snap.data;
        if (w == null) return const SizedBox.shrink();
        final now = _look(w.code);
        final dayNames = appLang.value == 'en'
            ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            : ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(now.icon, size: 44, color: cs.primary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${w.temp.round()}°C',
                            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        Text(appLang.value == 'en' ? now.en : now.tr),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(t('Hissedilen ${w.feels.round()}°', 'Feels like ${w.feels.round()}°'),
                            style: tt.bodySmall),
                        Text(t('Rüzgâr ${w.wind.round()} km/s', 'Wind ${w.wind.round()} km/h'),
                            style: tt.bodySmall),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final d in w.days)
                      Column(
                        children: [
                          Text(dayNames[d.date.weekday - 1], style: tt.labelMedium),
                          const SizedBox(height: 4),
                          Icon(_look(d.code).icon, size: 22, color: cs.primary),
                          const SizedBox(height: 4),
                          Text('${d.max.round()}°',
                              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                          Text('${d.min.round()}°',
                              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Open-Meteo', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        );
      },
    );
  }
}
