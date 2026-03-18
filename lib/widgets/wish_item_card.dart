import 'package:flutter/material.dart';
import 'package:maibumai/models/category_tag.dart';
import 'package:maibumai/models/wish_item.dart';
import 'package:maibumai/utils/formatters.dart';
import 'package:maibumai/widgets/category_chip.dart';
import 'package:maibumai/widgets/glass_card.dart';

class WishItemCard extends StatelessWidget {
  const WishItemCard({
    super.key,
    required this.item,
    required this.categories,
  });

  final WishItem item;
  final List<CategoryTag> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = categories.where((tag) => tag.name == item.category).firstOrNull;
    final categoryColor = category?.color ?? const Color(0xFF8F96A3);
    final waitingDays = daysSince(item.createdAt);
    final waitAccent = waitingDays >= 7
        ? const Color(0xFF5CC97B)
        : waitingDays >= 3
            ? const Color(0xFFFFB547)
            : theme.colorScheme.primary;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _WaitBadge(
                      label: formatWaitingLabel(item.createdAt),
                      color: waitAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatCurrency(item.price),
                style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CategoryChip(label: item.category, color: categoryColor),
              _InfoTag(
                icon: Icons.calendar_today_rounded,
                label: formatMonthDay(item.createdAt),
              ),
              _InfoTag(
                icon: Icons.hourglass_bottom_rounded,
                label: waitingDays == 0 ? '建议明天再看' : '再想一想',
              ),
            ],
          ),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                item.note,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaitBadge extends StatelessWidget {
  const _WaitBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Theme.of(context).hintColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
