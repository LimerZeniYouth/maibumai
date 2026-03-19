import 'package:maibumai/models/item_status.dart';

class WishItem {
  const WishItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.note,
    required this.createdAt,
    required this.status,
    required this.coolingDays,
    this.remindAt,
    this.skippedAt,
    this.boughtAt,
  });

  final String id;
  final String name;
  final double price;
  final String category;
  final String note;
  final DateTime createdAt;
  final ItemStatus status;
  final int coolingDays;
  final DateTime? remindAt;
  final DateTime? skippedAt;
  final DateTime? boughtAt;

  WishItem copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    String? note,
    DateTime? createdAt,
    ItemStatus? status,
    int? coolingDays,
    DateTime? remindAt,
    bool clearRemindAt = false,
    DateTime? skippedAt,
    bool clearSkippedAt = false,
    DateTime? boughtAt,
    bool clearBoughtAt = false,
  }) {
    return WishItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      coolingDays: coolingDays ?? this.coolingDays,
      remindAt: clearRemindAt ? null : remindAt ?? this.remindAt,
      skippedAt: clearSkippedAt ? null : skippedAt ?? this.skippedAt,
      boughtAt: clearBoughtAt ? null : boughtAt ?? this.boughtAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'status': status.value,
      'cooling_days': coolingDays,
      'remind_at': remindAt?.millisecondsSinceEpoch,
      'skipped_at': skippedAt?.millisecondsSinceEpoch,
      'bought_at': boughtAt?.millisecondsSinceEpoch,
    };
  }

  factory WishItem.fromMap(Map<String, Object?> map) {
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int);
    final status = ItemStatusX.fromValue(map['status']! as String);
    final coolingDays = (map['cooling_days'] as int?) ?? 3;
    final remindAtRaw = map['remind_at'] as int?;

    return WishItem(
      id: map['id']! as String,
      name: map['name']! as String,
      price: (map['price']! as num).toDouble(),
      category: map['category']! as String,
      note: (map['note'] as String?) ?? '',
      createdAt: createdAt,
      status: status,
      coolingDays: coolingDays,
      remindAt: remindAtRaw != null
          ? DateTime.fromMillisecondsSinceEpoch(remindAtRaw)
          : status == ItemStatus.wish
              ? createdAt.add(Duration(days: coolingDays))
              : null,
      skippedAt: map['skipped_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['skipped_at']! as int),
      boughtAt: map['bought_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['bought_at']! as int),
    );
  }
}
