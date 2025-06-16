class ScheduledMessage {
  final String id;
  final List<String> phoneNumbers;
  final String message;
  final DateTime scheduledTime;
  final String type;
  final bool isSent;
  final String? error;

  ScheduledMessage({
    required this.id,
    required this.phoneNumbers,
    required this.message,
    required this.scheduledTime,
    required this.type,
    this.isSent = false,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumbers': phoneNumbers.join(','),
      'message': message,
      'scheduledTime': scheduledTime.toIso8601String(),
      'type': type,
      'isSent': isSent ? 1 : 0,
      'error': error,
    };
  }

  factory ScheduledMessage.fromMap(Map<String, dynamic> map) {
    return ScheduledMessage(
      id: map['id'] as String,
      phoneNumbers: (map['phoneNumbers'] as String).split(','),
      message: map['message'] as String,
      scheduledTime: DateTime.parse(map['scheduledTime'] as String),
      type: map['type'] as String,
      isSent: (map['isSent'] as int) == 1,
      error: map['error'] as String?,
    );
  }
} 