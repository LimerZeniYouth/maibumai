import 'package:flutter/material.dart';
import 'package:maibumai/data/item_repository.dart';
import 'package:maibumai/models/app_stats.dart';
import 'package:maibumai/models/category_tag.dart';
import 'package:maibumai/models/item_status.dart';
import 'package:maibumai/models/stats_filter.dart';
import 'package:maibumai/models/wish_item.dart';

class AppProvider extends ChangeNotifier {
  AppProvider(this._repository);

  final ItemRepository _repository;

  bool _loading = true;
  bool get loading => _loading;

  List<WishItem> _items = [];
  List<WishItem> get items => _items;

  List<CategoryTag> _categories = [];
  List<CategoryTag> get categories => _categories;

  StatsFilter _statsFilter = StatsFilter.month;
  StatsFilter get statsFilter => _statsFilter;

  AppStats _stats = const AppStats(
    totalSaved: 0,
    periodSaved: 0,
    skippedCount: 0,
    boughtCount: 0,
    activeWishes: 0,
    trend: [],
    monthlySavings: [],
    categoryBreakdown: [],
  );
  AppStats get stats => _stats;

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();
    await _repository.seedDefaults();
    await refresh();
  }

  Future<void> refresh() async {
    _items = await _repository.fetchItems();
    _categories = await _repository.fetchCategories();
    _stats = await _repository.buildStats(filter: _statsFilter);
    _loading = false;
    notifyListeners();
  }

  Future<void> addItem({
    required String name,
    required double price,
    required String category,
    required String note,
  }) async {
    await _repository.addItem(
      name: name,
      price: price,
      category: category,
      note: note,
    );
    await refresh();
  }

  Future<void> addCategory(CategoryTag category) async {
    await _repository.addCategory(category);
    await refresh();
  }

  Future<void> markItem(String id, ItemStatus status) async {
    await _repository.updateItemStatus(id, status);
    await refresh();
  }

  Future<void> updateStatsFilter(StatsFilter filter) async {
    _statsFilter = filter;
    _stats = await _repository.buildStats(filter: filter);
    notifyListeners();
  }

  Future<void> resetAllData() async {
    await _repository.resetAllData();
    await refresh();
  }
}
