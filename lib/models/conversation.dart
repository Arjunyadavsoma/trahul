class Conversation {
  final String id;
  final List<String> members;
  final String type;
  final Map<String, dynamic>? lastMessage;

  Conversation({
    required this.id,
    required this.members,
    required this.type,
    this.lastMessage,
  });

  factory Conversation.fromMap(String id, Map<String, dynamic> data) {
    return Conversation(
      id: id,
      members: List<String>.from(data['members']),
      type: data['type'],
      lastMessage: data['lastMessage'],
    );
  }
}
