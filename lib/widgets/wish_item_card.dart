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
    this.selectionMode = false,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.onEdit,
  });

  final WishItem item;
  final List<CategoryTag> categories;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category =
        categories.where((tag) => tag.name == item.category).firstOrNull;
    final categoryColor = category?.color ?? const Color(0xFF8F96A3);
    final waitingDays = daysSince(item.createdAt);
    final waitAccent = waitingDays >= 7
        ? const Color(0xFF5CC97B)
        : waitingDays >= 3
            ? const Color(0xFFFFB547)
            : theme.colorScheme.primary;
    final reviewDue = item.remindAt != null && daysUntil(item.remindAt!) <= 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectionMode) ...[
                  _SelectionDot(selected: selected),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatCurrency(item.price),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (!selectionMode && onEdit != null) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: onEdit,
                      splashRadius: 18,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _WaitBadge(
                    label: formatWaitingLabel(item.createdAt),
                    color: waitAccent,
                  ),
                  const SizedBox(width: 6),
                  CategoryChip(label: item.category, color: categoryColor),
                  const SizedBox(width: 6),
                  _InfoTag(
                    icon: Icons.timer_outlined,
                    label: formatCoolingDaysLabel(item.coolingDays),
                  ),
                  const SizedBox(width: 6),
                  _InfoTag(
                    icon: reviewDue
                        ? Icons.notifications_active_rounded
                        : Icons.schedule_rounded,
                    label: formatReviewStatus(item.remindAt),
                    accent: reviewDue ? const Color(0xFFFF8A47) : null,
                  ),
                ],
              ),
            ),
            if (item.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(top: 1),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
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
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final foreground = accent ?? Theme.of(context).hintColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accent != null
            ? accent!.withValues(alpha: 0.12)
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
