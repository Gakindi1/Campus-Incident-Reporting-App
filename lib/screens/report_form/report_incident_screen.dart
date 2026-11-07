import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/status_style.dart';
import '../../core/utils/feedback.dart';
import '../../core/utils/validators.dart';
import '../../models/incident.dart';
import '../../models/incident_enums.dart';
import '../../providers/incident_provider.dart';
import '../../providers/report_form_controller.dart';
import '../../widgets/category_selector.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_image.dart';
import '../details/incident_details_screen.dart';

class ReportIncidentScreen extends StatelessWidget {
  const ReportIncidentScreen({super.key, this.existing});

  final Incident? existing;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportFormController(initial: existing),
      child: const _ReportForm(),
    );
  }
}

class _ReportForm extends StatefulWidget {
  const _ReportForm();

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationDetailController;

  @override
  void initState() {
    super.initState();
    final initial = context.read<ReportFormController>().initial;
    _titleController = TextEditingController(text: initial?.title);
    _descriptionController = TextEditingController(text: initial?.description);
    _locationDetailController = TextEditingController(
      text: initial?.locationDetail,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationDetailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final form = context.read<ReportFormController>();
    final selectionsValid = form.validateSelections();
    final fieldsValid = _formKey.currentState!.validate();
    if (!selectionsValid || !fieldsValid) {
      showError(context, StateError('Please fix the highlighted fields.'));
      return;
    }

    final incidents = context.read<IncidentProvider>();
    final navigator = Navigator.of(context);
    form.setSubmitting(true);
    try {
      if (form.isEditing) {
        await incidents.updateReport(
          form.initial!,
          title: _titleController.text,
          description: _descriptionController.text,
          category: form.category!,
          priority: form.priority,
          location: form.location!,
          locationDetail: _locationDetailController.text,
          isAnonymous: form.isAnonymous,
          photo: form.photo,
          removePhoto: form.removedExistingPhoto,
        );
        if (!mounted) return;
        showSuccess(context, 'Report updated.');
        navigator.pop();
      } else {
        await incidents.submitReport(
          title: _titleController.text,
          description: _descriptionController.text,
          category: form.category!,
          priority: form.priority,
          location: form.location!,
          locationDetail: _locationDetailController.text,
          isAnonymous: form.isAnonymous,
          photo: form.photo,
        );
        if (!mounted) return;
        navigator.pop();
        await _showSubmittedDialog(navigator.context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) form.setSubmitting(false);
    }
  }

  Future<void> _showSubmittedDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.resolvedBg,
          child: Icon(Icons.check_rounded, color: AppColors.resolved, size: 36),
        ),
        title: const Text('Report submitted'),
        content: const Text(
          'Thank you for helping improve our campus. Campus staff have been '
          'notified, and you can track progress under Reports.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _choosePhotoSource() async {
    final form = context.read<ReportFormController>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      await form.pickPhoto(source);
    } catch (e) {
      if (mounted) {
        showError(context, StateError('Could not access photos: $e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ReportFormController>();
    return PopScope(
      canPop: !form.isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: Text(form.isEditing ? 'Edit Report' : 'Report an Incident'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: form.isSubmitting ? null : () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              LabeledField(
                label: 'Select a category',
                child: CategorySelector(
                  selected: form.category,
                  hasError: form.showCategoryError,
                  onSelected: form.selectCategory,
                ),
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: 'Title',
                child: TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  validator: Validators.incidentTitle,
                  decoration: const InputDecoration(
                    hintText: 'e.g. No water in Block B washrooms',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: 18),
              LabeledField(
                label: 'Description',
                child: TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 1000,
                  validator: Validators.incidentDescription,
                  decoration: const InputDecoration(
                    hintText: 'What happened, since when, and who is affected?',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              LabeledField(
                label: 'Location',
                child: DropdownButtonFormField<String>(
                  initialValue: form.location,
                  isExpanded: true,
                  validator: (v) => Validators.requiredField(v, 'Location'),
                  decoration: const InputDecoration(
                    hintText: 'Where on campus?',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  items: [
                    for (final location in kCampusLocations)
                      DropdownMenuItem(value: location, child: Text(location)),
                  ],
                  onChanged: form.selectLocation,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _locationDetailController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 60,
                decoration: const InputDecoration(
                  hintText: 'Room, floor or landmark (optional)',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                  counterText: '',
                ),
              ),
              const _DuplicateWarning(),
              const SizedBox(height: 18),
              LabeledField(
                label: 'How urgent is it?',
                child: SegmentedButton<IncidentPriority>(
                  showSelectedIcon: false,
                  segments: [
                    for (final p in IncidentPriority.values)
                      ButtonSegment(
                        value: p,
                        label: Text(p.label),
                        icon: Icon(Icons.flag_rounded, color: p.color),
                      ),
                  ],
                  selected: {form.priority},
                  onSelectionChanged: (s) => form.selectPriority(s.first),
                ),
              ),
              const SizedBox(height: 20),
              LabeledField(
                label: 'Add a photo',
                optional: true,
                child: _PhotoPicker(onPick: _choosePhotoSource),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  value: form.isAnonymous,
                  onChanged: form.setAnonymous,
                  title: const Text(
                    'Report anonymously',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Your name is hidden from everyone, including other '
                    'students. You can still track this report.',
                    style: TextStyle(fontSize: 12),
                  ),
                  secondary: const Icon(Icons.visibility_off_outlined),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: form.isEditing ? 'Save Changes' : 'Submit Report',
                icon: Icons.send_rounded,
                isLoading: form.isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DuplicateWarning extends StatelessWidget {
  const _DuplicateWarning();

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ReportFormController>();
    if (form.isEditing || form.category == null || form.location == null) {
      return const SizedBox.shrink();
    }
    final duplicates = context.select<IncidentProvider, List<Incident>>(
      (p) => p.possibleDuplicates(form.category!, form.location!),
    );
    if (duplicates.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.submittedBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.submitted.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.submitted,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Already reported?',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Similar open reports exist here. Tap one to add "Me too" '
            'instead of creating a duplicate.',
            style: TextStyle(fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          for (final incident in duplicates)
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      IncidentDetailsScreen(incidentId: incident.id),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      incident.status.icon,
                      size: 16,
                      color: incident.status.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        incident.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ReportFormController>();

    if (!form.hasPhoto) {
      return InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
              width: 1.4,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.primary,
                size: 30,
              ),
              SizedBox(height: 8),
              Text(
                'Tap to take or choose a photo',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Photos help staff fix issues faster',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: form.photo != null
              ? Image.file(
                  form.photo!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : IncidentImage(
                  imageUrl: form.existingImageUrl,
                  category: form.category ?? IncidentCategory.other,
                  height: 200,
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _PhotoAction(
                icon: Icons.swap_horiz_rounded,
                tooltip: 'Replace photo',
                onTap: onPick,
              ),
              const SizedBox(width: 8),
              _PhotoAction(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Remove photo',
                onTap: form.removePhoto,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }
}
