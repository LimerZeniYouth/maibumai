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
      'skipped_at': skippedAt?.millisecondsSinceEpoch,
      'bought_at': boughtAt?.millisecondsSinceEpoch,
    };
  }

  factory WishItem.fromMap(Map<String, Object?> map) {
    return WishItem(
      id: map['id']! as String,
      name: map['name']! as String,
      price: (map['price']! as num).toDouble(),
      category: map['category']! as String,
      note: (map['note'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
      status: ItemStatusX.fromValue(map['status']! as String),
      skippedAt: map['skipped_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['skipped_at']! as int),
      boughtAt: map['bought_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['bought_at']! as int),
    );
  }
}
