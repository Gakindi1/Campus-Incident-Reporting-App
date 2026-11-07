import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_enums.dart';

/// One entry in an incident's status timeline.
class StatusChange {
  const StatusChange({
    required this.status,
    required this.changedAt,
    required this.changedById,
    required this.changedByName,
    this.note,
  });

  final IncidentStatus status;
  final DateTime changedAt;
  final String changedById;
  final String changedByName;
  final String? note;

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    return StatusChange(
      status: IncidentStatus.fromName(map['status'] as String?),
      changedAt: _toDate(map['changedAt']),
      changedById: map['changedById'] as String? ?? '',
      changedByName: map['changedByName'] as String? ?? '',
      note: map['note'] as String?,
    );
  }

  /// Array elements cannot use server timestamps, so a client timestamp is
  /// stored here; the parent document still uses server time for ordering.
  Map<String, dynamic> toMap() => {
    'status': status.name,
    'changedAt': Timestamp.fromDate(changedAt),
    'changedById': changedById,
    'changedByName': changedByName,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}

DateTime _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}
