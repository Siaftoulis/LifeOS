class ChatChannel {
  final String id;
  final String name;
  final bool isDirect;
  final List<String> members;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final ChatMessage? lastMessage;
  final int unreadCount;

  const ChatChannel({
    required this.id,
    required this.name,
    required this.isDirect,
    required this.members,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ChatChannel.fromJson(Map<String, dynamic> json) {
    return ChatChannel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Channel',
      isDirect: json['is_direct'] == true || json['is_direct'] == 1,
      members: (json['members'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch((json['created_at'] ?? 0) * 1000),
      lastMessageAt: DateTime.fromMillisecondsSinceEpoch((json['last_message_at'] ?? 0) * 1000),
      lastMessage: json['last_message'] != null ? ChatMessage.fromJson(json['last_message']) : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_direct': isDirect,
    'members': members,
    'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    'last_message_at': lastMessageAt.millisecondsSinceEpoch ~/ 1000,
  };
}

class ChatMessage {
  final String id;
  final String channelID;
  final String senderID;
  final String senderName;
  final String content;
  final String? attachmentURL;
  final String? attachmentType; // image, file, audio
  final DateTime createdAt;
  final String status; // sent, delivered, read

  const ChatMessage({
    required this.id,
    required this.channelID,
    required this.senderID,
    required this.senderName,
    required this.content,
    this.attachmentURL,
    this.attachmentType,
    required this.createdAt,
    this.status = 'sent',
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      channelID: json['channel_id'] ?? '',
      senderID: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? 'Anonymous',
      content: json['content'] ?? '',
      attachmentURL: json['attachment_url'],
      attachmentType: json['attachment_type'],
      createdAt: DateTime.fromMillisecondsSinceEpoch((json['created_at'] ?? 0) * 1000),
      status: json['status'] ?? 'delivered',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'channel_id': channelID,
    'sender_id': senderID,
    'sender_name': senderName,
    'content': content,
    'attachment_url': attachmentURL,
    'attachment_type': attachmentType,
    'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
    'status': status,
  };
}
