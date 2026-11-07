import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/incident.dart';
import '../models/status_change.dart';

abstract class IncidentRepository {
  Stream<List<Incident>> watchIncidents();

  String newIncidentId();

  Future<void> createIncident(Incident incident);

  Future<void> updateIncidentDetails(Incident incident);

  Future<void> addStatusChange(String incidentId, StatusChange change);

  Future<void> setSupport(
    String incidentId,
    String uid, {
    required bool support,
  });

  Future<void> deleteIncident(String incidentId);
}

class FirestoreIncidentRepository implements IncidentRepository {
  FirestoreIncidentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int streamLimit = 300;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection('incidents');

  @override
  Stream<List<Incident>> watchIncidents() => _incidents
      .orderBy('createdAt', descending: true)
      .limit(streamLimit)
      .snapshots()
      .map((snap) => snap.docs.map(Incident.fromFirestore).toList());

  @override
  String newIncidentId() => _incidents.doc().id;

  @override
  Future<void> createIncident(Incident incident) {
    return _incidents.doc(incident.id).set({
      ...incident.toCreateMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateIncidentDetails(Incident incident) {
    return _incidents.doc(incident.id).update({
      'title': incident.title,
      'description': incident.description,
      'category': incident.category.name,
      'priority': incident.priority.name,
      'location': incident.location,
      'locationDetail': incident.locationDetail,
      'isAnonymous': incident.isAnonymous,
      'reporterName': incident.reporterName,
      'imageUrl': incident.imageUrl,
      'imagePath': incident.imagePath,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addStatusChange(String incidentId, StatusChange change) {
    return _incidents.doc(incidentId).update({
      'status': change.status.name,
      'statusHistory': FieldValue.arrayUnion([change.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setSupport(
    String incidentId,
    String uid, {
    required bool support,
  }) {
    return _incidents.doc(incidentId).update({
      'supporters': support
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  @override
  Future<void> deleteIncident(String incidentId) =>
      _incidents.doc(incidentId).delete();
}
