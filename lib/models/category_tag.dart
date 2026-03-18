import 'package:flutter/material.dart';

class CategoryTag {
  const CategoryTag({
    required this.name,
    required this.colorValue,
    this.isDefault = false,
  });

  final String name;
  final int colorValue;
  final bool isDefault;

  Color get color => Color(colorValue);

  Map<String, Object?> toMap() => {
        'name': name,
        'color_value': colorValue,
        'is_default': isDefault ? 1 : 0,
      };

  factory CategoryTag.fromMap(Map<String, Object?> map) => CategoryTag(
        name: map['name']! as String,
        colorValue: map['color_value']! as int,
        isDefault: (map['is_default']! as int) == 1,
      );
}
