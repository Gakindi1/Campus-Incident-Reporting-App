import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_enums.dart';
import 'status_change.dart';

class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.location,
    required this.reporterId,
    required this.reporterName,
    required this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
    this.locationDetail = '',
    this.imageUrl,
    this.imagePath,
    this.statusHistory = const [],
    this.supporters = const [],
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final IncidentStatus status;
  final IncidentPriority priority;
  final String location;
  final String locationDetail;
  final String? imageUrl;

  final String? imagePath;
  final String reporterId;
  final String reporterName;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusChange> statusHistory;

  final List<String> supporters;

  String get fullLocation =>
      locationDetail.isEmpty ? location : '$location — $locationDetail';

  bool isReportedBy(String uid) => reporterId == uid;

  bool isSupportedBy(String uid) => supporters.contains(uid);

  bool get isEditableByReporter => status == IncidentStatus.submitted;

  String get publicReporterName =>
      isAnonymous ? 'Anonymous student' : reporterName;

  factory Incident.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Incident.fromMap(doc.id, doc.data() ?? const {});

  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = _toDate(map['createdAt']);
    return Incident(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: IncidentCategory.fromName(map['category'] as String?),
      status: IncidentStatus.fromName(map['status'] as String?),
      priority: IncidentPriority.fromName(map['priority'] as String?),
      location: map['location'] as String? ?? '',
      locationDetail: map['locationDetail'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      imagePath: map['imagePath'] as String?,
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: map['updatedAt'] == null
          ? createdAt
          : _toDate(map['updatedAt']),
      statusHistory: (map['statusHistory'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatusChange.fromMap)
          .toList(),
      supporters: List<String>.from(map['supporters'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'title': title,
    'description': description,
    'category': category.name,
    'status': status.name,
    'priority': priority.name,
    'location': location,
    'locationDetail': locationDetail,
    'imageUrl': imageUrl,
    'imagePath': imagePath,
    'reporterId': reporterId,
    'reporterName': reporterName,
    'isAnonymous': isAnonymous,
    'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
    'supporters': supporters,
  };

  Incident copyWith({
    String? title,
    String? description,
    IncidentCategory? category,
    IncidentStatus? status,
    IncidentPriority? priority,
    String? location,
    String? locationDetail,
    String? imageUrl,
    String? imagePath,
    String? reporterName,
    bool? isAnonymous,
    List<StatusChange>? statusHistory,
    List<String>? supporters,
  }) {
    return Incident(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      locationDetail: locationDetail ?? this.locationDetail,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      reporterId: reporterId,
      reporterName: reporterName ?? this.reporterName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt,
      updatedAt: updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
      supporters: supporters ?? this.supporters,
    );
  }
}

DateTime _toDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}
