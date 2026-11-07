import 'dart:async';
import 'dart:io';

import 'package:campus_fix/models/app_user.dart';
import 'package:campus_fix/models/incident.dart';
import 'package:campus_fix/models/incident_enums.dart';
import 'package:campus_fix/models/status_change.dart';
import 'package:campus_fix/services/incident_repository.dart';
import 'package:campus_fix/services/storage_service.dart';

/// In-memory repository that behaves like Firestore's live stream.
class FakeIncidentRepository implements IncidentRepository {
  final _controller = StreamController<List<Incident>>.broadcast();
  final Map<String, Incident> _store = {};
  int _nextId = 0;
  bool failNextCreate = false;

  void seed(List<Incident> incidents) {
    for (final i in incidents) {
      _store[i.id] = i;
    }
    _emit();
  }

  Incident? byId(String id) => _store[id];

  void _emit() {
    final list = _store.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(list);
  }

  @override
  Stream<List<Incident>> watchIncidents() {
    scheduleMicrotask(_emit);
    return _controller.stream;
  }

  @override
  String newIncidentId() => 'new-${_nextId++}';

  @override
  Future<void> createIncident(Incident incident) async {
    if (failNextCreate) {
      failNextCreate = false;
      throw Exception('network down');
    }
    _store[incident.id] = incident;
    _emit();
  }

  @override
  Future<void> updateIncidentDetails(Incident incident) async {
    _store[incident.id] = incident;
    _emit();
  }

  @override
  Future<void> addStatusChange(String incidentId, StatusChange change) async {
    final current = _store[incidentId]!;
    _store[incidentId] = current.copyWith(
      status: change.status,
      statusHistory: [...current.statusHistory, change],
    );
    _emit();
  }

  @override
  Future<void> setSupport(
    String incidentId,
    String uid, {
    required bool support,
  }) async {
    final current = _store[incidentId]!;
    final supporters = {...current.supporters};
    support ? supporters.add(uid) : supporters.remove(uid);
    _store[incidentId] = current.copyWith(supporters: supporters.toList());
    _emit();
  }

  @override
  Future<void> deleteIncident(String incidentId) async {
    _store.remove(incidentId);
    _emit();
  }
}

class FakeStorageService implements StorageService {
  final List<String> uploaded = [];
  final List<String> deleted = [];

  @override
  Future<({String path, String url})> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    final path = 'incidents/$uid/$incidentId/photo.jpg';
    uploaded.add(path);
    return (path: path, url: 'https://example.com/$path');
  }

  @override
  Future<void> deleteFile(String path) async => deleted.add(path);
}

final student = AppUser(
  uid: 'student-1',
  fullName: 'Amina Hassan',
  email: 'a.hassan@alustudent.com',
  role: UserRole.student,
  createdAt: DateTime(2026, 1, 1),
);

final otherStudent = AppUser(
  uid: 'student-2',
  fullName: 'Kofi Mensah',
  email: 'k.mensah@alustudent.com',
  role: UserRole.student,
  createdAt: DateTime(2026, 1, 1),
);

final staff = AppUser(
  uid: 'staff-1',
  fullName: 'Grace Uwase',
  email: 'g.uwase@alueducation.com',
  role: UserRole.staff,
  createdAt: DateTime(2026, 1, 1),
);

Incident makeIncident({
  required String id,
  String title = 'Water shortage',
  String reporterId = 'student-1',
  IncidentStatus status = IncidentStatus.submitted,
  IncidentCategory category = IncidentCategory.water,
  IncidentPriority priority = IncidentPriority.medium,
  String location = 'Student Residence',
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime(2026, 10, 15, 10, 24);
  return Incident(
    id: id,
    title: title,
    description: 'There has been no water since this morning.',
    category: category,
    status: status,
    priority: priority,
    location: location,
    reporterId: reporterId,
    reporterName: 'Someone',
    isAnonymous: false,
    createdAt: created,
    updatedAt: created,
    statusHistory: [
      StatusChange(
        status: IncidentStatus.submitted,
        changedAt: created,
        changedById: reporterId,
        changedByName: 'Someone',
      ),
    ],
  );
}
