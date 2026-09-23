import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'theme/app_theme.dart';
import 'state/providers.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/library_screen.dart';
import 'ui/screens/playlists_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/player_screen.dart';
import 'ui/widgets/mini_player.dart';

class NovaPlayApp extends ConsumerWidget {
  const NovaPlayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Nova Play',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode == 'light'
          ? ThemeMode.light
          : themeMode == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system,
      home: const Shell(),
      routes: {
        '/settings': (_) => const SettingsScreen(),
        '/player': (_) => const PlayerScreen(),
      },
    );
  }
}

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});
  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeScreen(),
      LibraryScreen(),
      PlaylistsScreen(),
      SearchScreen(),
    ];
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: IndexedStack(index: index, children: pages)),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedHome01),
            selectedIcon: HugeIcon(icon: HugeIcons.strokeRoundedHome01),
            label: 'Home',
          ),
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedVideo01),
            label: 'Library',
          ),
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedPlaylist01),
            label: 'Playlists',
          ),
          NavigationDestination(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedSearch01),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}
