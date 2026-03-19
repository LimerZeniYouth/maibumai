import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
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

  final List<WishItem> _memoryItems = <WishItem>[];
  final List<CategoryTag> _memoryCategories = <CategoryTag>[];

  bool get _useInMemoryStore => kIsWeb;

  Future<void> seedDefaults() async {
    if (_useInMemoryStore) {
      if (_memoryCategories.isEmpty) {
        _memoryCategories.addAll(defaultCategories);
      }

      if (_memoryItems.isEmpty) {
        _memoryItems.addAll(_seedItems());
      }
      return;
    }

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
      final batch = db.batch();
      for (final item in _seedItems()) {
        batch.insert('items', item.toMap());
      }
      await batch.commit(noResult: true);
    }
  }

  Future<List<WishItem>> fetchItems({ItemStatus? status}) async {
    if (_useInMemoryStore) {
      final items = status == null
          ? List<WishItem>.from(_memoryItems)
          : _memoryItems.where((item) => item.status == status).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    }

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
    if (_useInMemoryStore) {
      return _sortedMemoryCategories();
    }

    final db = await _database.database;
    final maps =
        await db.query('categories', orderBy: 'is_default DESC, name ASC');
    return maps.map(CategoryTag.fromMap).toList();
  }

  Future<void> addItem({
    required String name,
    required double price,
    required String category,
    required String note,
    required int coolingDays,
  }) async {
    final now = DateTime.now();
    final item = WishItem(
      id: _uuid.v4(),
      name: name,
      price: price,
      category: category,
      note: note,
      createdAt: now,
      status: ItemStatus.wish,
      coolingDays: coolingDays,
      remindAt: now.add(Duration(days: coolingDays)),
    );

    if (_useInMemoryStore) {
      _memoryItems.add(item);
      return;
    }

    final db = await _database.database;
    await db.insert('items', item.toMap());
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required double price,
    required String category,
    required String note,
    required int coolingDays,
  }) async {
    final existing = await _findItemById(id);
    if (existing == null) return;

    final nextReminder = existing.status == ItemStatus.wish
        ? _reviewAtForUpdatedItem(existing, coolingDays)
        : null;
    final updated = existing.copyWith(
      name: name,
      price: price,
      category: category,
      note: note,
      coolingDays: coolingDays,
      remindAt: nextReminder,
      clearRemindAt: existing.status != ItemStatus.wish,
    );

    if (_useInMemoryStore) {
      final index = _memoryItems.indexWhere((item) => item.id == id);
      if (index == -1) return;
      _memoryItems[index] = updated;
      return;
    }

    final db = await _database.database;
    await db.update(
      'items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addCategory(CategoryTag category) async {
    if (_useInMemoryStore) {
      _memoryCategories.removeWhere((item) => item.name == category.name);
      _memoryCategories.add(category);
      return;
    }

    final db = await _database.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateItemStatus(String id, ItemStatus status) async {
    final existing = await _findItemById(id);
    if (existing == null) return;

    final updated = _copyWithStatus(existing, status);

    if (_useInMemoryStore) {
      final index = _memoryItems.indexWhere((item) => item.id == id);
      if (index == -1) return;
      _memoryItems[index] = updated;
      return;
    }

    final db = await _database.database;
    await db.update(
      'items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateItemsStatus(List<String> ids, ItemStatus status) async {
    if (ids.isEmpty) return;

    if (_useInMemoryStore) {
      for (final id in ids) {
        final index = _memoryItems.indexWhere((item) => item.id == id);
        if (index == -1) continue;
        _memoryItems[index] = _copyWithStatus(_memoryItems[index], status);
      }
      return;
    }

    final db = await _database.database;
    final batch = db.batch();
    for (final id in ids) {
      final item = await _findItemById(id);
      if (item == null) continue;
      batch.update(
        'items',
        _copyWithStatus(item, status).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> restoreItem(String id) async {
    final existing = await _findItemById(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      status: ItemStatus.wish,
      remindAt: DateTime.now().add(Duration(days: existing.coolingDays)),
      clearSkippedAt: true,
      clearBoughtAt: true,
    );

    if (_useInMemoryStore) {
      final index = _memoryItems.indexWhere((item) => item.id == id);
      if (index == -1) return;
      _memoryItems[index] = updated;
      return;
    }

    final db = await _database.database;
    await db.update(
      'items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> postponeItem(String id, int coolingDays) async {
    final existing = await _findItemById(id);
    if (existing == null) return;

    final updated = existing.copyWith(
      status: ItemStatus.wish,
      coolingDays: coolingDays,
      remindAt: DateTime.now().add(Duration(days: coolingDays)),
      clearSkippedAt: true,
      clearBoughtAt: true,
    );

    if (_useInMemoryStore) {
      final index = _memoryItems.indexWhere((item) => item.id == id);
      if (index == -1) return;
      _memoryItems[index] = updated;
      return;
    }

    final db = await _database.database;
    await db.update(
      'items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteItems(List<String> ids) async {
    if (ids.isEmpty) return;

    if (_useInMemoryStore) {
      _memoryItems.removeWhere((item) => ids.contains(item.id));
      return;
    }

    final db = await _database.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      'items',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<String> exportBackupJson() async {
    final payload = <String, Object?>{
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'categories':
          (await _exportCategories()).map((item) => item.toMap()).toList(),
      'items': (await _exportItems()).map((item) => item.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> importBackupJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup payload.');
    }

    final itemsJson = decoded['items'];
    final categoriesJson = decoded['categories'];

    if (itemsJson is! List || categoriesJson is! List) {
      throw const FormatException('Backup file is missing required fields.');
    }

    final importedItems = itemsJson
        .map((item) => WishItem.fromMap(Map<String, Object?>.from(item as Map)))
        .toList();
    final importedCategories = categoriesJson
        .map((item) =>
            CategoryTag.fromMap(Map<String, Object?>.from(item as Map)))
        .toList();

    if (_useInMemoryStore) {
      _memoryItems
        ..clear()
        ..addAll(importedItems);
      _memoryCategories
        ..clear()
        ..addAll(importedCategories);
      return;
    }

    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete('items');
      await txn.delete('categories');

      final categoryBatch = txn.batch();
      for (final category in importedCategories) {
        categoryBatch.insert('categories', category.toMap());
      }
      await categoryBatch.commit(noResult: true);

      final itemBatch = txn.batch();
      for (final item in importedItems) {
        itemBatch.insert('items', item.toMap());
      }
      await itemBatch.commit(noResult: true);
    });
  }

  Future<AppStats> buildStats({required StatsFilter filter}) async {
    final List<WishItem> allItems;
    final List<CategoryTag> categories;

    if (_useInMemoryStore) {
      allItems = List<WishItem>.from(_memoryItems)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      categories = _sortedMemoryCategories();
    } else {
      final db = await _database.database;
      allItems = (await db.query('items', orderBy: 'created_at ASC'))
          .map(WishItem.fromMap)
          .toList();
      categories = await fetchCategories();
    }

    final categoryColors = {
      for (final category in categories) category.name: category.colorValue,
    };

    final skippedAll =
        allItems.where((item) => item.status == ItemStatus.skipped).toList();
    final filteredSkipped = skippedAll
        .where((item) => _withinFilter(item.skippedAt, filter))
        .toList();
    final filteredAll = allItems
        .where((item) => _withinFilter(item.createdAt, filter))
        .toList();

    final totalSaved =
        skippedAll.fold<double>(0, (sum, item) => sum + item.price);
    final periodSaved =
        filteredSkipped.fold<double>(0, (sum, item) => sum + item.price);
    final boughtCount =
        filteredAll.where((item) => item.status == ItemStatus.bought).length;
    final activeWishes =
        allItems.where((item) => item.status == ItemStatus.wish).length;

    final trend = _buildTrend(filteredSkipped, filter);
    final monthlySavings = _buildMonthlySavings(skippedAll);
    final categoryBreakdown =
        _buildCategoryBreakdown(filteredSkipped, categoryColors);

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
      return const [TrendPoint(label: '-', amount: 0)];
    }

    final Map<String, double> bucket = {};
    for (final item in skippedItems) {
      final date = item.skippedAt!;
      final key = switch (filter) {
        StatsFilter.today => '${date.hour}:00',
        StatsFilter.week || StatsFilter.month => formatMonthDay(date),
        StatsFilter.year || StatsFilter.all => '${date.month}m',
      };
      bucket.update(key, (value) => value + item.price,
          ifAbsent: () => item.price);
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
                item.skippedAt?.year == date.year &&
                item.skippedAt?.month == date.month,
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
      bucket.update(item.category, (value) => value + item.price,
          ifAbsent: () => item.price);
    }

    return bucket.entries
        .map(
          (entry) => CategoryBreakdown(
            category: entry.key,
            amount: entry.value,
            colorValue:
                categoryColors[entry.key] ?? fallbackCategoryColor.toARGB32(),
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
          orElse: () =>
              const CategoryTag(name: 'other', colorValue: 0xFF8F96A3),
        )
        .color;
  }

  Future<void> resetAllData() async {
    if (_useInMemoryStore) {
      _memoryItems.clear();
      _memoryCategories.clear();
      await seedDefaults();
      return;
    }

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

  List<CategoryTag> _sortedMemoryCategories() {
    final categories = List<CategoryTag>.from(_memoryCategories);
    categories.sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    return categories;
  }

  Future<List<WishItem>> _exportItems() async {
    if (_useInMemoryStore) {
      return List<WishItem>.from(_memoryItems);
    }

    return fetchItems();
  }

  Future<List<CategoryTag>> _exportCategories() async {
    if (_useInMemoryStore) {
      return List<CategoryTag>.from(_memoryCategories);
    }

    return fetchCategories();
  }

  Future<WishItem?> _findItemById(String id) async {
    if (_useInMemoryStore) {
      final index = _memoryItems.indexWhere((item) => item.id == id);
      return index == -1 ? null : _memoryItems[index];
    }

    final db = await _database.database;
    final maps = await db.query('items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return WishItem.fromMap(maps.first);
  }

  WishItem _copyWithStatus(WishItem item, ItemStatus status) {
    final now = DateTime.now();
    return item.copyWith(
      status: status,
      remindAt: status == ItemStatus.wish
          ? now.add(Duration(days: item.coolingDays))
          : null,
      clearRemindAt: status != ItemStatus.wish,
      skippedAt: status == ItemStatus.skipped ? now : null,
      clearSkippedAt: status != ItemStatus.skipped,
      boughtAt: status == ItemStatus.bought ? now : null,
      clearBoughtAt: status != ItemStatus.bought,
    );
  }

  DateTime _reviewAtForUpdatedItem(WishItem item, int coolingDays) {
    if (coolingDays != item.coolingDays) {
      return DateTime.now().add(Duration(days: coolingDays));
    }
    return item.remindAt ?? item.createdAt.add(Duration(days: coolingDays));
  }

  List<WishItem> _seedItems() {
    final now = DateTime.now();
    return [
      WishItem(
        id: _uuid.v4(),
        name: 'Noise Cancelling Headphones',
        price: 1299,
        category: defaultCategories[0].name,
        note: 'Wait for next promo event.',
        createdAt: now.subtract(const Duration(days: 8)),
        status: ItemStatus.wish,
        coolingDays: 7,
        remindAt: now.subtract(const Duration(days: 1)),
      ),
      WishItem(
        id: _uuid.v4(),
        name: 'Coffee Course',
        price: 399,
        category: defaultCategories[4].name,
        note: 'Finish current lessons first.',
        createdAt: now.subtract(const Duration(days: 21)),
        status: ItemStatus.skipped,
        coolingDays: 3,
        skippedAt: now.subtract(const Duration(days: 5)),
      ),
      WishItem(
        id: _uuid.v4(),
        name: 'Designer Desk Lamp',
        price: 569,
        category: defaultCategories[5].name,
        note: 'Bought after confirming daily use.',
        createdAt: now.subtract(const Duration(days: 15)),
        status: ItemStatus.bought,
        coolingDays: 7,
        boughtAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
