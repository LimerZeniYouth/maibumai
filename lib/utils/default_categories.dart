import 'package:flutter/material.dart';
import 'package:maibumai/models/category_tag.dart';

const defaultCategories = <CategoryTag>[
  CategoryTag(name: '数码', colorValue: 0xFF6C8EFF, isDefault: true),
  CategoryTag(name: '衣物', colorValue: 0xFFFF7D6B, isDefault: true),
  CategoryTag(name: '食品', colorValue: 0xFF58C27D, isDefault: true),
  CategoryTag(name: '娱乐', colorValue: 0xFF9B6BFF, isDefault: true),
  CategoryTag(name: '学习', colorValue: 0xFFFFB547, isDefault: true),
  CategoryTag(name: '家居', colorValue: 0xFF4BB7C9, isDefault: true),
  CategoryTag(name: '其他', colorValue: 0xFF8F96A3, isDefault: true),
];

const fallbackCategoryColor = Color(0xFF8F96A3);
