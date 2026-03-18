import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maibumai/models/category_tag.dart';
import 'package:maibumai/providers/app_provider.dart';
import 'package:maibumai/widgets/animated_primary_button.dart';
import 'package:maibumai/widgets/glass_card.dart';

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;

  late final AnimationController _successController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  final _palette = const [
    Color(0xFF6C8EFF),
    Color(0xFFFF7D6B),
    Color(0xFF58C27D),
    Color(0xFF9B6BFF),
    Color(0xFFFFB547),
    Color(0xFF4BB7C9),
  ];

  @override
  void initState() {
    super.initState();
    final categories = context.read<AppProvider>().categories;
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppProvider>().categories;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('添加想买的东西', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    '先记下来，不急着下单。给自己一点冷静期。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _HintChip(icon: Icons.schedule_rounded, label: '先放 24h'),
                      _HintChip(icon: Icons.psychology_rounded, label: '避免冲动'),
                      _HintChip(icon: Icons.savings_rounded, label: '留下复盘'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '物品名称',
                      hintText: '例如：降噪耳机 / 跑鞋 / 台灯',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? '请输入物品名称' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '价格',
                      hintText: '输入你现在看到的价格',
                      prefixText: '¥ ',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) return '请输入正确价格';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories
                        .map((category) => DropdownMenuItem(
                              value: category.name,
                              child: Text(category.name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value),
                    decoration: const InputDecoration(labelText: '类别'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _showAddCategoryDialog(context),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('自定义类别'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: '备注（可选）',
                      hintText: '为什么想买？等什么时机再决定？',
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _successController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 1 - _successController.value,
                        child: Transform.scale(
                          scale: 1 - (_successController.value * 0.05),
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedPrimaryButton(
                      label: '加入心愿单',
                      icon: Icons.auto_awesome_rounded,
                      onTap: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<AppProvider>().addItem(
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          category: _selectedCategory!,
          note: _noteController.text.trim(),
        );

    await _successController.forward();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已成功加入心愿单')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final appProvider = context.read<AppProvider>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('新建类别'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: '类别名称'),
              validator: (value) => value == null || value.trim().isEmpty ? '请输入类别名称' : null,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final name = controller.text.trim();
                final color = _palette[Random().nextInt(_palette.length)];
                await appProvider.addCategory(
                  CategoryTag(name: name, colorValue: color.value),
                );
                if (!mounted || !dialogContext.mounted) return;
                setState(() => _selectedCategory = name);
                Navigator.pop(dialogContext);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
