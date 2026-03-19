
import 'package:flutter/material.dart';
import 'package:maibumai/models/item_status.dart';
import 'package:maibumai/models/wish_item.dart';
import 'package:maibumai/providers/app_provider.dart';
import 'package:maibumai/screens/add/add_item_sheet.dart';
import 'package:maibumai/utils/formatters.dart';
import 'package:maibumai/widgets/glass_card.dart';
import 'package:maibumai/widgets/wish_item_card.dart';
import 'package:provider/provider.dart';

enum _HomeSort { latest, oldest, priceHigh, priceLow }
enum _HomeFilter { all, wait3Days, wait7Days, dueNow }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  _HomeSort _sort = _HomeSort.latest;
  _HomeFilter _filter = _HomeFilter.all;
  String _query = '';
  final Set<String> _selectedIds = <String>{};

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final wishItems = provider.activeWishItems;
    final dueItems = provider.dueWishItems;
    final totalWishValue =
        wishItems.fold<double>(0, (sum, item) => sum + item.price);

    final filtered = wishItems.where(_matchFilter).where(_matchQuery).toList();
    _sortItems(filtered);

    final filteredIds = filtered.map((item) => item.id).toSet();
    _selectedIds.removeWhere((id) => !filteredIds.contains(id));

    return SafeArea(
      child: Stack(
        children: [
          const _HomeBackdrop(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopHeader(
                        totalWishValue: totalWishValue,
                        dueCount: dueItems.length,
                      ),
                      const SizedBox(height: 16),
                      _SearchInput(controller: _searchController),
                      const SizedBox(height: 12),
                      if (_selectionMode)
                        _SelectionToolbar(
                          selectedCount: _selectedIds.length,
                          allSelected: filtered.isNotEmpty &&
                              _selectedIds.length == filtered.length,
                          onSelectAll: () => _selectAll(filtered),
                          onClear: _clearSelection,
                          onEdit: _selectedIds.length == 1
                              ? () => _editSelected(filtered)
                              : null,
                          onMarkBought: () =>
                              _markSelected(context, ItemStatus.bought),
                          onMarkSkipped: () =>
                              _markSelected(context, ItemStatus.skipped),
                          onDelete: () => _deleteSelected(context),
                        )
                      else
                        _ToolbarRow(
                          filterLabel: _filterLabel(_filter),
                          sortLabel: _sortLabel(_sort),
                          count: filtered.length,
                          dueCount: dueItems.length,
                          onFilterTap: _showFilterMenu,
                          onSortTap: _showSortMenu,
                        ),
                      if (!_selectionMode && dueItems.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DueReviewPanel(
                          items: dueItems.take(3).toList(),
                          totalCount: dueItems.length,
                          onReview: (item) => _showReviewSheet(context, item),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 112),
                    child: _EmptyWishCard(),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final selected = _selectedIds.contains(item.id);
                      final card = WishItemCard(
                        item: item,
                        categories: provider.categories,
                        selectionMode: _selectionMode,
                        selected: selected,
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelection(item.id);
                          } else if (item.remindAt != null &&
                              daysUntil(item.remindAt!) <= 0) {
                            _showReviewSheet(context, item);
                          }
                        },
                        onLongPress: () => _toggleSelection(item.id),
                        onEdit: () => _openEditSheet(item),
                      );

                      if (_selectionMode) {
                        return card;
                      }

                      return Dismissible(
                        key: ValueKey(item.id),
                        background: const _SwipeAction(
                          alignment: Alignment.centerLeft,
                          color: Color(0xFF5CC97B),
                          icon: Icons.close_rounded,
                          label: '先不买',
                        ),
                        secondaryBackground: const _SwipeAction(
                          alignment: Alignment.centerRight,
                          color: Color(0xFF4B7BFF),
                          icon: Icons.check_rounded,
                          label: '已购买',
                        ),
                        confirmDismiss: (direction) async {
                          final status = direction == DismissDirection.startToEnd
                              ? ItemStatus.skipped
                              : ItemStatus.bought;
                          await _handleStatusChange(context, item, status);
                          return true;
                        },
                        child: card,
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleStatusChange(
    BuildContext context,
    WishItem item,
    ItemStatus status,
  ) async {
    final provider = context.read<AppProvider>();
    await provider.markItem(item.id, status);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    final content = status == ItemStatus.bought
        ? '已将 ${item.name} 标记为已购买'
        : '已将 ${item.name} 移出心愿单';

    messenger.showSnackBar(
      SnackBar(
        content: Text(content),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () => context.read<AppProvider>().restoreItem(item.id),
        ),
      ),
    );
  }

  bool _matchFilter(WishItem item) {
    final waiting = daysSince(item.createdAt);
    final isDue = item.remindAt != null && daysUntil(item.remindAt!) <= 0;
    switch (_filter) {
      case _HomeFilter.all:
        return true;
      case _HomeFilter.wait3Days:
        return waiting >= 3;
      case _HomeFilter.wait7Days:
        return waiting >= 7;
      case _HomeFilter.dueNow:
        return isDue;
    }
  }

  bool _matchQuery(WishItem item) {
    if (_query.isEmpty) return true;
    return item.name.toLowerCase().contains(_query) ||
        item.category.toLowerCase().contains(_query) ||
        item.note.toLowerCase().contains(_query);
  }

  void _sortItems(List<WishItem> items) {
    switch (_sort) {
      case _HomeSort.latest:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _HomeSort.oldest:
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _HomeSort.priceHigh:
        items.sort((a, b) => b.price.compareTo(a.price));
      case _HomeSort.priceLow:
        items.sort((a, b) => a.price.compareTo(b.price));
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<WishItem> items) {
    setState(() {
      if (_selectedIds.length == items.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(items.map((item) => item.id));
      }
    });
  }

  void _clearSelection() {
    setState(_selectedIds.clear);
  }
  Future<void> _markSelected(BuildContext context, ItemStatus status) async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await provider.markItems(ids, status);
    if (!mounted) return;
    _clearSelection();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          status == ItemStatus.bought ? '已批量标记为已购买' : '已批量标记为先不买',
        ),
      ),
    );
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('删除选中清单'),
              content: Text('确定删除已选中的 ${ids.length} 项吗？此操作不可撤销。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await provider.deleteItems(ids);
    if (!mounted) return;
    _clearSelection();
    messenger.showSnackBar(
      const SnackBar(content: Text('已删除选中清单')),
    );
  }

  void _editSelected(List<WishItem> filtered) {
    if (_selectedIds.length != 1) return;
    final id = _selectedIds.first;
    final item = filtered.firstWhere((element) => element.id == id);
    _clearSelection();
    _openEditSheet(item);
  }

  Future<void> _openEditSheet(WishItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => AddItemSheet(item: item),
    );
  }

  Future<void> _showReviewSheet(BuildContext context, WishItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _ReviewSheet(
          item: item,
          onEdit: () async {
            Navigator.of(sheetContext).pop();
            await _openEditSheet(item);
          },
          onBought: () async {
            Navigator.of(sheetContext).pop();
            await _handleStatusChange(context, item, ItemStatus.bought);
          },
          onSkipped: () async {
            Navigator.of(sheetContext).pop();
            await _handleStatusChange(context, item, ItemStatus.skipped);
          },
          onDelay3Days: () async {
            Navigator.of(sheetContext).pop();
            await context.read<AppProvider>().postponeItem(item.id, 3);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.name} 已延后 3 天复看')),
            );
          },
          onDelay7Days: () async {
            Navigator.of(sheetContext).pop();
            await context.read<AppProvider>().postponeItem(item.id, 7);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.name} 已延后 7 天复看')),
            );
          },
        );
      },
    );
  }

  String _filterLabel(_HomeFilter filter) {
    switch (filter) {
      case _HomeFilter.all:
        return '全部';
      case _HomeFilter.wait3Days:
        return '等 3 天';
      case _HomeFilter.wait7Days:
        return '等 7 天';
      case _HomeFilter.dueNow:
        return '待复看';
    }
  }

  String _sortLabel(_HomeSort sort) {
    switch (sort) {
      case _HomeSort.latest:
        return '最新';
      case _HomeSort.oldest:
        return '最早';
      case _HomeSort.priceHigh:
        return '价格高';
      case _HomeSort.priceLow:
        return '价格低';
    }
  }

  Future<void> _showFilterMenu() async {
    final result = await showModalBottomSheet<_HomeFilter>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _SelectPanel<_HomeFilter>(
          title: '筛选条件',
          current: _filter,
          items: const [
            (_HomeFilter.all, '全部'),
            (_HomeFilter.wait3Days, '等待 3 天以上'),
            (_HomeFilter.wait7Days, '等待 7 天以上'),
            (_HomeFilter.dueNow, '已经到复看期'),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => _filter = result);
    }
  }

  Future<void> _showSortMenu() async {
    final result = await showModalBottomSheet<_HomeSort>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _SelectPanel<_HomeSort>(
          title: '排序方式',
          current: _sort,
          items: const [
            (_HomeSort.latest, '最新'),
            (_HomeSort.oldest, '最早'),
            (_HomeSort.priceHigh, '价格从高到低'),
            (_HomeSort.priceLow, '价格从低到高'),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => _sort = result);
    }
  }
}

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF68B8FF).withValues(alpha: 0.18),
                    const Color(0xFF68B8FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 190,
            left: -120,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8EDCFF).withValues(alpha: 0.14),
                    const Color(0xFF8EDCFF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.totalWishValue, required this.dueCount});

  final double totalWishValue;
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _HeaderMark(theme: theme),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('买不买', style: theme.textTheme.headlineMedium),
                            const SizedBox(height: 2),
                            Text(
                              dueCount > 0 ? '有 $dueCount 项该二次确认了' : '理性消费第一步',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: dueCount > 0
                                    ? const Color(0xFFFF8A47)
                                    : theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _HeaderValue(totalWishValue: totalWishValue),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _HeaderMark(theme: theme),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('买不买', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 2),
                        Text(
                          dueCount > 0 ? '有 $dueCount 项该二次确认了' : '理性消费第一步',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: dueCount > 0
                                ? const Color(0xFFFF8A47)
                                : theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _HeaderValue(totalWishValue: totalWishValue),
                ],
              );
      },
    );
  }
}
class _HeaderMark extends StatelessWidget {
  const _HeaderMark({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF20B2FF), Color(0xFF5572FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4EA8FF).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _HeaderValue extends StatelessWidget {
  const _HeaderValue({required this.totalWishValue});

  final double totalWishValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '待购总额',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          formatCurrency(totalWishValue),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF1EA7FF),
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.80),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF93A8C7).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜索想要的物品...',
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          prefixIcon:
              Icon(Icons.search_rounded, color: Theme.of(context).hintColor),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}

