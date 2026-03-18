enum ItemStatus {
  wish,
  bought,
  skipped,
}

extension ItemStatusX on ItemStatus {
  String get value => switch (this) {
        ItemStatus.wish => 'wish',
        ItemStatus.bought => 'bought',
        ItemStatus.skipped => 'skipped',
      };

  String get label => switch (this) {
        ItemStatus.wish => '想买',
        ItemStatus.bought => '已购买',
        ItemStatus.skipped => '不买了',
      };

  static ItemStatus fromValue(String value) => ItemStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => ItemStatus.wish,
      );
}
