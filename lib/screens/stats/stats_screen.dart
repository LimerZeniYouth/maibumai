import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maibumai/data/item_repository.dart';
import 'package:maibumai/models/stats_filter.dart';
import 'package:maibumai/providers/app_provider.dart';
import 'package:maibumai/utils/formatters.dart';
import 'package:maibumai/widgets/empty_state.dart';
import 'package:maibumai/widgets/glass_card.dart';
import 'package:maibumai/widgets/stats_charts.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final stats = provider.stats;
    final repository = context.read<ItemRepository>();

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text('数据统计', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '把每一次克制，变成看得见的趋势。',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 18),
          _StatsHero(
            periodLabel: provider.statsFilter.label,
            periodSaved: stats.periodSaved,
            totalSaved: stats.totalSaved,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in StatsFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: provider.statsFilter == filter,
                      onSelected: (_) => context.read<AppProvider>().updateStatsFilter(filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard(
                title: '本周期节省',
                value: formatCurrency(stats.periodSaved),
                icon: Icons.savings_rounded,
                accent: const Color(0xFF5CC97B),
              ),
              _MetricCard(
                title: '累计节省',
                value: formatCurrency(stats.totalSaved),
                icon: Icons.auto_graph_rounded,
                accent: const Color(0xFF6C8EFF),
              ),
              _MetricCard(
                title: '放弃次数',
                value: '${stats.skippedCount}',
                icon: Icons.close_rounded,
                accent: const Color(0xFF58C27D),
              ),
              _MetricCard(
                title: '当前想买',
                value: '${stats.activeWishes}',
                icon: Icons.timelapse_rounded,
                accent: const Color(0xFFFFB547),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (stats.categoryBreakdown.isEmpty)
            const EmptyState(
              title: '还没有节省数据',
              subtitle: '把某件商品右滑标记为“不买了”，这里就会开始有图表。',
              icon: Icons.auto_graph_rounded,
            )
          else ...[
            _ChartSection(
              title: '节省趋势',
              subtitle: '看你在这个周期里，克制是怎么累积出来的。',
              child: SavingsLineChart(
                points: stats.trend,
                maxY: repository.niceMax(stats.trend.map((item) => item.amount)),
              ),
            ),
            const SizedBox(height: 16),
            _ChartSection(
              title: '近 6 个月',
              subtitle: '把波动拉长看，更能看到消费习惯变化。',
              child: MonthlyBarChart(
                points: stats.monthlySavings,
                maxY: repository.niceMax(stats.monthlySavings.map((item) => item.amount)),
              ),
            ),
            const SizedBox(height: 16),
            _ChartSection(
              title: '分类占比',
              subtitle: '哪些品类最容易冲动，哪些最容易冷静下来。',
              child: CategoryPieChart(data: stats.categoryBreakdown),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsHero extends StatelessWidget {
  const _StatsHero({
    required this.periodLabel,
    required this.periodSaved,
    required this.totalSaved,
  });

  final String periodLabel;
  final double periodSaved;
  final double totalSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF101A33), Color(0xFF223767)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF223767).withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$periodLabel表现',
            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            formatCurrency(periodSaved),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '累计已经省下 ${formatCurrency(totalSaved)}',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Column(
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
          ),
        ),
        child,
      ],
    );
  }
}
