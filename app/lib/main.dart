import 'splash.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ai_plan.dart';
import 'city_photos.dart';
import 'explore.dart';
import 'l10n.dart';
import 'names_en.dart';
import 'profile_edit.dart';
import 'stickers.dart';
import 'trip_map.dart';
import 'trip_share.dart';
import 'weather.dart';

final String baseUrl = kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
String? authToken;

Map<String, String> authHeaders() => {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = await loadPrefs();
  themeMode.value = ThemeMode.values.firstWhere((m) => m.name == theme, orElse: () => ThemeMode.system);
  runApp(const ExploreApp());
}

/// Açık / koyu / sistem teması (Profil sekmesinden değişir).
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

ThemeData _buildTheme(Brightness brightness, Color seed) {
  final cs = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class ExploreApp extends StatelessWidget {
  const ExploreApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: accentColor,
      builder: (_, seed, __) => ValueListenableBuilder<ThemeMode>(
        valueListenable: themeMode,
        builder: (_, mode, __) => MaterialApp(
          title: 'Zaino',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light, seed),
          darkTheme: _buildTheme(Brightness.dark, seed),
          themeMode: mode,
          home: const SplashPage(),
        ),
      ),
    );
  }
}

// ---------------- GİRİŞ / KAYIT ----------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(text: 'test@test.com');
  final _password = TextEditingController(text: '12345678');
  final _name = TextEditingController();
  bool _register = false;
  String? _error;
  bool _loading = false;

  String _errorFrom(http.Response res, String fallback) {
    try {
      final j = jsonDecode(utf8.decode(res.bodyBytes));
      if (j is Map) {
        final m = j['message'] ?? j['error'] ?? j['detail'];
        if (m is String && m.isNotEmpty) return m;
      }
    } catch (_) {}
    return '$fallback (${res.statusCode})';
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_register) {
        final r = await http.post(
          Uri.parse('$baseUrl/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _email.text.trim(),
            'password': _password.text,
            'displayName': _name.text.trim(),
          }),
        );
        if (r.statusCode != 200 && r.statusCode != 201) {
          setState(() => _error = _errorFrom(r, t('Kayıt başarısız', 'Sign-up failed')));
          return;
        }
      }
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email.text.trim(), 'password': _password.text}),
      );
      if (res.statusCode == 200) {
        authToken = jsonDecode(res.body)['token'];
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainShell()));
      } else {
        setState(() => _error = _errorFrom(res, t('Giriş başarısız', 'Login failed')));
      }
    } catch (e) {
      setState(() => _error = t('Sunucuya ulaşılamadı', 'Could not reach the server'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primaryContainer, cs.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MiniGlobe(size: 190),
                    const SizedBox(height: 8),
                    Text('Zaino',
                        style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(t('Yapay zekâ destekli seyahat rehberin', 'Your AI-powered travel guide'),
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (_register) ...[
                              TextField(
                                controller: _name,
                                decoration: InputDecoration(
                                  labelText: t('Adın', 'Your name'),
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: t('E-posta', 'Email'),
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _password,
                              obscureText: true,
                              onSubmitted: (_) => _loading ? null : _submit(),
                              decoration: InputDecoration(
                                labelText: t('Şifre', 'Password'),
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!, style: TextStyle(color: cs.error)),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: _loading ? null : _submit,
                                child: Text(_loading
                                    ? t('Bekleyin...', 'Please wait...')
                                    : (_register ? t('Kayıt ol', 'Sign up') : t('Giriş yap', 'Log in'))),
                              ),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => setState(() {
                                        _register = !_register;
                                        _error = null;
                                      }),
                              child: Text(_register
                                  ? t('Hesabın var mı? Giriş yap', 'Already have an account? Log in')
                                  : t('Hesabın yok mu? Kayıt ol', 'No account yet? Sign up')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- ANA KABUK (ALT MENÜ) ----------------
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  int _favGen = 0;
  int _tripGen = 0;

  @override
  void initState() {
    super.initState();
    fetchProfile(); // vurgu rengini uygular
    loadStickers();
  }

  void _select(int i) {
    setState(() {
      if (i == 1) _favGen++; // sekmeye her girişte liste yenilensin
      if (i == 2) _tripGen++;
      _tab = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const ExplorePage(),
          FavoritesPage(key: ValueKey('fav$_favGen')),
          HomePage(key: ValueKey('trips$_tripGen')),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
              icon: Icon(Icons.public_outlined),
              selectedIcon: Icon(Icons.public),
              label: t('Keşfet', 'Explore')),
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: t('Favoriler', 'Favorites')),
          NavigationDestination(
              icon: Icon(Icons.luggage_outlined),
              selectedIcon: Icon(Icons.luggage),
              label: t('Seyahatlerim', 'My trips')),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: t('Profil', 'Profile')),
        ],
      ),
    );
  }
}

// ---------------- PROFİL ----------------
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _me;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final j = await fetchProfile();
    if (j != null && mounted) setState(() => _me = j);
  }

  Future<void> _edit() async {
    final updated = await showEditProfileDialog(context, _me ?? <String, dynamic>{});
    if (updated != null && mounted) setState(() => _me = updated);
  }

  void _logout() {
    authToken = null;
    accentColor.value = kDefaultAccent;
    myStickers.value = <Map<String, dynamic>>[];
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final name = '${_me?['displayName'] ?? _me?['name'] ?? t('Gezgin', 'Traveler')}';
    final email = '${_me?['email'] ?? ''}';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Profil', 'Profile')),
        actions: [
          IconButton(
            tooltip: t('Profili düzenle', 'Edit profile'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: cs.primaryContainer,
              child: Text(initial,
                  style: tt.displaySmall?.copyWith(color: cs.onPrimaryContainer)),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(name, style: tt.titleLarge)),
          if (email.isNotEmpty)
            Center(
              child: Text(email, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
          if ('${_me?['bio'] ?? ''}'.isNotEmpty) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                '“${_me?['bio']}”',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: myStickers,
            builder: (_, list, __) => StickerSummary(stickers: list),
          ),
          const SizedBox(height: 28),
          Text(t('Görünüm', 'Appearance'), style: tt.titleSmall),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (_, mode, __) => SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text(t('Sistem', 'System'))),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text(t('Açık', 'Light'))),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text(t('Koyu', 'Dark'))),
              ],
              selected: {mode},
              onSelectionChanged: (s) {
                themeMode.value = s.first;
                savePref('theme', s.first.name);
              },
            ),
          ),
          const SizedBox(height: 28),
          Text(t('Dil', 'Language'), style: tt.titleSmall),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: appLang,
            builder: (_, lang, __) => SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'tr', label: Text('Türkçe')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {lang},
              onSelectionChanged: (s) {
                appLang.value = s.first;
                savePref('lang', s.first);
                rebuildAll();
              },
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: Text(t('Çıkış yap', 'Log out')),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(t('Zaino · yapay zekâ destekli seyahat rehberi', 'Zaino · AI-powered travel guide'),
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

// ---------------- SEYAHATLERİM ----------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/trips?_=${DateTime.now().millisecondsSinceEpoch}'),
        headers: authHeaders(),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        if (!mounted) return;
        setState(() {
          _trips = list;
          _loading = false;
          _error = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = t('Liste alınamadı (${res.statusCode})', 'Could not load the list (${res.statusCode})');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t('Sunucuya ulaşılamadı', 'Could not reach the server');
      });
    }
  }

  Future<void> _addTrip() async {
    final created = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTripPage()),
    );
    if (created == null) return;

    setState(() {
      _trips = [created, ..._trips.where((t) => t['id'] != created['id'])];
    });

    await Future.delayed(const Duration(milliseconds: 700));
    await _load();

    if (!mounted) return;
    if (!_trips.any((t) => t['id'] == created['id'])) {
      setState(() => _trips = [created, ..._trips]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Seyahatlerim', 'My trips')),
        actions: [
          IconButton(
            tooltip: t('Yenile', 'Refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTrip,
        icon: const Icon(Icons.add),
        label: Text(t('Yeni gezi', 'New trip')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _trips.isEmpty
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _trips.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 120),
                          Icon(Icons.luggage_outlined, size: 64, color: cs.outline),
                          const SizedBox(height: 12),
                          Center(child: Text(t('Henüz gezin yok.', 'No trips yet.'))),
                          const SizedBox(height: 4),
                          Center(child: Text(t('Aşağıdaki "Yeni gezi" düğmesiyle başla.', 'Start with the "New trip" button below.'))),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: _trips.length,
                          itemBuilder: (context, i) {
                            final trip = _trips[i];
                            final days = (trip['days'] is List)
                                ? (trip['days'] as List).length
                                : (trip['dayCount'] ?? '?');
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  child: Icon(Icons.luggage, color: cs.onPrimaryContainer),
                                ),
                                title: Text('${trip['title'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    t('${trip['city'] ?? ''}, ${trip['country'] ?? ''} · $days gün', '${trip['city'] ?? ''}, ${trip['country'] ?? ''} · $days days')),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => TripDetailPage(tripId: trip['id'])),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

// ---------------- YENİ GEZİ ----------------
class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});
  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _title = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _days = TextEditingController(text: '3');
  String? _error;
  bool _saving = false;

  Future<void> _save() async {
    final days = int.tryParse(_days.text.trim()) ?? 0;
    if (_title.text.trim().isEmpty ||
        _city.text.trim().isEmpty ||
        _country.text.trim().isEmpty ||
        days < 1 ||
        days > 30) {
      setState(() => _error = t('Tüm alanları doldur (gün 1-30).', 'Fill in all fields (days 1-30).'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trips'),
        headers: authHeaders(),
        body: jsonEncode({
          'title': _title.text.trim(),
          'city': _city.text.trim(),
          'country': _country.text.trim(),
          'dayCount': days,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        if (!mounted) return;
        Navigator.pop(context, {
          'id': body['id'],
          'title': body['title'] ?? _title.text.trim(),
          'city': body['city'] ?? _city.text.trim(),
          'country': body['country'] ?? _country.text.trim(),
          'dayCount': days,
        });
      } else {
        setState(() => _error = t('Kaydedilemedi (${res.statusCode})', 'Could not save (${res.statusCode})'));
      }
    } catch (e) {
      setState(() => _error = t('Hata: $e', 'Error: $e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('Yeni gezi', 'New trip'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
              controller: _title,
              decoration: InputDecoration(
                  labelText: t('Başlık', 'Title'), border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _city,
              decoration: InputDecoration(
                  labelText: t('Şehir', 'City'), border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _country,
              decoration: InputDecoration(
                  labelText: t('Ülke', 'Country'), border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _days,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: t('Gün sayısı', 'Number of days'), border: OutlineInputBorder())),
          const SizedBox(height: 12),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? t('Kaydediliyor...', 'Saving...') : t('Kaydet', 'Save')),
          ),
        ],
      ),
    );
  }
}

// ---------------- GEZİ DETAYI ----------------
class TripDetailPage extends StatefulWidget {
  final dynamic tripId;
  const TripDetailPage({super.key, required this.tripId});
  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  Map<String, dynamic>? _trip;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse(
            '$baseUrl/api/trips/${widget.tripId}?_=${DateTime.now().millisecondsSinceEpoch}'),
        headers: authHeaders(),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _trip = jsonDecode(utf8.decode(res.bodyBytes));
          _error = null;
        });
      } else {
        if (!mounted) return;
        setState(() => _error = t('Yüklenemedi (${res.statusCode})', 'Could not load (${res.statusCode})'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = t('Sunucuya ulaşılamadı', 'Could not reach the server'));
    }
  }

  Future<void> _addStop(int dayNumber) async {
    final name = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('$dayNumber. gün - durak ekle', 'Day $dayNumber - add stop')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: t('Yer adı', 'Place name'), border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: note,
                decoration: InputDecoration(
                    labelText: t('Not (isteğe bağlı)', 'Note (optional)'), border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('Vazgeç', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t('Ekle', 'Add'))),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trips/${widget.tripId}/stops'),
        headers: authHeaders(),
        body: jsonEncode({
          'dayNumber': dayNumber,
          'name': name.text.trim(),
          'latitude': null,
          'longitude': null,
          'note': note.text.trim().isEmpty ? null : note.text.trim(),
        }),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        _msg(t('Eklenemedi (${res.statusCode})', 'Could not add (${res.statusCode})'));
      }
    } catch (e) {
      _msg(t('Sunucuya ulaşılamadı', 'Could not reach the server'));
    }
    await _load();
  }

  // position: gün içindeki yeni sıra (1'den başlar)
  Future<void> _move(dynamic stopId, int dayNumber, int position) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/trips/${widget.tripId}/stops/$stopId/move'),
        headers: authHeaders(),
        body: jsonEncode({'dayNumber': dayNumber, 'position': position}),
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        _msg(t('Taşınamadı (${res.statusCode})', 'Could not move (${res.statusCode})'));
      }
    } catch (e) {
      _msg(t('Sunucuya ulaşılamadı', 'Could not reach the server'));
    }
    await _load();
  }

  Future<void> _delete(dynamic stopId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/trips/${widget.tripId}/stops/$stopId'),
        headers: authHeaders(),
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        _msg(t('Silinemedi (${res.statusCode})', 'Could not delete (${res.statusCode})'));
      }
    } catch (e) {
      _msg(t('Sunucuya ulaşılamadı', 'Could not reach the server'));
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final days = (_trip?['days'] as List<dynamic>?) ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text('${_trip?['title'] ?? t('Gezi', 'Trip')}'),
        actions: [
          if (_trip != null)
            IconButton(
              tooltip: t('Haritada gör', 'View on map'),
              icon: const Icon(Icons.map_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TripMapPage(trip: _trip!)),
              ),
            ),
          if (_trip != null)
            IconButton(
              tooltip: t('Paylaş', 'Share'),
              icon: const Icon(Icons.share_outlined),
              onPressed: () => shareTrip(context, _trip!),
            ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : _trip == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final d in days) ...[
                      Text(t('${d['dayNumber']}. Gün', 'Day ${d['dayNumber']}'),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal)),
                      const SizedBox(height: 6),
                      if ((d['stops'] as List<dynamic>? ?? []).isEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(t('Henüz durak yok', 'No stops yet')),
                        ),
                      ..._stopCards(d),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _addStop(d['dayNumber'] as int),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: Text(t('Durak ekle', 'Add stop')),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
    );
  }

  List<Widget> _stopCards(Map<String, dynamic> day) {
    final stops = (day['stops'] as List<dynamic>? ?? []);
    final dayNumber = day['dayNumber'] as int;
    final cards = <Widget>[];
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final isFirst = i == 0;
      final isLast = i == stops.length - 1;
      cards.add(Card(
        child: ListTile(
          leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
          title: Text('${s['name']}'),
          subtitle: (s['note'] != null && '${s['note']}'.isNotEmpty)
              ? Text('${s['note']}')
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: t('Yukarı', 'Up'),
                icon: const Icon(Icons.arrow_upward),
                onPressed: isFirst ? null : () => _move(s['id'], dayNumber, i),
              ),
              IconButton(
                tooltip: t('Aşağı', 'Down'),
                icon: const Icon(Icons.arrow_downward),
                onPressed: isLast ? null : () => _move(s['id'], dayNumber, i + 2),
              ),
              IconButton(
                tooltip: t('Sil', 'Delete'),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(s['id']),
              ),
            ],
          ),
        ),
      ));
    }
    return cards;
  }
}

