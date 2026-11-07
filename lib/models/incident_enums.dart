import 'package:flutter/material.dart';

/// The type of problem being reported. Categories map to the campus team
/// that would typically handle the issue.
enum IncidentCategory {
  facilities('Facilities', Icons.apartment_rounded),
  water('Water', Icons.water_drop_rounded),
  electricity('Electricity', Icons.bolt_rounded),
  safety('Safety', Icons.shield_rounded),
  sanitation('Sanitation', Icons.cleaning_services_rounded),
  internet('Wi-Fi & IT', Icons.wifi_rounded),
  furniture('Furniture', Icons.chair_rounded),
  other('Other', Icons.more_horiz_rounded);

  const IncidentCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static IncidentCategory fromName(String? name) => IncidentCategory.values
      .firstWhere((c) => c.name == name, orElse: () => IncidentCategory.other);
}

/// Lifecycle of an incident from the moment a student submits it until staff
/// close it. Staff may only move an incident along [nextOptions], which keeps
/// the workflow predictable and the timeline meaningful.
enum IncidentStatus {
  submitted('Submitted', Icons.send_rounded),
  underReview('Under Review', Icons.manage_search_rounded),
  inProgress('In Progress', Icons.construction_rounded),
  resolved('Resolved', Icons.check_circle_rounded),
  rejected('Rejected', Icons.block_rounded);

  const IncidentStatus(this.label, this.icon);

  final String label;
  final IconData icon;

  static IncidentStatus fromName(String? name) => IncidentStatus.values
      .firstWhere((s) => s.name == name, orElse: () => IncidentStatus.submitted);

  /// Whether the incident is still waiting for (or receiving) attention.
  bool get isOpen => this != resolved && this != rejected;

  /// Statuses a staff member may move this incident to.
  List<IncidentStatus> get nextOptions => switch (this) {
    submitted => [underReview, inProgress, rejected],
    underReview => [inProgress, resolved, rejected],
    inProgress => [resolved, underReview],
    resolved => [inProgress],
    rejected => [underReview],
  };

  /// Closing or rejecting a report must be explained to the reporter.
  bool get requiresNote => this == resolved || this == rejected;
}

/// How urgently the reporter believes the issue needs attention.
enum IncidentPriority {
  low('Low'),
  medium('Medium'),
  high('Urgent');

  const IncidentPriority(this.label);

  final String label;

  static IncidentPriority fromName(String? name) => IncidentPriority.values
      .firstWhere((p) => p.name == name, orElse: () => IncidentPriority.medium);
}

/// Common reporting locations on campus, so reports are consistent and easy
/// for facilities staff to route. A free-text detail field captures specifics.
const List<String> kCampusLocations = [
  'Block A',
  'Block B',
  'Block C',
  'Library',
  'Cafeteria',
  'Student Residence',
  'Admin Block',
  'Sports Ground',
  'Parking Area',
  'Main Gate',
  'Other',
];
