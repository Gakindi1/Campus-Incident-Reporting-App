import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/status_style.dart';
import '../../models/incident_enums.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_card.dart';
import '../details/incident_details_screen.dart';

/// Browse, search and filter reports. All filter state lives in
/// [IncidentProvider] so it survives tab switches and can be preset from the
/// dashboard.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<IncidentProvider>();
    final isStaff = incidents.user?.isStaff ?? false;
    final results = incidents.filteredIncidents;

    // Keep the text box in sync when filters are cleared elsewhere.
    if (_searchController.text != incidents.query) {
      _searchController.text = incidents.query;
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Text(
              isStaff ? 'All Reports' : 'Reports',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _ScopeToggle(
              scope: incidents.scope,
              onChanged: incidents.setScope,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: incidents.setQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search title, location, category…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: incidents.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => incidents.setQuery(''),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _CategoryFilterButton(
                  selected: incidents.categoryFilter,
                  onSelected: incidents.setCategoryFilter,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterPill(
                  label: 'All',
                  selected: incidents.statusFilter == null,
                  onTap: () => incidents.setStatusFilter(null),
                ),
                for (final status in IncidentStatus.values)
                  _FilterPill(
                    label: status.label,
                    color: status.color,
                    selected: incidents.statusFilter == status,
                    onTap: () => incidents.setStatusFilter(status),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 12, 4),
            child: Row(
              children: [
                Text(
                  '${results.length} report${results.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (incidents.categoryFilter != null) ...[
                  const SizedBox(width: 8),
                  InputChip(
                    label: Text(incidents.categoryFilter!.label),
                    avatar: Icon(incidents.categoryFilter!.icon, size: 16),
                    onDeleted: () => incidents.setCategoryFilter(null),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                const Spacer(),
                if (incidents.hasActiveFilters)
                  TextButton(
                    onPressed: incidents.clearFilters,
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildResults(context, incidents)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, IncidentProvider incidents) {
    if (incidents.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (incidents.error != null) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load reports',
        message: incidents.error!,
      );
    }
    final results = incidents.filteredIncidents;
    if (results.isEmpty) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: incidents.hasActiveFilters
              ? 'No matching reports'
              : 'Nothing here yet',
          message: incidents.hasActiveFilters
              ? 'Try a different search term or remove some filters.'
              : incidents.scope == ReportScope.mine
              ? 'Reports you submit will appear here.'
              : 'No one has reported an issue yet.',
        ),
      );
    }
    final isStaff = incidents.user?.isStaff ?? false;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final incident = results[index];
        return IncidentCard(
          incident: incident,
          showPriority: isStaff,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IncidentDetailsScreen(incidentId: incident.id),
            ),
          ),
        );
      },
    );
  }
}

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.scope, required this.onChanged});

  final ReportScope scope;
  final ValueChanged<ReportScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment('My Reports', ReportScope.mine),
          _segment('Campus Feed', ReportScope.all),
        ],
      ),
    );
  }

  Widget _segment(String label, ReportScope value) {
    final selected = scope == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: color,
        backgroundColor: AppColors.surface,
        side: BorderSide(color: selected ? color : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _CategoryFilterButton extends StatelessWidget {
  const _CategoryFilterButton({
    required this.selected,
    required this.onSelected,
  });

  final IncidentCategory? selected;
  final ValueChanged<IncidentCategory?> onSelected;

  Future<void> _openSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_CategoryChoice>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All categories'),
                    selected: selected == null,
                    onSelected: (_) =>
                        Navigator.pop(context, const _CategoryChoice(null)),
                  ),
                  for (final category in IncidentCategory.values)
                    ChoiceChip(
                      avatar: Icon(category.icon, size: 18),
                      label: Text(category.label),
                      selected: selected == category,
                      onSelected: (_) =>
                          Navigator.pop(context, _CategoryChoice(category)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    // Dismissing the sheet (null result) keeps the current filter.
    if (result != null) onSelected(result.category);
  }

  @override
  Widget build(BuildContext context) {
    final active = selected != null;
    return Material(
      color: active ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: active ? AppColors.primary : AppColors.border),
      ),
      child: IconButton(
        tooltip: 'Filter by category',
        onPressed: () => _openSheet(context),
        icon: Icon(
          Icons.tune_rounded,
          color: active ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _CategoryChoice {
  const _CategoryChoice(this.category);

  final IncidentCategory? category;
}
