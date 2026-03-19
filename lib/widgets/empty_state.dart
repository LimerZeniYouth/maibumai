import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.18),
                    const Color(0xFF8BD9FF).withValues(alpha: 0.12),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 18),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                      height: 1.45,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
