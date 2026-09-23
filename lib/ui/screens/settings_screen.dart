import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(prefsStoreProvider);
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _group('Playback'),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedGauge),
            title: const Text('Default speed'),
            subtitle: Text('${store.defaultSpeed()}×'),
            onTap: () => _speedSheet(context, ref),
          ),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedPlay),
            title: const Text('Resume behavior'),
            subtitle: Text(_resumeLabel(store.resumeBehavior())),
            onTap: () => _resumeSheet(context, ref),
          ),
          SwitchListTile(
            secondary: const HugeIcon(
                icon: HugeIcons.strokeRoundedTouch01),
            title: const Text('Gesture controls'),
            subtitle: const Text('Swipe to seek, sides for volume/brightness'),
            value: store.gesturesEnabled(),
            onChanged: (v) async {
              await store.setGesturesEnabled(v);
              ref.invalidate(historyProvider);
              (context as Element).markNeedsBuild();
            },
          ),
          SwitchListTile(
            secondary: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowUpDown),
            title: const Text('Up next on top'),
            subtitle: const Text(
                'Show the queue above the player instead of below'),
            value: store.upNextOnTop(),
            onChanged: (v) async {
              await store.setUpNextOnTop(v);
              (context as Element).markNeedsBuild();
            },
          ),
          _group('Library'),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh01),
            title: const Text('Rescan library'),
            subtitle: const Text(
                'Also lets you select more videos'),
            onTap: () => ref
                .read(libraryProvider.notifier)
                .refresh(prompt: true),
          ),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedClock01),
            title: const Text('Clear history'),
            subtitle: Text('${history.length} entries'),
            onTap: () async {
              await store.clearHistory();
              ref.invalidate(historyProvider);
            },
          ),
          _group('Appearance'),
          ListTile(
            leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedMoon01),
            title: const Text('Theme'),
            subtitle: Text(ref.watch(themeModeProvider)),
            onTap: () => _themeSheet(context, ref),
          ),
          _group('About'),
          const ListTile(
            leading: HugeIcon(icon: HugeIcons.strokeRoundedInformationCircle),
            title: Text('Nova Play 1.0.0'),
            subtitle: Text(
                'Offline-first local video player. Your videos never leave this device.'),
          ),
        ],
      ),
    );
  }

  Widget _group(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
      );

  String _resumeLabel(String v) => switch (v) {
        'always' => 'Always resume',
        'never' => 'Always restart',
        _ => 'Ask me',
      };

  void _speedSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
              .map((s) => ListTile(
                    title: Text('${s}×'),
                    onTap: () async {
                      await ref
                          .read(prefsStoreProvider)
                          .setDefaultSpeed(s);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _resumeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in [
              ('ask', 'Ask me'),
              ('always', 'Always resume'),
              ('never', 'Always restart')
            ])
              ListTile(
                title: Text(e.$2),
                onTap: () async {
                  await ref
                      .read(prefsStoreProvider)
                      .setResumeBehavior(e.$1);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _themeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in ['system', 'light', 'dark'])
              ListTile(
                title: Text(m[0].toUpperCase() + m.substring(1)),
                trailing:
                    ref.watch(themeModeProvider) == m
                        ? Icon(Icons.check,
                            color: Theme.of(context)
                                .colorScheme
                                .primary)
                        : null,
                onTap: () async {
                  await ref
                      .read(prefsStoreProvider)
                      .setThemeMode(m);
                  ref.read(themeModeProvider.notifier).state = m;
                  if (context.mounted) Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
