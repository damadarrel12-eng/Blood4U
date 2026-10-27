import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/blood_request_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<UserModel?> watchProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((document) {
      final data = document.data();
      if (!document.exists || data == null) return null;
      return UserModel.fromPrivateMap(data, documentId: document.id);
    });
  }

  Stream<List<UserModel>> watchAvailableDonors({required String currentUserId}) {
    return _db
        .collection('donors_public')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((document) => document.id != currentUserId)
            .map((document) => UserModel.fromDonorMap(
                  document.data(),
                  documentId: document.id,
                ))
            .toList());
  }

  Future<void> setDonorAvailability({
    required UserModel profile,
    required bool available,
    String area = '',
  }) async {
    final profileRef = _db.collection('users').doc(profile.uid);
    final donorRef = _db.collection('donors_public').doc(profile.uid);
    final batch = _db.batch();
    batch.update(profileRef, {'isDonorAvailable': available});
    if (available) {
      batch.set(donorRef, {
        ...profile.toDonorMap(area: area.trim()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.delete(donorRef);
    }
    await batch.commit();
  }

  Stream<List<BloodRequest>> watchOpenBloodRequests() {
    return _db
        .collection('blood_requests')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs.map(BloodRequest.fromDocument).toList();
      requests.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return requests;
    });
  }

  Future<void> createBloodRequest({
    required String requesterId,
    required String bloodType,
    required String hospitalName,
    required String area,
    required String details,
  }) {
    return _db.collection('blood_requests').add({
      'requesterId': requesterId,
      'bloodType': bloodType,
      'hospitalName': hospitalName.trim(),
      'area': area.trim(),
      'details': details.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> closeBloodRequest(String requestId) {
    return _db.collection('blood_requests').doc(requestId).update({
      'status': 'closed',
    });
  }

  String conversationIdFor(String firstUserId, String secondUserId) {
    final participants = [firstUserId, secondUserId]..sort();
    return '${participants[0]}_${participants[1]}';
  }

  Future<String> ensureConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (currentUserId == otherUserId) {
      throw ArgumentError('A conversation needs two different users.');
    }
    final id = conversationIdFor(currentUserId, otherUserId);
    final reference = _db.collection('conversations').doc(id);
    final existing = await reference.get();
    if (!existing.exists) {
      final participants = [currentUserId, otherUserId]..sort();
      await reference.set({
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(MessageModel.fromDocument)
            .toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'text': text.trim(),
      'senderId': senderId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
