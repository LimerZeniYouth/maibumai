enum StatsFilter {
  today,
  week,
  month,
  year,
  all,
}

extension StatsFilterX on StatsFilter {
  String get label => switch (this) {
        StatsFilter.today => '今日',
        StatsFilter.week => '本周',
        StatsFilter.month => '本月',
        StatsFilter.year => '本年',
        StatsFilter.all => '全部',
      };
}
