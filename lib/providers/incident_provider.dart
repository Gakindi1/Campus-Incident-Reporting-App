import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_enums.dart';
import '../models/status_change.dart';
import '../services/incident_repository.dart';
import '../services/storage_service.dart';

enum ReportScope { mine, all }

class IncidentSummary {
  const IncidentSummary({
    required this.total,
    required this.submitted,
    required this.inProgress,
    required this.resolved,
  });

  final int total;

  final int submitted;
  final int inProgress;
  final int resolved;

  factory IncidentSummary.of(Iterable<Incident> incidents) {
    var submitted = 0, inProgress = 0, resolved = 0, total = 0;
    for (final i in incidents) {
      total++;
      switch (i.status) {
        case IncidentStatus.submitted:
          submitted++;
        case IncidentStatus.inProgress:
          inProgress++;
        case IncidentStatus.resolved:
          resolved++;
        case IncidentStatus.underReview:
        case IncidentStatus.rejected:
          break;
      }
    }
    return IncidentSummary(
      total: total,
      submitted: submitted,
      inProgress: inProgress,
      resolved: resolved,
    );
  }
}

class IncidentUpdate {
  const IncidentUpdate(this.incident, this.change);

  final Incident incident;
  final StatusChange change;
}

class IncidentProvider extends ChangeNotifier {
  IncidentProvider({required this._repository, required this._storage});

  final IncidentRepository _repository;
  final StorageService _storage;
  StreamSubscription<List<Incident>>? _sub;

  AppUser? _user;
  List<Incident> _incidents = const [];
  bool _isLoading = false;
  String? _error;

  String _query = '';
  IncidentStatus? _statusFilter;
  IncidentCategory? _categoryFilter;
  ReportScope _scope = ReportScope.mine;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Incident> get allIncidents => _incidents;
  String get query => _query;
  IncidentStatus? get statusFilter => _statusFilter;
  IncidentCategory? get categoryFilter => _categoryFilter;
  ReportScope get scope => _scope;

  bool get hasActiveFilters =>
      _query.isNotEmpty || _statusFilter != null || _categoryFilter != null;

  void bindUser(AppUser? user) {
    final changedAccount = user?.uid != _user?.uid;
    final roleChanged = user?.role != _user?.role;
    _user = user;
    if (roleChanged && user != null) {
      _scope = user.isStaff ? ReportScope.all : ReportScope.mine;
    }
    if (!changedAccount) return;

    _sub?.cancel();
    _sub = null;
    _incidents = const [];
    _error = null;
    _clearFiltersSilently();
    if (user == null) return;

    _isLoading = true;
    _sub = _repository.watchIncidents().listen(
      (incidents) {
        _incidents = incidents;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _isLoading = false;
        _error = 'Could not load reports. Check your connection.';
        debugPrint('Incident stream error: $e');
        notifyListeners();
      },
    );
  }

  List<Incident> get myIncidents {
    final uid = _user?.uid;
    if (uid == null) return const [];
    return _incidents.where((i) => i.isReportedBy(uid)).toList();
  }

  IncidentSummary get summary =>
      IncidentSummary.of((_user?.isStaff ?? false) ? _incidents : myIncidents);

  IncidentSummary get mySummary => IncidentSummary.of(myIncidents);

  List<Incident> get recentForHome {
    final source = (_user?.isStaff ?? false) ? _incidents : myIncidents;
    return source.take(5).toList();
  }

  List<Incident> get staffQueue {
    final open = _incidents.where((i) => i.status.isOpen).toList()
      ..sort((a, b) {
        final byPriority = b.priority.index.compareTo(a.priority.index);
        return byPriority != 0
            ? byPriority
            : a.createdAt.compareTo(b.createdAt);
      });
    return open;
  }

