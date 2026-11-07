import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/status_style.dart';
import '../core/utils/date_format.dart';
import '../models/status_change.dart';

/// Vertical timeline of every status change on an incident, including the
/// staff member's note, so reporters understand what happened and why.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.history});

  final List<StatusChange> history;

  @override
  Widget build(BuildContext context) {
    final entries = [...history]
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _TimelineEntry(
            change: entries[i],
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.change, required this.isLast});

  final StatusChange change;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = change.status;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isLast ? status.color : status.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status.icon,
                  size: 16,
                  color: isLast ? Colors.white : status.color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isLast ? status.color : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shortDateTime(change.changedAt)} · ${change.changedByName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (change.note != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        change.note!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