// ---------------- YAPAY ZEKÂ REHBERİ ----------------
class _GuideLine {
  final String text;
  final bool isHeader;
  final String? favType; // PLACE / FOOD
  final String? favName;
  final String? note;
  _GuideLine(this.text,
      {this.isHeader = false, this.favType, this.favName, this.note});
}

class AiGuidePage extends StatefulWidget {
  const AiGuidePage({super.key, this.initialCity, this.initialCountry});
  final String? initialCity;
  final String? initialCountry;
  @override
  State<AiGuidePage> createState() => _AiGuidePageState();
}

class _AiGuidePageState extends State<AiGuidePage> {
  final _city = TextEditingController(text: cityn('Roma'));
  final _country = TextEditingController(text: cn('İtalya'));
  List<_GuideLine>? _lines;
  String _genCity = '';
  String _genCountry = '';
  String? _error;
  bool _loading = false;
  final Map<String, dynamic> _favIds = {}; // "TYPE|ad" -> favori id

  @override
  void initState() {
    super.initState();
    if (widget.initialCity != null) {
      _city.text = widget.initialCity!;
      _country.text = widget.initialCountry ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
    }
  }

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

  List<_GuideLine> _parse(String text) {
    final result = <_GuideLine>[];
    String section = '';
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final clean = line
          .replaceAll(RegExp(r'^[#*\s]+'), '')
          .replaceAll(RegExp(r'[*\s:]+$'), '');
      final isHeader = clean.length < 40 &&
          (clean.startsWith('Kısaca') ||
              clean.startsWith('Mutlaka') ||
              clean.startsWith('Ne yenir') ||
              clean.startsWith('İpucu') ||
              clean.startsWith('Ipucu') ||
              clean.startsWith('Overview') ||
              clean.startsWith('Must') ||
              clean.startsWith('What to eat') ||
              clean.startsWith('Tips'));
      if (isHeader) {
        if (clean.startsWith('Mutlaka') || clean.startsWith('Must')) {
          section = 'PLACE';
        } else if (clean.startsWith('Ne yenir') || clean.startsWith('What to eat')) {
          section = 'FOOD';
        } else {
          section = '';
        }
        result.add(_GuideLine(clean, isHeader: true));
        continue;
      }
      final body = line.replaceAll(RegExp(r'^([-•*]|\d+[.)])\s*'), '').replaceAll('**', '');
      if (section == 'PLACE' || section == 'FOOD') {
        var name = body.split(RegExp(r'\s[-–—:]\s|:\s|\s[-–—]\s')).first.trim();
        if (name.length > 80) name = name.substring(0, 80);
        String? note;
        if (body.length > name.length) {
          var rest = body
              .substring(name.length)
              .replaceFirst(RegExp(r'^\s*[-–—:]\s*'), '')
              .trim();
          if (rest.length > 500) rest = rest.substring(0, 500);
          if (rest.isNotEmpty) note = rest;
        }
        result.add(_GuideLine(body, favType: section, favName: name, note: note));
      } else {
        result.add(_GuideLine(body));
      }
    }
    return result;
  }

  Future<void> _generate() async {
    final city = _city.text.trim();
    final country = _country.text.trim();
    if (city.isEmpty || country.isEmpty) {
      setState(() => _error = t('Şehir ve ülke yaz.', 'Enter a city and a country.'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _lines = null;
      _favIds.clear();
    });
    final prompt = appLang.value == 'en'
        ? 'Write a short travel guide for $city, $country. '
            'Write in English. Do not use markdown symbols (#, *, **), plain text only. '
            'Use these headings, each on its own line: '
            'Overview, Must-see (4-5 places, each on its own line, as "Place name - one sentence"), '
            'What to eat (3-4 dishes, each on its own line, as "Dish name - one sentence"), '
            'Tips (2-3 practical tips).'
        : '$city, $country için kısa bir gezi rehberi hazırla. '
            'Türkçe yaz. Markdown işaretleri (#, *, **) kullanma, düz metin yaz. '
            'Şu başlıkları kullan, her başlık kendi satırında olsun: '
            'Kısaca, Mutlaka gör (4-5 yer, her biri ayrı satırda, "Yer adı - tek cümle" biçiminde), '
            'Ne yenir (3-4 yemek, her biri ayrı satırda, "Yemek adı - tek cümle" biçiminde), '
            'İpucu (2-3 pratik öneri).';
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/ai'),
            headers: authHeaders(),
            body: jsonEncode({'prompt': prompt}),
          )
          .timeout(const Duration(seconds: 90));
      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        if (!mounted) return;
        setState(() {
          _genCity = city;
          _genCountry = country;
          _lines = _parse(_extractText(body));
        });
      } else {
        setState(() => _error = t('Rehber alınamadı (${res.statusCode})', 'Could not get the guide (${res.statusCode})'));
      }
    } catch (e) {
      setState(() => _error = t('Rehber alınamadı. Backend açık mı? ($e)', 'Could not get the guide. Is the backend running? ($e)'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggleFav(String type, String name) async {
    final key = '$type|$name';
    try {
      if (_favIds.containsKey(key)) {
        final res = await http.delete(
          Uri.parse('$baseUrl/api/favorites/${_favIds[key]}'),
          headers: authHeaders(),
        );
        if (res.statusCode == 200 || res.statusCode == 204) {
          setState(() => _favIds.remove(key));
        } else {
          _msg(t('Kaldırılamadı (${res.statusCode})', 'Could not remove (${res.statusCode})'));
        }
      } else {
        final res = await http.post(
          Uri.parse('$baseUrl/api/favorites'),
          headers: authHeaders(),
          body: jsonEncode({
            'type': type,
            'name': name,
            'city': _genCity,
            'country': _genCountry,
          }),
        );
        if (res.statusCode == 200 || res.statusCode == 201) {
          final body = jsonDecode(utf8.decode(res.bodyBytes));
          setState(() => _favIds[key] = body['id']);
        } else {
          _msg(t('Favoriye eklenemedi (${res.statusCode})', 'Could not add to favorites (${res.statusCode})'));
        }
      }
    } catch (e) {
      _msg(t('Sunucuya ulaşılamadı', 'Could not reach the server'));
    }
  }

  Future<void> _addToTrip(String name, String? note) async {
    List<dynamic> trips;
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/trips?_=${DateTime.now().millisecondsSinceEpoch}'),
        headers: authHeaders(),
      );
      if (res.statusCode != 200) {
        _msg(t('Geziler alınamadı (${res.statusCode})', 'Could not load trips (${res.statusCode})'));
        return;
      }
      trips = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    } catch (e) {
      _msg(t('Sunucuya ulaşılamadı', 'Could not reach the server'));
      return;
    }
    if (trips.isEmpty) {
      _msg(t('Önce Seyahatlerim ekranından bir gezi oluştur.', 'First create a trip from the My trips screen.'));
      return;
    }
    if (!mounted) return;
    final trip = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(t('Hangi geziye eklensin?', 'Add to which trip?')),
        children: [
          for (final t in trips)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text('${t['title']} (${t['city']})'),
            ),
        ],
      ),
    );
    if (trip == null || !mounted) return;
    final dayCount = (trip['dayCount'] as num?)?.toInt() ?? 1;
    final day = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(t('Hangi güne?', 'Which day?')),
        children: [
          for (var d = 1; d <= dayCount; d++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, d),
              child: Text(t('$d. gün', 'Day $d')),
            ),
        ],
      ),
    );
    if (day == null) return;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/trips/${trip['id']}/stops'),
        headers: authHeaders(),
        body: jsonEncode({
          'dayNumber': day,
          'name': name,
          'latitude': null,
          'longitude': null,
          'note': note,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _msg(t('"$name" ${trip['title']} gezisinin $day. gününe eklendi.', '"$name" added to day $day of ${trip['title']}.'));
      } else {
        _msg(t('Eklenemedi (${res.statusCode})', 'Could not add (${res.statusCode})'));
      }
    } catch (e) {
      _msg(t('Sunucuya ulaşılamadı', 'Could not reach the server'));
    }
  }

  Widget _favButton(String type, String name) {
    final isFav = _favIds.containsKey('$type|$name');
    return IconButton(
      tooltip: isFav ? t('Favoriden çıkar', 'Remove from favorites') : t('Favorilere ekle', 'Add to favorites'),
      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? Colors.red : null),
      onPressed: () => _toggleFav(type, name),
    );
  }

  Widget _form() {
    return Column(
      children: [
        TextField(
          controller: _city,
          decoration: InputDecoration(
              labelText: t('Şehir', 'City'), prefixIcon: Icon(Icons.location_city)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _country,
          decoration: InputDecoration(
              labelText: t('Ülke', 'Country'), prefixIcon: Icon(Icons.flag_outlined)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _loading ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_loading ? t('Rehber hazırlanıyor...', 'Preparing guide...') : t('Rehber oluştur', 'Create guide')),
          ),
        ),
      ],
    );
  }

  IconData _sectionIcon(String header) {
    if (header.startsWith('Mutlaka') || header.startsWith('Must')) return Icons.place_outlined;
    if (header.startsWith('Ne yenir') || header.startsWith('What to eat')) {
      return Icons.restaurant_outlined;
    }
    if (header.startsWith('İpucu') || header.startsWith('Ipucu') || header.startsWith('Tips')) {
      return Icons.lightbulb_outline;
    }
    return Icons.info_outline;
  }

  Widget _lineRow(_GuideLine l, ColorScheme cs) {
    if (l.favType == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SelectableText(l.text, style: const TextStyle(fontSize: 15, height: 1.45)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SelectableText.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 15, height: 1.45),
                  children: [
                    TextSpan(
                      text: l.favName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (l.note != null) TextSpan(text: ' — ${l.note}'),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: t('Gezime ekle', 'Add to my trip'),
                icon: const Icon(Icons.add_location_alt_outlined),
                onPressed: () => _addToTrip(l.favName!, l.note),
              ),
              _favButton(l.favType!, l.favName!),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _sections(List<_GuideLine> lines, ColorScheme cs) {
    final cards = <Widget>[];
    String? header;
    var items = <_GuideLine>[];

    void flush() {
      if (header == null && items.isEmpty) return;
      cards.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (header != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, right: 8),
                    child: Row(
                      children: [
                        Icon(_sectionIcon(header!), color: cs.primary),
                        const SizedBox(width: 8),
                        Text(header!,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: cs.primary)),
                      ],
                    ),
                  ),
                for (final l in items) _lineRow(l, cs),
              ],
            ),
          ),
        ),
      );
      header = null;
      items = <_GuideLine>[];
    }

    for (final l in lines) {
      if (l.isHeader) {
        flush();
        header = l.text;
      } else {
        items.add(l);
      }
    }
    flush();
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(t('Yapay zekâ rehberi', 'AI guide'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (lines != null) ...[
            CityPhotos(
              key: ValueKey('$_genCity|$_genCountry'),
              city: _genCity,
              country: _genCountry,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_genCity,
                          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(_genCountry,
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _toggleFav('CITY', _genCity),
                  icon: Icon(
                    _favIds.containsKey('CITY|$_genCity')
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _favIds.containsKey('CITY|$_genCity') ? Colors.red : null,
                  ),
                  label: Text(_favIds.containsKey('CITY|$_genCity')
                      ? t('Favoride', 'In favorites')
                      : t('Şehri favorile', 'Favorite this city')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            WeatherCard(
              key: ValueKey('w$_genCity|$_genCountry'),
              city: _genCity,
              country: _genCountry,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => planTripWithAi(context, _genCity, _genCountry),
                icon: const Icon(Icons.auto_awesome_motion),
                label: Text(t('Bu şehir için gezi planı oluştur',
                    'Create a trip plan for this city')),
              ),
            ),
            const SizedBox(height: 12),
            ..._sections(lines, cs),
            Card(
              margin: EdgeInsets.zero,
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: const Icon(Icons.travel_explore),
                title: Text(t('Başka şehir ara', 'Search another city')),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [_form()],
              ),
            ),
          ] else ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _form(),
              ),
            ),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
        ],
      ),
    );
  }
}

