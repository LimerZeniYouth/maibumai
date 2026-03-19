import 'package:flutter/material.dart';
import 'package:maibumai/data/app_database.dart';
import 'package:maibumai/data/item_repository.dart';
import 'package:maibumai/providers/app_provider.dart';
import 'package:maibumai/providers/theme_provider.dart';
import 'package:maibumai/screens/add/add_item_sheet.dart';
import 'package:maibumai/screens/history/history_screen.dart';
import 'package:maibumai/screens/home/home_screen.dart';
import 'package:maibumai/screens/settings/settings_screen.dart';
import 'package:maibumai/screens/stats/stats_screen.dart';
import 'package:maibumai/services/notification_service.dart';
import 'package:maibumai/theme/app_theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.initialize();

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
    const pages = [
      HomeScreen(),
      HistoryScreen(),
      StatsScreen(),
      SettingsScreen(),
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

  static const _pageSlots = [0, 1, 3, 4];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 88,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.24 : 0.08,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const indicatorWidth = 42.0;
              final slot = _pageSlots[currentIndex];
              final itemWidth = constraints.maxWidth / 5;
              final left = slot * itemWidth + (itemWidth - indicatorWidth) / 2;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    left: left,
                    child: Container(
                      width: indicatorWidth,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _BottomNavItem(
                        icon: Icons.favorite_border_rounded,
                        label: '心愿单',
                        selected: currentIndex == 0,
                        onTap: () => onChanged(0),
                      ),
                      _BottomNavItem(
                        icon: Icons.history_rounded,
                        label: '记录',
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
                        icon: Icons.insert_chart_outlined,
                        label: '统计',
                        selected: currentIndex == 2,
                        onTap: () => onChanged(2),
                      ),
                      _BottomNavItem(
                        icon: Icons.settings_outlined,
                        label: '设置',
                        selected: currentIndex == 3,
                        onTap: () => onChanged(3),
                      ),
                    ],
                  ),
                ],
              );
            },
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
    final color = selected ? theme.colorScheme.primary : theme.hintColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.only(top: highlighted ? 0 : 10, bottom: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (highlighted)
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF19C2FF), Color(0xFF3478FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E93FF)
                                  .withValues(alpha: 0.32),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 7,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
              if (!highlighted) ...[
                const SizedBox(height: 6),
                SizedBox(
                  height: 16,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
