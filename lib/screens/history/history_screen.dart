import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maibumai/models/category_tag.dart';
import 'package:maibumai/models/item_status.dart';
import 'package:maibumai/models/wish_item.dart';
import 'package:maibumai/providers/app_provider.dart';
import 'package:maibumai/utils/formatters.dart';
import 'package:maibumai/widgets/category_chip.dart';
import 'package:maibumai/widgets/empty_state.dart';
import 'package:maibumai/widgets/glass_card.dart';

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

    final boughtCount = provider.items.where((item) => item.status == ItemStatus.bought).length;
    final skippedCount = provider.items.where((item) => item.status == ItemStatus.skipped).length;
    final totalSpent = provider.items
        .where((item) => item.status == ItemStatus.bought)
        .fold<double>(0, (sum, item) => sum + item.price);

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text('历史记录', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '不只是归档，更是回看自己怎么做决定。',
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
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 10),
                _HistoryFilterChip(
                  label: '已购买',
                  selected: _filter == ItemStatus.bought,
                  onTap: () => setState(() => _filter = ItemStatus.bought),
                ),
                const SizedBox(width: 10),
                _HistoryFilterChip(
                  label: '不买了',
                  selected: _filter == ItemStatus.skipped,
                  onTap: () => setState(() => _filter = ItemStatus.skipped),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (filteredItems.isEmpty)
            const EmptyState(
              title: '还没有历史记录',
              subtitle: '把心愿单里的物品标记为“已购买”或“不买了”，这里就会出现。',
              icon: Icons.history_rounded,
            )
          else ...[
            if (recentItems.isNotEmpty) ...[
              _HistorySectionHeader(
                title: '最近 7 天',
                subtitle: '刚刚做完的决定，最值得回看。',
              ),
              const SizedBox(height: 12),
              ...recentItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _HistoryTimelineCard(item: item, categories: provider.categories),
                ),
              ),
            ],
            if (olderItems.isNotEmpty) ...[
              if (recentItems.isNotEmpty) const SizedBox(height: 8),
              _HistorySectionHeader(
                title: '更早之前',
                subtitle: '这些决定已经沉淀下来了。',
              ),
              const SizedBox(height: 12),
              ...olderItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _HistoryTimelineCard(item: item, categories: provider.categories),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  DateTime _actionTimeOf(WishItem item) => item.boughtAt ?? item.skippedAt ?? item.createdAt;
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
            color: const Color(0xFF24345F).withOpacity(0.22),
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
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            '${boughtCount + skippedCount} 次',
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            '买下来的，说明真的需要；没买的，说明冲动过去了。',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 18),
          Row(
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
                  label: '不买了',
                  value: '$skippedCount',
                  subtitle: '省下 ${formatCurrency(totalSaved)}',
                  accent: const Color(0xFF76E0A0),
                ),
              ),
            ],
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: accent, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
        const SizedBox(height: 6),
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _HistoryTimelineCard extends StatelessWidget {
  const _HistoryTimelineCard({
    required this.item,
    required this.categories,
  });

  final WishItem item;
  final List<CategoryTag> categories;

  @override
  Widget build(BuildContext context) {
    final category = categories.where((tag) => tag.name == item.category).firstOrNull;
    final categoryColor = category?.color ?? const Color(0xFF8F96A3);
    final accentColor = item.status == ItemStatus.bought
        ? const Color(0xFF4B7BFF)
        : const Color(0xFF5CC97B);
    final actionTime = item.boughtAt ?? item.skippedAt ?? item.createdAt;
    final actionLabel = item.status == ItemStatus.bought ? '买下来了' : '最后没买';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            Container(
              width: 2,
              height: item.note.isEmpty ? 132 : 156,
              color: accentColor.withOpacity(0.18),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.status.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    CategoryChip(label: item.category, color: categoryColor),
                    const SizedBox(width: 10),
                    Text(
                      formatCurrency(item.price),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '$actionLabel · ${formatRelativeDecision(actionTime)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(item.note, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