// ---------------- FAVORİLER ----------------
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'ALL';

  Map<String, String> get _labels => {
        'PLACE': t('Yer', 'Place'),
        'FOOD': t('Yemek', 'Food'),
        'RESTAURANT': t('Restoran', 'Restaurant'),
        'CITY': t('Şehir', 'City'),
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/favorites?_=${DateTime.now().millisecondsSinceEpoch}'),
        headers: authHeaders(),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _items = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
          _loading = false;
          _error = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = t('Liste alınamadı (${res.statusCode})', 'Could not load the list (${res.statusCode})');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t('Sunucuya ulaşılamadı', 'Could not reach the server');
      });
    }
  }

  Future<void> _delete(dynamic id) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/favorites/$id'),
        headers: authHeaders(),
      );
    } catch (_) {}
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filter == 'ALL'
        ? _items
        : _items.where((f) => f['type'] == _filter).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Favorilerim', 'My favorites')),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          for (final e in {
                            'ALL': t('Tümü', 'All'),
                            'PLACE': t('Yerler', 'Places'),
                            'FOOD': t('Yemekler', 'Foods'),
                            'RESTAURANT': t('Restoranlar', 'Restaurants'),
                            'CITY': t('Şehirler', 'Cities'),
                          }.entries)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(e.value),
                                selected: _filter == e.key,
                                onSelected: (_) => setState(() => _filter = e.key),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: shown.isEmpty
                          ? Center(child: Text(t('Henüz favori yok.', 'No favorites yet.')))
                          : ListView.builder(
                              itemCount: shown.length,
                              itemBuilder: (context, i) {
                                final f = shown[i];
                                final label = _labels[f['type']] ?? '${f['type']}';
                                return ListTile(
                                  leading: const Icon(Icons.favorite, color: Colors.red),
                                  title: Text('${f['name']}'),
                                  subtitle: Text('$label · ${f['city']}, ${f['country']}'),
                                  trailing: IconButton(
                                    tooltip: t('Kaldır', 'Remove'),
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _delete(f['id']),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
