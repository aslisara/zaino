import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'l10n.dart';

/// Geziyi paylaşılabilir düz metne çevirir.
String buildTripText(Map<String, dynamic> trip) {
  final b = StringBuffer();
  final days = (trip['days'] as List?) ?? const [];
  b.writeln('✈️ ${trip['title'] ?? ''}');
  b.writeln('📍 ${trip['city'] ?? ''}, ${trip['country'] ?? ''} · '
      '${t('${days.length} gün', '${days.length} days')}');
  for (final d in days) {
    b.writeln();
    b.writeln('📅 ${t('${d['dayNumber']}. Gün', 'Day ${d['dayNumber']}')}');
    final stops = (d['stops'] as List?) ?? const [];
    if (stops.isEmpty) {
      b.writeln('  –');
    }
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final note = '${s['note'] ?? ''}'.trim();
      b.writeln('  ${i + 1}. ${s['name']}${note.isEmpty ? '' : ' — $note'}');
    }
  }
  b.writeln();
  b.write(t('Explore World ile hazırlandı 🌍', 'Made with Explore World 🌍'));
  return b.toString();
}

Future<void> shareTrip(BuildContext context, Map<String, dynamic> trip) async {
  final text = buildTripText(trip);
  final messenger = ScaffoldMessenger.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 180),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text(t('Metni kopyala', 'Copy text')),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) Navigator.pop(ctx);
              messenger.showSnackBar(SnackBar(content: Text(t('Kopyalandı', 'Copied'))));
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('WhatsApp'),
            onTap: () async {
              Navigator.pop(ctx);
              await launchUrl(
                Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(t('E-posta', 'Email')),
            onTap: () async {
              Navigator.pop(ctx);
              await launchUrl(
                Uri.parse('mailto:?subject=${Uri.encodeComponent('${trip['title'] ?? ''}')}'
                    '&body=${Uri.encodeComponent(text)}'),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