  List<Incident> get filteredIncidents {
    final uid = _user?.uid;
    final q = _query.trim().toLowerCase();
    return _incidents.where((i) {
      if (_scope == ReportScope.mine && !i.isReportedBy(uid ?? '')) {
        return false;
      }
      if (_statusFilter != null && i.status != _statusFilter) return false;
      if (_categoryFilter != null && i.category != _categoryFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return i.title.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          i.fullLocation.toLowerCase().contains(q) ||
          i.category.label.toLowerCase().contains(q);
    }).toList();
  }

  Incident? incidentById(String id) {
    for (final i in _incidents) {
      if (i.id == id) return i;
    }
    return null;
  }

  List<IncidentUpdate> get updatesForMe {
    final uid = _user?.uid;
    if (uid == null) return const [];
    final updates = <IncidentUpdate>[
      for (final incident in myIncidents)
        for (final change in incident.statusHistory)
          if (change.changedById != uid) IncidentUpdate(incident, change),
    ]..sort((a, b) => b.change.changedAt.compareTo(a.change.changedAt));
    return updates;
  }

  List<Incident> possibleDuplicates(
    IncidentCategory category,
    String location,
  ) {
    return _incidents
        .where(
          (i) =>
              i.status.isOpen &&
              i.category == category &&
              i.location == location &&
              i.reporterId != _user?.uid,
        )
        .take(3)
        .toList();
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void setStatusFilter(IncidentStatus? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setCategoryFilter(IncidentCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setScope(ReportScope scope) {
    _scope = scope;
    notifyListeners();
  }

  void clearFilters() {
    _clearFiltersSilently();
    notifyListeners();
  }

  void _clearFiltersSilently() {
    _query = '';
    _statusFilter = null;
    _categoryFilter = null;
  }

  AppUser get _requireUser {
    final user = _user;
    if (user == null) throw StateError('You need to be signed in.');
    return user;
  }

  Future<void> submitReport({
    required String title,
    required String description,
    required IncidentCategory category,
    required IncidentPriority priority,
    required String location,
    required String locationDetail,
    required bool isAnonymous,
    File? photo,
  }) async {
    final user = _requireUser;
    final id = _repository.newIncidentId();
    ({String path, String url})? upload;
    if (photo != null) {
      upload = await _storage.uploadIncidentPhoto(
        uid: user.uid,
        incidentId: id,
        file: photo,
      );
    }

    final now = DateTime.now();
    final incident = Incident(
      id: id,
      title: title.trim(),
      description: description.trim(),
      category: category,
      status: IncidentStatus.submitted,
      priority: priority,
      location: location,
      locationDetail: locationDetail.trim(),
      imageUrl: upload?.url,
      imagePath: upload?.path,
      reporterId: user.uid,
      reporterName: isAnonymous ? 'Anonymous student' : user.fullName,
      isAnonymous: isAnonymous,
      createdAt: now,
      updatedAt: now,
      statusHistory: [
        StatusChange(
          status: IncidentStatus.submitted,
          changedAt: now,
          changedById: user.uid,
          changedByName: isAnonymous ? 'Anonymous student' : user.fullName,
        ),
      ],
    );

    try {
      await _repository.createIncident(incident);
    } catch (_) {
      if (upload != null) await _storage.deleteFile(upload.path);
      rethrow;
    }
  }

  Future<void> updateReport(
    Incident original, {
    required String title,
    required String description,
    required IncidentCategory category,
    required IncidentPriority priority,
    required String location,
    required String locationDetail,
    required bool isAnonymous,
    File? photo,
    bool removePhoto = false,
  }) async {
    final user = _requireUser;
    if (!original.isReportedBy(user.uid) || !original.isEditableByReporter) {
      throw StateError('This report can no longer be edited.');
    }

    String? imageUrl = original.imageUrl;
    String? imagePath = original.imagePath;
    final oldPath = original.imagePath;
    var replacedPhoto = false;

    if (photo != null) {
      final upload = await _storage.uploadIncidentPhoto(
        uid: user.uid,
        incidentId: original.id,
        file: photo,
      );
      imageUrl = upload.url;
      imagePath = upload.path;
      replacedPhoto = true;
    } else if (removePhoto) {
      imageUrl = null;
      imagePath = null;
      replacedPhoto = true;
    }

    final updated = Incident(
      id: original.id,
      title: title.trim(),
      description: description.trim(),
      category: category,
      status: original.status,
      priority: priority,
      location: location,
      locationDetail: locationDetail.trim(),
      imageUrl: imageUrl,
      imagePath: imagePath,
      reporterId: original.reporterId,
      reporterName: isAnonymous ? 'Anonymous student' : user.fullName,
      isAnonymous: isAnonymous,
      createdAt: original.createdAt,
      updatedAt: DateTime.now(),
      statusHistory: original.statusHistory,
      supporters: original.supporters,
    );
    await _repository.updateIncidentDetails(updated);

    if (replacedPhoto && oldPath != null) {
      unawaited(_storage.deleteFile(oldPath).catchError((_) {}));
    }
  }

  Future<void> updateStatus(
    Incident incident,
    IncidentStatus status, {
    String? note,
  }) async {
    final user = _requireUser;
    if (!user.isStaff) {
      throw StateError('Only campus staff can update a report status.');
    }
    if (!incident.status.nextOptions.contains(status)) {
      throw StateError(
        'Cannot move from ${incident.status.label} to ${status.label}.',
      );
    }
    if (status.requiresNote && (note == null || note.trim().isEmpty)) {
      throw StateError('Please add a note for the reporter.');
    }
    await _repository.addStatusChange(
      incident.id,
      StatusChange(
        status: status,
        changedAt: DateTime.now(),
        changedById: user.uid,
        changedByName: user.fullName,
        note: note?.trim(),
      ),
    );
  }

  Future<void> toggleSupport(Incident incident) {
    final user = _requireUser;
    return _repository.setSupport(
      incident.id,
      user.uid,
      support: !incident.isSupportedBy(user.uid),
    );
  }

  Future<void> deleteReport(Incident incident) async {
    final user = _requireUser;
    final canDelete =
        user.isStaff ||
        (incident.isReportedBy(user.uid) && incident.isEditableByReporter);
    if (!canDelete) throw StateError('You cannot delete this report.');

    await _repository.deleteIncident(incident.id);
    final path = incident.imagePath;
    if (path != null) {
      unawaited(_storage.deleteFile(path).catchError((_) {}));
    }
  }

  bool canEdit(Incident incident) =>
      _user != null &&
      incident.isReportedBy(_user!.uid) &&
      incident.isEditableByReporter;

  bool canDelete(Incident incident) =>
      _user != null && (_user!.isStaff || canEdit(incident));

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
