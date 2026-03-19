import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:maibumai/models/app_stats.dart';
import 'package:maibumai/widgets/glass_card.dart';

class SavingsLineChart extends StatelessWidget {
  const SavingsLineChart({
    super.key,
    required this.points,
    required this.maxY,
  });

  final List<TrendPoint> points;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('节省金额趋势', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 208,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(handleBuiltInTouches: true),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            points[index].label,
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 4,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 3.6,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.20),
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].amount),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.points,
    required this.maxY,
  });

  final List<TrendPoint> points;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('每月节省金额', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 208,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                alignment: BarChartAlignment.spaceBetween,
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= points.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            points[index].label,
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].amount,
                          borderRadius: BorderRadius.circular(12),
                          width: 16,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              const Color(0xFF8BD9FF),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.data,
  });

  final List<CategoryBreakdown> data;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, item) => sum + item.amount);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('类别节省占比', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final chart = SizedBox(
                height: 210,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 42,
                    sectionsSpace: 2,
                    sections: [
                      for (final item in data)
                        PieChartSectionData(
                          value: item.amount,
                          radius: 56,
                          color: Color(item.colorValue),
                          title: total == 0
                              ? '0%'
                              : '${(item.amount / total * 100).toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              );

              final legend = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in data.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Color(item.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('¥${item.amount.toStringAsFixed(0)}'),
                        ],
                      ),
                    ),
                ],
              );

              if (compact) {
                return Column(
                  children: [
                    chart,
                    const SizedBox(height: 12),
                    legend,
                  ],
                );
              }

              return SizedBox(
                height: 220,
                child: Row(
                  children: [
                    Expanded(child: chart),
                    const SizedBox(width: 14),
                    Expanded(child: legend),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
