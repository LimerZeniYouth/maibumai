class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.amount,
  });

  final String label;
  final double amount;
}

class CategoryBreakdown {
  const CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.colorValue,
  });

  final String category;
  final double amount;
  final int colorValue;
}

class AppStats {
  const AppStats({
    required this.totalSaved,
    required this.periodSaved,
    required this.skippedCount,
    required this.boughtCount,
    required this.activeWishes,
    required this.trend,
    required this.monthlySavings,
    required this.categoryBreakdown,
  });

  final double totalSaved;
  final double periodSaved;
  final int skippedCount;
  final int boughtCount;
  final int activeWishes;
  final List<TrendPoint> trend;
  final List<TrendPoint> monthlySavings;
  final List<CategoryBreakdown> categoryBreakdown;
}
