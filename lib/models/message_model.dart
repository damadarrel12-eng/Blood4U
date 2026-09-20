class MessageModel {
  String text;
  String senderId;
  DateTime time;

  MessageModel({
    required this.text,
    required this.senderId,
    required this.time,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'senderId': senderId,
        'time': time,
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      text: map['text'],
      senderId: map['senderId'],
      time: map['time'].toDate(),
    );
  }
}