class Message {
  Message({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.deliveredAt,
    this.readAt,
  });

  final String sender;
  final String text;
  final int timestamp;
  final int? deliveredAt;
  final int? readAt;

  Message copyWith({
    String? sender,
    String? text,
    int? timestamp,
    int? deliveredAt,
    int? readAt,
  }) {
    return Message(
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }

  factory Message.fromMap(Map<dynamic, dynamic> data) {
    return Message(
      sender: data['sender']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
      deliveredAt: _parseNullableTimestamp(data['deliveredAt']),
      readAt: _parseNullableTimestamp(data['readAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'timestamp': timestamp,
      if (deliveredAt != null) 'deliveredAt': deliveredAt,
      if (readAt != null) 'readAt': readAt,
    };
  }

  static int _parseTimestamp(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static int? _parseNullableTimestamp(dynamic value) {
    if (value == null) return null;
    final parsed = _parseTimestamp(value);
    return parsed == 0 ? null : parsed;
  }
}
