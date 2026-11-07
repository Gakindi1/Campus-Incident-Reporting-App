import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_enums.dart';

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
