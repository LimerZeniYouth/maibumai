import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:maibumai/providers/app_provider.dart';
import 'package:maibumai/providers/theme_provider.dart';
import 'package:maibumai/utils/formatters.dart';
import 'package:maibumai/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final provider = context.watch<AppProvider>();

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text('设置', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '管理外观、分类和你的理性消费数据。',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 18),
          _SettingsHero(
            totalSaved: provider.stats.totalSaved,
            activeWishes: provider.stats.activeWishes,
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('冷静期提醒', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  provider.dueWishItems.isEmpty
                      ? '开启系统通知后，新的冷静期到点会直接提醒你回来二次确认。'
                      : '当前有 ${provider.dueWishItems.length} 项已经到复看期，通知会继续覆盖之后的新提醒。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    if (compact) {
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _requestNotificationPermission(context),
                              icon: const Icon(Icons.notifications_active_rounded),
                              label: const Text('开启通知权限'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () => _resyncNotifications(context),
                              icon: const Icon(Icons.sync_rounded),
                              label: const Text('重新同步提醒'),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _requestNotificationPermission(context),
                            icon: const Icon(Icons.notifications_active_rounded),
                            label: const Text('开启通知权限'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _resyncNotifications(context),
                            icon: const Icon(Icons.sync_rounded),
                            label: const Text('重新同步提醒'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('外观模式', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '主题切换保持固定尺寸，避免切换时按钮抖动。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                const SizedBox(height: 14),
                _ThemeModeSelector(currentMode: themeProvider.themeMode),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('分类颜色', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '保持颜色稳定，一眼就知道是什么类型的消费。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in provider.categories)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('数据备份', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '导出一份 JSON 备份，或导入之前的备份文件恢复数据。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 360;
                    if (compact) {
                      return Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _exportData(context),
                              icon: const Icon(Icons.upload_file_rounded),
                              label: const Text('导出数据'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () => _importData(context),
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('导入数据'),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _exportData(context),
                            icon: const Icon(Icons.upload_file_rounded),
                            label: const Text('导出数据'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _importData(context),
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('导入数据'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('数据维护', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '如果你只是想回到演示状态，可以一键恢复示例数据。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () async {
                      await context.read<AppProvider>().resetAllData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已重置为示例数据')),
                        );
                      }
                    },
                    child: const Text('重置示例数据'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final json = await provider.exportBackupJson();
    final bytes = Uint8List.fromList(utf8.encode(json));

    final path = await FilePicker.platform.saveFile(
      dialogTitle: '导出备份文件',
      fileName: 'maibumai-backup.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path == null ? '已导出备份文件' : '备份已导出到 $path',
        ),
      ),
    );
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final provider = context.read<AppProvider>();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw const FormatException('无法读取备份文件内容。');
      }

      await provider.importBackupJson(utf8.decode(bytes));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入 ${file.name}')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$error')),
        );
      }
    }
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    final granted =
        await context.read<AppProvider>().requestNotificationPermissions();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(granted ? '通知权限已开启' : '未获得通知权限，可稍后在系统设置中开启'),
      ),
    );
  }

  Future<void> _resyncNotifications(BuildContext context) async {
    await context.read<AppProvider>().refresh();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已重新同步冷静期提醒')),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.totalSaved,
    required this.activeWishes,
  });

  final double totalSaved;
  final int activeWishes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141C36), Color(0xFF24345F)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF24345F).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '你的消费节奏',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            formatCurrency(totalSaved),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前还有 $activeWishes 件在等待你决定。',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.currentMode});

  final ThemeMode currentMode;

  @override
  Widget build(BuildContext context) {
    const options = [
      (ThemeMode.system, Icons.phone_iphone_rounded, '跟随系统'),
      (ThemeMode.light, Icons.light_mode_rounded, '浅色'),
      (ThemeMode.dark, Icons.dark_mode_rounded, '深色'),
    ];

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            Expanded(
              child: _ThemeModeButton(
                mode: options[i].$1,
                icon: options[i].$2,
                label: options[i].$3,
                selected: currentMode == options[i].$1,
              ),
            ),
            if (i != options.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.mode,
    required this.icon,
    required this.label,
    required this.selected,
  });

  final ThemeMode mode;
  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        selected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color;

    return InkWell(
      onTap: () => context.read<ThemeProvider>().updateThemeMode(mode),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.24)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