class _ToolbarRow extends StatelessWidget {
  const _ToolbarRow({
    required this.filterLabel,
    required this.sortLabel,
    required this.count,
    required this.dueCount,
    required this.onFilterTap,
    required this.onSortTap,
  });

  final String filterLabel;
  final String sortLabel;
  final int count;
  final int dueCount;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.68),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8EA6C6).withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ToolbarChip(
                    icon: Icons.filter_alt_outlined,
                    label: filterLabel,
                    onTap: onFilterTap,
                  ),
                  _ToolbarChip(
                    icon: Icons.sort_rounded,
                    label: sortLabel,
                    onTap: onSortTap,
                  ),
                  if (!compact)
                    _CountBadge(count: count, dueCount: dueCount)
                  else
                    const SizedBox.shrink(),
                ],
              ),
              if (compact) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _CountBadge(count: count, dueCount: dueCount),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.selectedCount,
    required this.allSelected,
    required this.onSelectAll,
    required this.onClear,
    required this.onEdit,
    required this.onMarkBought,
    required this.onMarkSkipped,
    required this.onDelete,
  });

  final int selectedCount;
  final bool allSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback? onEdit;
  final VoidCallback onMarkBought;
  final VoidCallback onMarkSkipped;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('已选 $selectedCount 项',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: onSelectAll,
                child: Text(allSelected ? '取消全选' : '全选当前结果'),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('退出'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onMarkBought,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('批量买了'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onMarkSkipped,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('批量不买'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('删除'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DueReviewPanel extends StatelessWidget {
  const _DueReviewPanel({
    required this.items,
    required this.totalCount,
    required this.onReview,
  });

  final List<WishItem> items;
  final int totalCount;
  final ValueChanged<WishItem> onReview;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A47).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFFF8A47),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('到期复看提醒',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '当前有 $totalCount 项该做二次确认',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            _DueReviewTile(item: item, onReview: () => onReview(item)),
            if (item != items.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _DueReviewTile extends StatelessWidget {
  const _DueReviewTile({required this.item, required this.onReview});

  final WishItem item;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatCurrency(item.price)} · ${formatCoolingDaysLabel(item.coolingDays)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(
            onPressed: onReview,
            child: const Text('去确认'),
          ),
        ],
      ),
    );
  }
}
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.dueCount});

  final int count;
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dueCount > 0
            ? const Color(0xFFFF8A47).withValues(alpha: 0.10)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dueCount > 0 ? '$count 项 · $dueCount 待复看' : '$count 个心愿',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dueCount > 0
                  ? const Color(0xFFFF8A47)
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  const _ToolbarChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.78),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).hintColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWishCard extends StatelessWidget {
  const _EmptyWishCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.84),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF98AEC9).withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFBFE8FF).withValues(alpha: 0.72),
                  const Color(0xFFDFF3FF).withValues(alpha: 0.34),
                ],
              ),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 52,
              color: Color(0xFF1EA7FF),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '还没有想要的物品',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '点击中间的 +，把此刻的消费冲动先温柔地收进清单里。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _SelectPanel<T> extends StatelessWidget {
  const _SelectPanel({
    required this.title,
    required this.current,
    required this.items,
  });

  final String title;
  final T current;
  final List<(T, String)> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.$2),
              trailing: item.$1 == current
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => Navigator.of(context).pop(item.$1),
            ),
        ],
      ),
    );
  }
}

class _ReviewSheet extends StatelessWidget {
  const _ReviewSheet({
    required this.item,
    required this.onEdit,
    required this.onBought,
    required this.onSkipped,
    required this.onDelay3Days,
    required this.onDelay7Days,
  });

  final WishItem item;
  final VoidCallback onEdit;
  final VoidCallback onBought;
  final VoidCallback onSkipped;
  final VoidCallback onDelay3Days;
  final VoidCallback onDelay7Days;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('二次确认', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            '${item.name} 已经过了冷静期，现在重新看一眼再决定。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  '${formatCurrency(item.price)} · ${item.category} · ${formatCoolingDaysLabel(item.coolingDays)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(item.note,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onBought,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('现在买'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onSkipped,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('先不买'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDelay3Days,
                  child: const Text('再等 3 天'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDelay7Days,
                  child: const Text('再等 7 天'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('编辑这项'),
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignment == Alignment.centerRight) ...[
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
            ],
            Icon(icon, color: color),
            if (alignment == Alignment.centerLeft) ...[
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}
