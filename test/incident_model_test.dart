import 'package:campus_fix/models/incident.dart';
import 'package:campus_fix/models/incident_enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  test('toCreateMap and fromMap round-trip core fields', () {
    final original = makeIncident(
      id: 'abc',
      category: IncidentCategory.electricity,
      priority: IncidentPriority.high,
    );
    final map = {
      ...original.toCreateMap(),
      'createdAt': Timestamp.fromDate(original.createdAt),
    };

    final restored = Incident.fromMap('abc', map);

    expect(restored.id, 'abc');
    expect(restored.title, original.title);
    expect(restored.category, IncidentCategory.electricity);
    expect(restored.priority, IncidentPriority.high);
    expect(restored.status, IncidentStatus.submitted);
    expect(restored.createdAt, original.createdAt);
    expect(restored.statusHistory, hasLength(1));
    expect(restored.statusHistory.first.status, IncidentStatus.submitted);
  });

  test('unknown enum values fall back safely', () {
    final incident = Incident.fromMap('x', {
      'category': 'spaceship',
      'status': 'teleported',
    });
    expect(incident.category, IncidentCategory.other);
    expect(incident.status, IncidentStatus.submitted);
  });

  test('only submitted reports are editable by their reporter', () {
    expect(makeIncident(id: '1').isEditableByReporter, isTrue);
    expect(
      makeIncident(
        id: '2',
        status: IncidentStatus.inProgress,
      ).isEditableByReporter,
      isFalse,
    );
  });

  test('status workflow only allows sensible transitions', () {
    expect(
      IncidentStatus.submitted.nextOptions,
      isNot(contains(IncidentStatus.resolved)),
    );
    expect(
      IncidentStatus.inProgress.nextOptions,
      contains(IncidentStatus.resolved),
    );
    expect(IncidentStatus.resolved.requiresNote, isTrue);
    expect(IncidentStatus.inProgress.requiresNote, isFalse);
  });
}
