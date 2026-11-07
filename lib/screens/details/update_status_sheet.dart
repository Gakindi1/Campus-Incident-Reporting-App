import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/status_style.dart';
import '../../core/utils/feedback.dart';
import '../../models/incident.dart';
import '../../models/incident_enums.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';

Future<void> showUpdateStatusSheet(BuildContext context, Incident incident) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _UpdateStatusSheet(incident: incident),
  );
}

class _UpdateStatusSheet extends StatefulWidget {
  const _UpdateStatusSheet({required this.incident});

  final Incident incident;

  @override
  State<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<_UpdateStatusSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  IncidentStatus? _selected;
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null) {
      showError(context, StateError('Choose a new status.'));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<IncidentProvider>().updateStatus(
        widget.incident,
        _selected!,
        note: _noteController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      showSuccess(context, 'Status updated to ${_selected!.label}.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = widget.incident.status.nextOptions;
    final noteRequired = _selected?.requiresNote ?? false;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Update status',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Currently ${widget.incident.status.label}. The reporter will '
              'see this change and your note in their timeline.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            for (final status in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _StatusOption(
                  status: status,
                  selected: _selected == status,
                  onTap: () => setState(() => _selected = status),
                ),
              ),
            const SizedBox(height: 8),
            LabeledField(
              label: 'Note to reporter',
              optional: !noteRequired,
              child: TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) =>
                    noteRequired && (value == null || value.trim().isEmpty)
                    ? 'Explain the outcome to the reporter'
                    : null,
                decoration: InputDecoration(
                  hintText: noteRequired
                      ? 'e.g. Plumber replaced the faulty valve.'
                      : 'e.g. Technician assigned, visiting tomorrow.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Save Update',
              icon: Icons.check_rounded,
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  const _StatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final IncidentStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? status.background : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? status.color : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(status.icon, color: status.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  status.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? status.color : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
