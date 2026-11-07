import 'dart:io';

import 'package:campus_fix/models/app_user.dart';
import 'package:campus_fix/models/incident_enums.dart';
import 'package:campus_fix/providers/incident_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeIncidentRepository repository;
  late FakeStorageService storage;
  late IncidentProvider provider;

  setUp(() {
    repository = FakeIncidentRepository();
    storage = FakeStorageService();
    provider = IncidentProvider(repository: repository, storage: storage);
    repository.seed([
      makeIncident(id: 'a', title: 'Water shortage'),
      makeIncident(
        id: 'b',
        title: 'Broken projector',
        category: IncidentCategory.facilities,
        location: 'Block B',
        status: IncidentStatus.inProgress,
        reporterId: 'student-2',
      ),
      makeIncident(
        id: 'c',
        title: 'Overflowing bin',
        category: IncidentCategory.sanitation,
        location: 'Cafeteria',
        status: IncidentStatus.resolved,
        priority: IncidentPriority.high,
      ),
    ]);
  });

  tearDown(() => provider.dispose());

  Future<void> bind(AppUser? user) async {
    provider.bindUser(user);
    await pumpEventQueue();
  }

  group('browsing and filtering', () {
    test('students default to their own reports', () async {
      await bind(student);
      expect(provider.scope, ReportScope.mine);
      expect(provider.filteredIncidents.map((i) => i.id), ['a', 'c']);
    });

    test('staff default to the campus-wide feed', () async {
      await bind(staff);
      expect(provider.scope, ReportScope.all);
      expect(provider.filteredIncidents, hasLength(3));
    });

    test('search matches title, location and category', () async {
      await bind(student);
      provider.setScope(ReportScope.all);

      provider.setQuery('projector');
      expect(provider.filteredIncidents.single.id, 'b');

      provider.setQuery('cafeteria');
      expect(provider.filteredIncidents.single.id, 'c');

      provider.setQuery('sanitation');
      expect(provider.filteredIncidents.single.id, 'c');
    });

    test('status and category filters combine', () async {
      await bind(student);
      provider.setScope(ReportScope.all);
      provider.setStatusFilter(IncidentStatus.resolved);
      expect(provider.filteredIncidents.single.id, 'c');

      provider.setCategoryFilter(IncidentCategory.water);
      expect(provider.filteredIncidents, isEmpty);

      provider.clearFilters();
      expect(provider.filteredIncidents, hasLength(3));
    });

    test('summary counts only the student\'s own reports', () async {
      await bind(student);
      final summary = provider.summary;
      expect(summary.total, 2);
      expect(summary.submitted, 1);
      expect(summary.resolved, 1);
    });

    test('staff queue lists open reports, urgent first', () async {
      repository.seed([
        makeIncident(
          id: 'urgent',
          priority: IncidentPriority.high,
          createdAt: DateTime(2026, 10, 20),
        ),
      ]);
      await bind(staff);
      final queue = provider.staffQueue.map((i) => i.id).toList();
      expect(queue.first, 'urgent');
      expect(queue, isNot(contains('c'))); // resolved is not in the queue
    });
  });

  group('commands', () {
    test('submitReport uploads the photo and creates a submitted report',
        () async {
      await bind(student);
      await provider.submitReport(
        title: 'Flickering lights',
        description: 'Lights in the library keep flickering all day.',
        category: IncidentCategory.electricity,
        priority: IncidentPriority.medium,
        location: 'Library',
        locationDetail: '2nd floor',
        isAnonymous: true,
        photo: File('photo.jpg'),
      );
      await pumpEventQueue();

      final created = repository.byId('new-0')!;
      expect(created.status, IncidentStatus.submitted);
      expect(created.reporterId, student.uid);
      expect(created.reporterName, 'Anonymous student');
      expect(created.imagePath, storage.uploaded.single);
      expect(provider.myIncidents.map((i) => i.id), contains('new-0'));
    });

    test('a failed save removes the orphaned photo', () async {
      await bind(student);
      repository.failNextCreate = true;
      await expectLater(
        provider.submitReport(
          title: 'Broken chair',
          description: 'A chair in Block A room 3 is broken.',
          category: IncidentCategory.furniture,
          priority: IncidentPriority.low,
          location: 'Block A',
          locationDetail: '',
          isAnonymous: false,
          photo: File('photo.jpg'),
        ),
        throwsException,
      );
      expect(storage.deleted, storage.uploaded);
    });

    test('students cannot update status', () async {
      await bind(student);
      final incident = provider.incidentById('a')!;
      expect(
        () => provider.updateStatus(incident, IncidentStatus.inProgress),
        throwsStateError,
      );
    });

    test('staff status updates propagate and extend the timeline', () async {
      await bind(staff);
      await provider.updateStatus(
        provider.incidentById('a')!,
        IncidentStatus.inProgress,
        note: 'Plumber assigned',
      );
      await pumpEventQueue();

      final updated = provider.incidentById('a')!;
      expect(updated.status, IncidentStatus.inProgress);
      expect(updated.statusHistory.last.note, 'Plumber assigned');
      expect(updated.statusHistory.last.changedByName, staff.fullName);
    });

    test('resolving requires a note for the reporter', () async {
      await bind(staff);
      final inProgress = provider.incidentById('b')!;
      expect(
        () => provider.updateStatus(inProgress, IncidentStatus.resolved),
        throwsStateError,
      );
    });

    test('invalid transitions are rejected', () async {
      await bind(staff);
      expect(
        () => provider.updateStatus(
          provider.incidentById('a')!,
          IncidentStatus.resolved,
          note: 'skip ahead',
        ),
        throwsStateError,
      );
    });

    test('reporters can only delete reports still awaiting review', () async {
      await bind(student);
      expect(provider.canDelete(provider.incidentById('a')!), isTrue);
      expect(provider.canDelete(provider.incidentById('c')!), isFalse);
      expect(provider.canDelete(provider.incidentById('b')!), isFalse);
    });

    test('updates feed shows staff changes on my reports', () async {
      await bind(staff);
      await provider.updateStatus(
        provider.incidentById('a')!,
        IncidentStatus.underReview,
      );
      await bind(student);

      final updates = provider.updatesForMe;
      expect(updates, hasLength(1));
      expect(updates.single.change.status, IncidentStatus.underReview);
    });

    test('"Me too" toggles support for other students', () async {
      await bind(otherStudent);
      await provider.toggleSupport(provider.incidentById('a')!);
      await pumpEventQueue();
      expect(provider.incidentById('a')!.supporters, [otherStudent.uid]);

      await provider.toggleSupport(provider.incidentById('a')!);
      await pumpEventQueue();
      expect(provider.incidentById('a')!.supporters, isEmpty);
    });
  });
}
