import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maibumai/models/item_status.dart';
import 'package:maibumai/models/wish_item.dart';
import 'package:maibumai/providers/app_provider.dart';
import 'package:maibumai/utils/formatters.dart';
import 'package:maibumai/widgets/empty_state.dart';
import 'package:maibumai/widgets/glass_card.dart';
import 'package:maibumai/widgets/hero_stat_card.dart';
import 'package:maibumai/widgets/wish_item_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onAddPressed,
  });

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final wishItems = provider.items.where((item) => item.status == ItemStatus.wish).toList();
    final skippedItems = provider.items.where((item) => item.status == ItemStatus.skipped).toList();
    final boughtItems = provider.items.where((item) => item.status == ItemStatus.bought).toList();
    final latestResolved = provider.items.where((item) => item.status != ItemStatus.wish).toList()
      ..sort((a, b) => _resolvedAtOf(b).compareTo(_resolvedAtOf(a)));

    final activeTotal = wishItems.fold<double>(0, (sum, item) => sum + item.price);
    final averageWishPrice = wishItems.isEmpty ? 0.0 : activeTotal / wishItems.length;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 380;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6C8EFF), Color(0xFF8A7BFF)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8A7BFF).withValues(alpha: 0.22),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.hourglass_bottom_rounded, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '买不买',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '把冲动先放进清单，等情绪过去再决定。',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).hintColor,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: compact ? double.infinity : null,
                            child: FilledButton.tonalIcon(
                              onPressed: onAddPressed,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('记一下'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  HeroStatCard(
                    title: '已经省下',
                    value: formatCurrency(provider.stats.totalSaved),
                    subtitle: skippedItems.isEmpty
                        ? '先把想买的东西记下来，过几天再看。'
                        : '你已经放弃 ${skippedItems.length} 次冲动购买。',
                    gradient: const [Color(0xFF6C8EFF), Color(0xFF8A7BFF)],
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stack = constraints.maxWidth < 360;
                      final first = _InsightCard(
                        icon: Icons.timelapse_rounded,
                        title: '待决定',
                        value: '${wishItems.length}',
                        subtitle: wishItems.isEmpty ? '清单是空的' : '总额 ${formatCurrency(activeTotal)}',
                        accent: const Color(0xFF6C8EFF),
                      );
                      final second = _InsightCard(
                        icon: Icons.query_stats_rounded,
                        title: '平均客单',
                        value: wishItems.isEmpty ? '—' : formatCurrency(averageWishPrice),
                        subtitle: boughtItems.isEmpty ? '先积累更多决策' : '已买 ${boughtItems.length} 件',
                        accent: const Color(0xFF5CC97B),
                      );

                      if (stack) {
                        return Column(
                          children: [
                            first,
                            const SizedBox(height: 12),
                            second,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: first),
                          const SizedBox(width: 12),
                          Expanded(child: second),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('正在犹豫', style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        '${wishItems.length} 件',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).hintColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '左滑买了，右滑放弃，让清单持续流动起来。真正重要的东西会留下。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (wishItems.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: '还没有想买的东西',
                subtitle: '点底部中间的 +，把心动但还在犹豫的物品记下来。',
                icon: Icons.shopping_bag_outlined,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverList.separated(
                itemBuilder: (context, index) {
                  final item = wishItems[index];
                  return Dismissible(
                    key: ValueKey(item.id),
                    background: const _SwipeAction(
                      alignment: Alignment.centerLeft,
                      color: Color(0xFF5CC97B),
                      icon: Icons.close_rounded,
                      label: '不买了',
                    ),
                    secondaryBackground: const _SwipeAction(
                      alignment: Alignment.centerRight,
                      color: Color(0xFF4B7BFF),
                      icon: Icons.check_rounded,
                      label: '已购买',
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        await context.read<AppProvider>().markItem(item.id, ItemStatus.skipped);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已放弃 ${item.name}，节省 ${formatCurrency(item.price)}')),
                          );
                        }
                      } else {
                        await context.read<AppProvider>().markItem(item.id, ItemStatus.bought);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已标记 ${item.name} 为已购买')),
                          );
                        }
                      }
                      return true;
                    },
                    child: WishItemCard(item: item, categories: provider.categories),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemCount: wishItems.length,
              ),
            ),
          if (latestResolved.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                child: _RecentResolutionCard(items: latestResolved.take(3).toList()),
              ),
            ),
        ],
      ),
    );
  }

  DateTime _resolvedAtOf(WishItem item) => item.boughtAt ?? item.skippedAt ?? item.createdAt;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecentResolutionCard extends StatelessWidget {
  const _RecentResolutionCard({required this.items});

  final List<WishItem> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('最近刚决定', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '复盘区',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final item in items) ...[
            _RecentResolutionRow(item: item),
            if (item != items.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _RecentResolutionRow extends StatelessWidget {
  const _RecentResolutionRow({required this.item});

  final WishItem item;

  @override
  Widget build(BuildContext context) {
    final isBought = item.status == ItemStatus.bought;
    final accent = isBought ? const Color(0xFF4B7BFF) : const Color(0xFF5CC97B);
    final verb = isBought ? '买了' : '没买';
    final actionTime = item.boughtAt ?? item.skippedAt ?? item.createdAt;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            isBought ? Icons.check_rounded : Icons.close_rounded,
            color: accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '$verb · ${formatRelativeDecision(actionTime)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ],
          ),
        ),
        Text(
          formatCurrency(item.price),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignment == Alignment.centerRight) ...[
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
            ],
            Icon(icon, color: color),
            if (alignment == Alignment.centerLeft) ...[
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}
