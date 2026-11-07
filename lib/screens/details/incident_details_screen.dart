import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/status_style.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/feedback.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_image.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/status_timeline.dart';
import '../report_form/report_incident_screen.dart';
import 'update_status_sheet.dart';

class IncidentDetailsScreen extends StatelessWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final incident = provider.incidentById(incidentId);
    final user = provider.user;

    if (incident == null || user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident Details')),
        body: const Center(
          child: EmptyState(
            icon: Icons.delete_sweep_outlined,
            title: 'Report unavailable',
            message: 'This report was withdrawn or removed.',
          ),
        ),
      );
    }

    final isMine = incident.isReportedBy(user.uid);
    final canEdit = provider.canEdit(incident);
    final canDelete = provider.canDelete(incident);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (canEdit || canDelete)
            PopupMenuButton<_MenuAction>(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) => switch (action) {
                _MenuAction.edit => Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => ReportIncidentScreen(existing: incident),
                  ),
                ),
                _MenuAction.delete => _delete(context, incident, isMine),
              },
              itemBuilder: (_) => [
                if (canEdit)
                  const PopupMenuItem(
                    value: _MenuAction.edit,
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit report'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (canDelete)
                  PopupMenuItem(
                    value: _MenuAction.delete,
                    child: ListTile(
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.rejected,
                      ),
                      title: Text(
                        isMine ? 'Withdraw report' : 'Remove report',
                        style: const TextStyle(color: AppColors.rejected),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          _HeaderCard(incident: incident, isMine: isMine),
          const SizedBox(height: 12),
          _SupportBar(incident: incident, isMine: isMine, uid: user.uid),
          if (isMine && canEdit) ...[
            const SizedBox(height: 12),
            const _InfoBanner(
              text:
                  'You can edit or withdraw this report until staff start '
                  'reviewing it.',
            ),
          ],
          const SizedBox(height: 24),
          const _SectionTitle('Status Timeline'),
          const SizedBox(height: 12),
          _Card(child: StatusTimeline(history: incident.statusHistory)),
          const SizedBox(height: 24),
          const _SectionTitle('Description'),
          const SizedBox(height: 12),
          _Card(
            child: Text(
              incident.description,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(height: 1.5),
            ),
          ),
          if (incident.imageUrl != null) ...[
            const SizedBox(height: 24),
            const _SectionTitle('Attached Photo'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openPhoto(context, incident),
              child: IncidentImage(
                imageUrl: incident.imageUrl,
                category: incident.category,
                height: 220,
                borderRadius: 18,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: user.isStaff
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: PrimaryButton(
                  label: 'Update Status',
                  icon: Icons.published_with_changes_rounded,
                  onPressed: () => showUpdateStatusSheet(context, incident),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _delete(
    BuildContext context,
    Incident incident,
    bool isMine,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: isMine ? 'Withdraw this report?' : 'Remove this report?',
      message: isMine
          ? 'The report and its photo will be permanently deleted.'
          : 'Use this for spam, abusive or duplicate reports. This cannot '
                'be undone.',
      confirmLabel: isMine ? 'Withdraw' : 'Remove',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<IncidentProvider>().deleteReport(incident);
      if (!context.mounted) return;
      Navigator.pop(context);
      showSuccess(context, 'Report deleted.');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  void _openPhoto(BuildContext context, Incident incident) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: IncidentImage(
                imageUrl: incident.imageUrl,
                category: incident.category,
                borderRadius: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _MenuAction { edit, delete }

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.incident, required this.isMine});

  final Incident incident;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IncidentImage(
                imageUrl: incident.imageUrl,
                category: incident.category,
                size: 76,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(incident.fullLocation, style: muted),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(status: incident.status),
                        PriorityBadge(priority: incident.priority),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _MetaRow(
            icon: incident.category.icon,
            iconColor: incident.category.color,
            text: incident.category.label,
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            text: 'Submitted ${fullDateTime(incident.createdAt)}',
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: incident.isAnonymous
                ? Icons.visibility_off_outlined
                : Icons.person_outline_rounded,
            text: isMine
                ? 'Reported by you${incident.isAnonymous ? ' (anonymous)' : ''}'
                : 'Reported by ${incident.publicReporterName}',
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, this.iconColor});

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _SupportBar extends StatelessWidget {
  const _SupportBar({
    required this.incident,
    required this.isMine,
    required this.uid,
  });

  final Incident incident;
  final bool isMine;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final count = incident.supporters.length;
    final supported = incident.isSupportedBy(uid);
    final label = count == 0
        ? 'No one else has confirmed this yet'
        : '$count other${count == 1 ? '' : 's'} affected';

    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.groups_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (!isMine && incident.status.isOpen)
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                backgroundColor: supported
                    ? AppColors.primary
                    : AppColors.primaryLight,
                foregroundColor: supported ? Colors.white : AppColors.primary,
              ),
              onPressed: () async {
                try {
                  await context.read<IncidentProvider>().toggleSupport(
                    incident,
                  );
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
              icon: Icon(
                supported ? Icons.check_rounded : Icons.add_rounded,
                size: 18,
              ),
              label: Text(supported ? 'Affected' : 'Me too'),
            ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
