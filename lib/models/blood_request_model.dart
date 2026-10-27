import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequest {
  const BloodRequest({
    required this.id,
    required this.requesterId,
    required this.bloodType,
    required this.hospitalName,
    required this.area,
    required this.details,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String requesterId;
  final String bloodType;
  final String hospitalName;
  final String area;
  final String details;
  final String status;
  final DateTime? createdAt;

  bool get isOpen => status == 'open';

  factory BloodRequest.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final timestamp = data['createdAt'];
    return BloodRequest(
      id: document.id,
      requesterId: (data['requesterId'] as String?) ?? '',
      bloodType: (data['bloodType'] as String?) ?? '',
      hospitalName: (data['hospitalName'] as String?) ?? '',
      area: (data['area'] as String?) ?? '',
      details: (data['details'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'open',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
