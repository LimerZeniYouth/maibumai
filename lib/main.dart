import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maibumai/data/app_database.dart';
import 'package:maibumai/data/item_repository.dart';
import 'package:maibumai/providers/app_provider.dart';
import 'package:maibumai/providers/theme_provider.dart';
import 'package:maibumai/screens/add/add_item_sheet.dart';
import 'package:maibumai/screens/history/history_screen.dart';
import 'package:maibumai/screens/home/home_screen.dart';
import 'package:maibumai/screens/settings/settings_screen.dart';
import 'package:maibumai/screens/stats/stats_screen.dart';
import 'package:maibumai/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase.instance;
  final repository = ItemRepository(database);
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  final appProvider = AppProvider(repository);
  await appProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: repository),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: appProvider),
      ],
      child: const MaiBuMaiApp(),
    ),
  );
}

class MaiBuMaiApp extends StatelessWidget {
  const MaiBuMaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '买不买',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onAddPressed: _openAddSheet),
      const HistoryScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        onChanged: (value) => setState(() => _index = value),
        onAddTap: _openAddSheet,
      ),
    );
  }

  Future<void> _openAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => const AddItemSheet(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.currentIndex,
    required this.onChanged,
    required this.onAddTap,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.22 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: '心愿单',
                selected: currentIndex == 0,
                onTap: () => onChanged(0),
              ),
              _BottomNavItem(
                icon: Icons.history_rounded,
                label: '历史',
                selected: currentIndex == 1,
                onTap: () => onChanged(1),
              ),
              _BottomNavItem(
                icon: Icons.add_rounded,
                label: '添加',
                highlighted: true,
                onTap: onAddTap,
              ),
              _BottomNavItem(
                icon: Icons.insert_chart_rounded,
                label: '统计',
                selected: currentIndex == 2,
                onTap: () => onChanged(2),
              ),
              _BottomNavItem(
                icon: Icons.settings_rounded,
                label: '设置',
                selected: currentIndex == 3,
                onTap: () => onChanged(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlighted
        ? theme.colorScheme.primary
        : selected
            ? theme.colorScheme.primary
            : theme.hintColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: highlighted ? 44 : 38,
                height: highlighted ? 44 : 38,
                decoration: highlighted
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, const Color(0xFF8A7BFF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.26),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      )
                    : BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                child: Icon(
                  icon,
                  color: highlighted ? Colors.white : color,
                  size: highlighted ? 24 : 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: selected || highlighted ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
