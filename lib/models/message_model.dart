import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String senderId;
  final DateTime? createdAt;

  factory MessageModel.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final timestamp = data['createdAt'];
    return MessageModel(
      id: document.id,
      text: (data['text'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  Map<String, dynamic> toMap({required String senderId}) => {
        'text': text,
        'senderId': senderId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
