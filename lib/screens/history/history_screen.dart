import 'package:flutter/material.dart';
import 'package:maibumai/models/category_tag.dart';
import 'package:maibumai/models/item_status.dart';
import 'package:maibumai/models/wish_item.dart';
import 'package:maibumai/providers/app_provider.dart';
import 'package:maibumai/utils/formatters.dart';
import 'package:maibumai/widgets/category_chip.dart';
import 'package:maibumai/widgets/empty_state.dart';
import 'package:maibumai/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ItemStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filteredItems = provider.items
        .where((item) => item.status != ItemStatus.wish)
        .where((item) => _filter == null || item.status == _filter)
        .toList()
      ..sort((a, b) => _actionTimeOf(b).compareTo(_actionTimeOf(a)));

    final recentItems = filteredItems.where((item) {
      final diff = DateTime.now().difference(_actionTimeOf(item));
      return diff.inDays < 7;
    }).toList();
    final olderItems = filteredItems.where((item) {
      final diff = DateTime.now().difference(_actionTimeOf(item));
      return diff.inDays >= 7;
    }).toList();

    final boughtCount =
        provider.items.where((item) => item.status == ItemStatus.bought).length;
    final skippedCount =
        provider.items.where((item) => item.status == ItemStatus.skipped).length;
    final totalSpent = provider.items
        .where((item) => item.status == ItemStatus.bought)
        .fold<double>(0, (sum, item) => sum + item.price);

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
        children: [
          Text('历史记录', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '回看每一次买下或放弃，也保留误操作后的回退机会。',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 18),
          _HistoryHero(
            boughtCount: boughtCount,
            skippedCount: skippedCount,
            totalSpent: totalSpent,
            totalSaved: provider.stats.totalSaved,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _HistoryFilterChip(
                  label: '全部',
                  icon: Icons.apps_rounded,
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 10),
                _HistoryFilterChip(
                  label: '已购买',
                  icon: Icons.check_circle_outline_rounded,
                  selected: _filter == ItemStatus.bought,
                  onTap: () => setState(() => _filter = ItemStatus.bought),
                ),
                const SizedBox(width: 10),
                _HistoryFilterChip(
                  label: '未购买',
                  icon: Icons.close_rounded,
                  selected: _filter == ItemStatus.skipped,
                  onTap: () => setState(() => _filter = ItemStatus.skipped),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (filteredItems.isEmpty)
            const EmptyState(
              title: '还没有历史记录',
              subtitle: '把心愿单里的物品标记为“已购买”或“未购买”，这里就会出现。',
              icon: Icons.history_rounded,
            )
          else ...[
            if (recentItems.isNotEmpty) ...[
              const _HistorySectionHeader(
                title: '最近 7 天',
                subtitle: '刚做完的决定，最值得回看。',
              ),
              const SizedBox(height: 12),
              ...recentItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(
                    item: item,
                    categories: provider.categories,
                    onRestore: () => _restoreItem(context, item),
                  ),
                ),
              ),
            ],
            if (olderItems.isNotEmpty) ...[
              if (recentItems.isNotEmpty) const SizedBox(height: 4),
              const _HistorySectionHeader(
                title: '更早之前',
                subtitle: '这些决定已经沉淀下来了。',
              ),
              const SizedBox(height: 12),
              ...olderItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HistoryCard(
                    item: item,
                    categories: provider.categories,
                    onRestore: () => _restoreItem(context, item),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _restoreItem(BuildContext context, WishItem item) async {
    await context.read<AppProvider>().restoreItem(item.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已将 ${item.name} 恢复到心愿单')),
      );
    }
  }

  DateTime _actionTimeOf(WishItem item) =>
      item.boughtAt ?? item.skippedAt ?? item.createdAt;
}

class _HistoryHero extends StatelessWidget {
  const _HistoryHero({
    required this.boughtCount,
    required this.skippedCount,
    required this.totalSpent,
    required this.totalSaved,
  });

  final int boughtCount;
  final int skippedCount;
  final double totalSpent;
  final double totalSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF141C36), Color(0xFF24345F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF24345F).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '决策复盘',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${boughtCount + skippedCount} 次',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '买下来的，说明真的需要；没买的，说明冲动已经过去了。',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 340;
              if (compact) {
                return Column(
                  children: [
                    _HeroMetric(
                      label: '已购买',
                      value: '$boughtCount',
                      subtitle: '支出 ${formatCurrency(totalSpent)}',
                      accent: const Color(0xFF83A4FF),
                    ),
                    const SizedBox(height: 10),
                    _HeroMetric(
                      label: '未购买',
                      value: '$skippedCount',
                      subtitle: '省下 ${formatCurrency(totalSaved)}',
                      accent: const Color(0xFF76E0A0),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      label: '已购买',
                      value: '$boughtCount',
                      subtitle: '支出 ${formatCurrency(totalSpent)}',
                      accent: const Color(0xFF83A4FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroMetric(
                      label: '未购买',
                      value: '$skippedCount',
                      subtitle: '省下 ${formatCurrency(totalSaved)}',
                      accent: const Color(0xFF76E0A0),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HistorySectionHeader extends StatelessWidget {
  const _HistorySectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      ],
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected ? theme.colorScheme.primary : theme.hintColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minWidth: 94, minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.80),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.categories,
    required this.onRestore,
  });

  final WishItem item;
  final List<CategoryTag> categories;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    final category =
        categories.where((tag) => tag.name == item.category).firstOrNull;
    final categoryColor = category?.color ?? const Color(0xFF8F96A3);
    final accentColor = item.status == ItemStatus.bought
        ? const Color(0xFF4B7BFF)
        : const Color(0xFF5CC97B);
    final actionTime = item.boughtAt ?? item.skippedAt ?? item.createdAt;
    final actionLabel = item.status == ItemStatus.bought ? '买下来了' : '最后没买';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: item.note.isEmpty ? 92 : 114,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      label: item.status == ItemStatus.bought ? '已购买' : '未购买',
                      color: accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CategoryChip(label: item.category, color: categoryColor),
                    Text(
                      formatCurrency(item.price),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      '$actionLabel · ${formatRelativeDecision(actionTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ],
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: TextButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('恢复到心愿单'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
