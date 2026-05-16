class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String? ?? '',
      text: json['text'] as String,
      timestamp: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}
