import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maibumai/data/app_database.dart';
import 'package:maibumai/models/app_stats.dart';
import 'package:maibumai/models/category_tag.dart';
import 'package:maibumai/models/item_status.dart';
import 'package:maibumai/models/stats_filter.dart';
import 'package:maibumai/models/wish_item.dart';
import 'package:maibumai/utils/default_categories.dart';
import 'package:maibumai/utils/formatters.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class ItemRepository {
  ItemRepository(this._database);

  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  Future<void> seedDefaults() async {
    final db = await _database.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'),
        ) ??
        0;

    if (count == 0) {
      final batch = db.batch();
      for (final category in defaultCategories) {
        batch.insert('categories', category.toMap());
      }
      await batch.commit(noResult: true);
    }

    final itemCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM items'),
        ) ??
        0;
    if (itemCount == 0) {
      final now = DateTime.now();
      final seedItems = <WishItem>[
        WishItem(
          id: _uuid.v4(),
          name: '降噪耳机',
          price: 1299,
          category: '数码',
          note: '等 618 看是否还有更低价。',
          createdAt: now.subtract(const Duration(days: 8)),
          status: ItemStatus.wish,
        ),
        WishItem(
          id: _uuid.v4(),
          name: '咖啡课程',
          price: 399,
          category: '学习',
          note: '先看完手头课程再决定。',
          createdAt: now.subtract(const Duration(days: 21)),
          status: ItemStatus.skipped,
          skippedAt: now.subtract(const Duration(days: 5)),
        ),
        WishItem(
          id: _uuid.v4(),
          name: '设计师台灯',
          price: 569,
          category: '家居',
          note: '风格很喜欢，但先衡量实际使用频率。',
          createdAt: now.subtract(const Duration(days: 15)),
          status: ItemStatus.bought,
          boughtAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final batch = db.batch();
      for (final item in seedItems) {
        batch.insert('items', item.toMap());
      }
      await batch.commit(noResult: true);
    }
  }

  Future<List<WishItem>> fetchItems({ItemStatus? status}) async {
    final db = await _database.database;
    final maps = await db.query(
      'items',
      where: status == null ? null : 'status = ?',
      whereArgs: status == null ? null : [status.value],
      orderBy: 'created_at DESC',
    );

    return maps.map(WishItem.fromMap).toList();
  }

  Future<List<CategoryTag>> fetchCategories() async {
    final db = await _database.database;
    final maps = await db.query('categories', orderBy: 'is_default DESC, name ASC');
    return maps.map(CategoryTag.fromMap).toList();
  }

  Future<void> addItem({
    required String name,
    required double price,
    required String category,
    required String note,
  }) async {
    final db = await _database.database;
    final item = WishItem(
      id: _uuid.v4(),
      name: name,
      price: price,
      category: category,
      note: note,
      createdAt: DateTime.now(),
      status: ItemStatus.wish,
    );

    await db.insert('items', item.toMap());
  }

  Future<void> addCategory(CategoryTag category) async {
    final db = await _database.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateItemStatus(String id, ItemStatus status) async {
    final db = await _database.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'items',
      {
        'status': status.value,
        'skipped_at': status == ItemStatus.skipped ? now : null,
        'bought_at': status == ItemStatus.bought ? now : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<AppStats> buildStats({required StatsFilter filter}) async {
    final db = await _database.database;
    final allItems = (await db.query('items', orderBy: 'created_at ASC'))
        .map(WishItem.fromMap)
        .toList();
    final categories = await fetchCategories();
    final categoryColors = {
      for (final category in categories) category.name: category.colorValue,
    };

    final skippedAll = allItems.where((item) => item.status == ItemStatus.skipped).toList();
    final filteredSkipped = skippedAll.where((item) => _withinFilter(item.skippedAt, filter)).toList();
    final filteredAll = allItems.where((item) => _withinFilter(item.createdAt, filter)).toList();

    final totalSaved = skippedAll.fold<double>(0, (sum, item) => sum + item.price);
    final periodSaved = filteredSkipped.fold<double>(0, (sum, item) => sum + item.price);
    final boughtCount = filteredAll.where((item) => item.status == ItemStatus.bought).length;
    final activeWishes = allItems.where((item) => item.status == ItemStatus.wish).length;

    final trend = _buildTrend(filteredSkipped, filter);
    final monthlySavings = _buildMonthlySavings(skippedAll);
    final categoryBreakdown = _buildCategoryBreakdown(filteredSkipped, categoryColors);

    return AppStats(
      totalSaved: totalSaved,
      periodSaved: periodSaved,
      skippedCount: filteredSkipped.length,
      boughtCount: boughtCount,
      activeWishes: activeWishes,
      trend: trend,
      monthlySavings: monthlySavings,
      categoryBreakdown: categoryBreakdown,
    );
  }

  bool _withinFilter(DateTime? date, StatsFilter filter) {
    if (date == null) return false;
    if (filter == StatsFilter.all) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(date.year, date.month, date.day);

    switch (filter) {
      case StatsFilter.today:
        return current == today;
      case StatsFilter.week:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return !current.isBefore(start);
      case StatsFilter.month:
        return current.year == now.year && current.month == now.month;
      case StatsFilter.year:
        return current.year == now.year;
      case StatsFilter.all:
        return true;
    }
  }

  List<TrendPoint> _buildTrend(List<WishItem> skippedItems, StatsFilter filter) {
    if (skippedItems.isEmpty) {
      return const [
        TrendPoint(label: '空', amount: 0),
      ];
    }

    final Map<String, double> bucket = {};
    for (final item in skippedItems) {
      final date = item.skippedAt!;
      final key = switch (filter) {
        StatsFilter.today => '${date.hour}:00',
        StatsFilter.week || StatsFilter.month => formatMonthDay(date),
        StatsFilter.year || StatsFilter.all => '${date.month}月',
      };
      bucket.update(key, (value) => value + item.price, ifAbsent: () => item.price);
    }

    return bucket.entries
        .map((entry) => TrendPoint(label: entry.key, amount: entry.value))
        .toList();
  }

  List<TrendPoint> _buildMonthlySavings(List<WishItem> skippedItems) {
    final now = DateTime.now();
    final points = <TrendPoint>[];

    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final total = skippedItems
          .where(
            (item) =>
                item.skippedAt?.year == date.year && item.skippedAt?.month == date.month,
          )
          .fold<double>(0, (sum, item) => sum + item.price);
      points.add(TrendPoint(label: formatMonth(date), amount: total));
    }

    return points;
  }

  List<CategoryBreakdown> _buildCategoryBreakdown(
    List<WishItem> skippedItems,
    Map<String, int> categoryColors,
  ) {
    final Map<String, double> bucket = {};
    for (final item in skippedItems) {
      bucket.update(item.category, (value) => value + item.price, ifAbsent: () => item.price);
    }

    return bucket.entries
        .map(
          (entry) => CategoryBreakdown(
            category: entry.key,
            amount: entry.value,
            colorValue: categoryColors[entry.key] ?? fallbackCategoryColor.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  Future<double> currentYearSaved() async {
    final stats = await buildStats(filter: StatsFilter.year);
    return stats.periodSaved;
  }

  Color colorForCategory(String category, List<CategoryTag> categories) {
    return categories
        .firstWhere(
          (item) => item.name == category,
          orElse: () => const CategoryTag(name: '其他', colorValue: 0xFF8F96A3),
        )
        .color;
  }

  Future<void> resetAllData() async {
    final db = await _database.database;
    await db.delete('items');
    await db.delete('categories');
    await seedDefaults();
  }

  double niceMax(Iterable<double> values) {
    final maxValue = values.fold<double>(0, max);
    if (maxValue <= 0) return 100;
    return (maxValue * 1.2).ceilToDouble();
  }
}
