import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student('Student'),
  staff('Campus Staff');

  const UserRole(this.label);

  final String label;

  static UserRole fromName(String? name) =>
      name == staff.name ? staff : student;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  bool get isStaff => role == UserRole.staff;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final created = map['createdAt'];
    return AppUser(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromName(map['role'] as String?),
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }
}
