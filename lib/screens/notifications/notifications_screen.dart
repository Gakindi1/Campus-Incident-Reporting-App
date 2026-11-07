import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/status_style.dart';
import '../../core/utils/date_format.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../details/incident_details_screen.dart';

/// Feed of staff actions on the user's reports, derived from each report's
/// status history, so no separate notifications collection is needed.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final updates = context.watch<IncidentProvider>().updatesForMe;
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Updates',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Progress on the issues you reported.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: updates.isEmpty
                ? const SingleChildScrollView(
                    child: EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No updates yet',
                      message:
                          'When staff review or resolve your reports, you '
                          'will see it here.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: updates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final update = updates[index];
                      final status = update.change.status;
                      return Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IncidentDetailsScreen(
                                incidentId: update.incident.id,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: status.background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    status.icon,
                                    color: status.color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: update.incident.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const TextSpan(text: ' is now '),
                                            TextSpan(
                                              text: status.label,
                                              style: TextStyle(
                                                color: status.color,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (update.change.note != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          '“${update.change.note}”',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        '${update.change.changedByName} · '
                                        '${timeAgo(update.change.changedAt)}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
