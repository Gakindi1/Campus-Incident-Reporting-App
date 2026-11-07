import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../models/incident_enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_card.dart';
import '../../widgets/summary_stat_card.dart';
import '../details/incident_details_screen.dart';

typedef OpenReports = void Function({
  IncidentStatus? status,
  ReportScope? scope,
});

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenReports,
    required this.onReport,
    required this.onOpenNotifications,
  });

  final OpenReports onOpenReports;
  final VoidCallback onReport;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().profile!;
    final incidents = context.watch<IncidentProvider>();
    final summary = incidents.summary;
    final list = user.isStaff
        ? incidents.staffQueue.take(5).toList()
        : incidents.recentForHome;
    final scope = user.isStaff ? ReportScope.all : ReportScope.mine;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => Future.delayed(const Duration(milliseconds: 600)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _Greeting(
              user: user,
              hasNewUpdates: incidents.updatesForMe.any(
                (u) =>
                    DateTime.now().difference(u.change.changedAt).inHours < 48,
              ),
              onOpenNotifications: onOpenNotifications,
            ),
            const SizedBox(height: 20),
            user.isStaff
                ? _StaffHeroCard(
                    openCount: incidents.staffQueue.length,
                    urgentCount: incidents.staffQueue
                        .where((i) => i.priority == IncidentPriority.high)
                        .length,
                    onOpenQueue: () => onOpenReports(scope: ReportScope.all),
                  )
                : _ReportHeroCard(onReport: onReport),
            const SizedBox(height: 24),
            SectionHeader(
              title: user.isStaff ? 'Campus Overview' : 'Report Summary',
              actionLabel: 'See all',
              onAction: () => onOpenReports(scope: scope),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SummaryStatCard(
                    label: user.isStaff ? 'Total' : 'My Reports',
                    value: summary.total,
                    icon: Icons.description_rounded,
                    color: AppColors.primary,
                    onTap: () => onOpenReports(scope: scope),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SummaryStatCard(
                    label: 'Submitted',
                    value: summary.submitted,
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.submitted,
                    onTap: () => onOpenReports(
                      scope: scope,
                      status: IncidentStatus.submitted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SummaryStatCard(
                    label: 'In Progress',
                    value: summary.inProgress,
                    icon: Icons.construction_rounded,
                    color: AppColors.progress,
                    onTap: () => onOpenReports(
                      scope: scope,
                      status: IncidentStatus.inProgress,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SummaryStatCard(
                    label: 'Resolved',
                    value: summary.resolved,
                    icon: Icons.check_circle_rounded,
                    color: AppColors.resolved,
                    onTap: () => onOpenReports(
                      scope: scope,
                      status: IncidentStatus.resolved,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(
              title: user.isStaff ? 'Needs Attention' : 'Recent Reports',
              actionLabel: 'See all',
              onAction: () => onOpenReports(scope: scope),
            ),
            const SizedBox(height: 8),
            if (incidents.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (incidents.error != null)
              EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Something went wrong',
                message: incidents.error!,
              )
            else if (list.isEmpty)
              EmptyState(
                icon: user.isStaff
                    ? Icons.celebration_rounded
                    : Icons.campaign_outlined,
                title: user.isStaff ? 'All caught up!' : 'No reports yet',
                message: user.isStaff ? 'There are no open reports right now.' : 'When you report an issue, you can follow its progress here.',
              )
            else
              ...list.map(
                (incident) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IncidentCard(
                    incident: incident,
                    showPriority: user.isStaff,
                    onTap: () => _openDetails(context, incident),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, Incident incident) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentDetailsScreen(incidentId: incident.id),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.user,
    required this.hasNewUpdates,
    required this.onOpenNotifications,
  });

  final AppUser user;
  final bool hasNewUpdates;
  final VoidCallback onOpenNotifications;

  String get _timeOfDay {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_timeOfDay,',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                user.firstName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.isStaff
                    ? 'Here is what needs your attention today.'
                    : 'Help make our campus safer and better.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
          child: IconButton(
            tooltip: 'Updates',
            onPressed: onOpenNotifications,
            icon: Badge(
              isLabelVisible: hasNewUpdates,
              backgroundColor: AppColors.accent,
              smallSize: 8,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InitialsAvatar(initials: user.initials, isStaff: user.isStaff),
      ],
    );
  }
}

class _ReportHeroCard extends StatelessWidget {
  const _ReportHeroCard({required this.onReport});

  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _HeroContainer(
      decoration: Icons.domain_rounded,
      children: [
        Text(
          'Spotted an issue\non campus?',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Report it in under a minute and follow\nit until it is fixed.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 18),
        _HeroButton(
          icon: Icons.add_rounded,
          label: 'Report an Issue',
          onTap: onReport,
        ),
      ],
    );
  }
}

class _StaffHeroCard extends StatelessWidget {
  const _StaffHeroCard({
    required this.openCount,
    required this.urgentCount,
    required this.onOpenQueue,
  });

  final int openCount;
  final int urgentCount;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _HeroContainer(
      decoration: Icons.admin_panel_settings_rounded,
      children: [
        const RoleBadge(label: 'STAFF CONSOLE', isStaff: true),
        const SizedBox(height: 10),
        Text(
          '$openCount open report${openCount == 1 ? '' : 's'}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          urgentCount > 0
              ? '$urgentCount marked urgent by students'
              : 'No urgent reports right now',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 18),
        _HeroButton(
          icon: Icons.fact_check_rounded,
          label: 'Open Triage Queue',
          onTap: onOpenQueue,
        ),
      ],
    );
  }
}

class _HeroContainer extends StatelessWidget {
  const _HeroContainer({required this.children, required this.decoration});

  final List<Widget> children;
  final IconData decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: _Circle(size: 140, opacity: 0.08),
          ),
          Positioned(
            right: 40,
            bottom: -50,
            child: _Circle(size: 110, opacity: 0.06),
          ),
          Positioned(
            right: 18,
            top: 22,
            child: Icon(
              decoration,
              size: 72,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.midnight,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.midnight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
