import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/feedback.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/summary_stat_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out?',
      message: 'You will need your ALU email and password to sign in again.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    await context.read<AuthProvider>().signOut();
  }

  void _showGuidelines(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reporting guidelines'),
        content: const SingleChildScrollView(
          child: Text(
            '• Report real issues you have seen on campus.\n'
            '• Check for an existing report first and tap "Me too" instead '
            'of filing a duplicate.\n'
            '• Do not include other people\'s faces or personal details in '
            'photos or descriptions.\n'
            '• For emergencies (fire, medical, violence), call campus '
            'security immediately; this app is not monitored 24/7.\n'
            '• Anonymous reports hide your name from everyone, but abuse of '
            'the system can still be traced to your account by '
            'administrators.\n'
            '• Staff may remove spam, abusive or duplicate reports.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().profile!;
    final summary = context.watch<IncidentProvider>().mySummary;
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Text(
            'Profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                InitialsAvatar(
                  initials: user.initials,
                  radius: 32,
                  isStaff: user.isStaff,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          RoleBadge(
                            label: user.role.label,
                            isStaff: user.isStaff,
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.resolved,
                          ),
                          const SizedBox(width: 3),
                          const Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.resolved,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'My Activity'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SummaryStatCard(
                  label: 'Total Reports',
                  value: summary.total,
                  icon: Icons.description_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryStatCard(
                  label: 'In Progress',
                  value: summary.inProgress,
                  icon: Icons.construction_rounded,
                  color: AppColors.progress,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryStatCard(
                  label: 'Resolved',
                  value: summary.resolved,
                  icon: Icons.check_circle_rounded,
                  color: AppColors.resolved,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Account'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Account type'),
                  subtitle: Text(
                    user.isStaff
                        ? 'Campus staff: can review and update reports'
                        : 'Student: can submit and track reports',
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Member since'),
                  subtitle: Text(fullDateTime(user.createdAt)),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.rule_rounded),
                  title: const Text('Reporting guidelines'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showGuidelines(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.rejected,
                  ),
                  title: const Text(
                    'Sign out',
                    style: TextStyle(color: AppColors.rejected),
                  ),
                  onTap: () => _signOut(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'CampusFix v1.0.0',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
