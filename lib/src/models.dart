/// Connection states for the NX messaging client
enum NxConnectionState {
  disconnected,
  connecting,
  connected,
  authenticating,
  authenticated,
  failed,
}

/// Presence status for a user
enum NxPresenceStatus {
  online,
  away,
  busy,
  offline,
  unknown,
}

/// Represents an incoming NX message
class NxMessage {
  final String? id;
  final String? from;
  final String? to;
  final String? body;
  final String? type;
  final int timestamp;
  final String? originId;

  NxMessage({
    this.id,
    this.from,
    this.to,
    this.body,
    this.type,
    required this.timestamp,
    this.originId,
  });

  factory NxMessage.fromJson(Map<String, dynamic> json) {
    return NxMessage(
      id: json['id']?.toString(),
      from: json['from']?.toString(),
      to: json['to']?.toString(),
      body: json['body']?.toString() ?? json['message']?.toString(),
      type: json['type']?.toString() ?? 'chat',
      timestamp: json['timestamp'] is int
          ? json['timestamp'] as int
          : int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
      originId: json['origin_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'body': body,
      'type': type,
      'timestamp': timestamp,
      'origin_id': originId,
    };
  }
}

/// Represents a presence update for a user
class NxPresence {
  final String? from;
  final NxPresenceStatus status;
  final String? show;
  final int timestamp;

  NxPresence({
    this.from,
    this.status = NxPresenceStatus.unknown,
    this.show,
    required this.timestamp,
  });

  factory NxPresence.fromXmpp(String? from, String? type, String? show) {
    NxPresenceStatus status;
    if (type == 'unavailable') {
      status = NxPresenceStatus.offline;
    } else if (show == 'away') {
      status = NxPresenceStatus.away;
    } else if (show == 'dnd' || show == 'xa') {
      status = NxPresenceStatus.busy;
    } else if (type == null || type == 'available') {
      status = NxPresenceStatus.online;
    } else {
      status = NxPresenceStatus.unknown;
    }

    return NxPresence(
      from: from,
      status: status,
      show: show,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// Typing indicator event
class NxTypingEvent {
  final String? from;
  final bool isTyping;
  final int timestamp;

  NxTypingEvent({
    this.from,
    required this.isTyping,
    required this.timestamp,
  });
}

/// Delivery receipt event
class NxDeliveryReceipt {
  final String? from;
  final String? messageId;
  final int timestamp;

  NxDeliveryReceipt({
    this.from,
    this.messageId,
    required this.timestamp,
  });
}

/// Read receipt event
class NxReadReceipt {
  final String? from;
  final String? messageId;
  final int timestamp;

  NxReadReceipt({
    this.from,
    this.messageId,
    required this.timestamp,
  });
}

/// Message history response from the API
class NxMessageHistoryResponse {
  final String status;
  final int total;
  final int limit;
  final int offset;
  final int? nextOffset;
  final bool hasNext;
  final bool hasPrev;
  final List<NxHistoryMessage> messages;

  NxMessageHistoryResponse({
    required this.status,
    required this.total,
    required this.limit,
    required this.offset,
    this.nextOffset,
    required this.hasNext,
    required this.hasPrev,
    required this.messages,
  });

  factory NxMessageHistoryResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> messagesList = _asList(json['messages']) ??
        _asList(json['data']) ??
        _asList(json['results']) ??
        _asList(json['items']) ??
        <dynamic>[];
    List<NxHistoryMessage> parsedMessages = [];

    for (final item in messagesList) {
      if (item is Map<String, dynamic>) {
        try {
          parsedMessages.add(NxHistoryMessage.fromJson(item));
        } catch (e) {
          // Log parse failures to help debugging broken response items
          // ignore: avoid_print
          print('⚠️ Failed to parse NxHistoryMessage: $e, item: $item');
        }
      }
    }

    return NxMessageHistoryResponse(
      status: json['status']?.toString() ?? 'ok',
      total: json['total'] is int
          ? json['total'] as int
          : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      limit: json['limit'] is int
          ? json['limit'] as int
          : int.tryParse(json['limit']?.toString() ?? '20') ?? 20,
      offset: json['offset'] is int
          ? json['offset'] as int
          : int.tryParse(json['offset']?.toString() ?? '0') ?? 0,
      nextOffset: json['next_offset'] is int
          ? json['next_offset'] as int
          : int.tryParse(json['next_offset']?.toString() ?? ''),
      hasNext: json['has_next'] is bool
          ? json['has_next'] as bool
          : json['hasNext'] is bool
              ? json['hasNext'] as bool
              : parsedMessages.length >=
                  (json['limit'] is int
                      ? json['limit'] as int
                      : int.tryParse(json['limit']?.toString() ?? '20') ?? 20),
      hasPrev: json['has_prev'] is bool
          ? json['has_prev'] as bool
          : json['hasPrev'] is bool
              ? json['hasPrev'] as bool
              : false,
      messages: parsedMessages,
    );
  }

  static List<dynamic>? _asList(dynamic value) {
    return value is List<dynamic> ? value : null;
  }
}

/// Individual message from history
class NxHistoryMessage {
  final String id;
  final String from;
  final String to;
  final String body;
  final int timestamp;
  final String type;
  final String? originId;
  final bool isMe;
  final bool read;

  NxHistoryMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    required this.timestamp,
    required this.type,
    this.originId,
    this.isMe = false,
    this.read = false,
  });

  factory NxHistoryMessage.fromJson(Map<String, dynamic> json) {
    return NxHistoryMessage(
      id: json['id']?.toString() ?? '',
      from: json['from']?.toString() ??
          json['from_jid']?.toString() ??
          json['fromNxid']?.toString() ??
          json['sender']?.toString() ??
          '',
      to: json['to']?.toString() ??
          json['to_jid']?.toString() ??
          json['toNxid']?.toString() ??
          '',
      body: json['body']?.toString() ??
          json['message']?.toString() ??
          json['content']?.toString() ??
          json['text']?.toString() ??
          '',
      timestamp: _parseTimestamp(json['timestamp']),
      type: json['type']?.toString() ?? 'chat',
      originId: json['origin_id']?.toString() ?? json['originId']?.toString(),
      isMe: json['is_me'] is bool ? json['is_me'] as bool : false,
      read: json['read'] is bool ? json['read'] as bool : false,
    );
  }

  /// Parse timestamp that may be in seconds, milliseconds, or microseconds.
  /// Returns value in milliseconds.
  static int _parseTimestamp(dynamic value) {
    if (value == null) return 0;
    int raw;
    if (value is int) {
      raw = value;
    } else {
      raw = int.tryParse(value.toString()) ?? 0;
    }
    // Microseconds (16+ digits) → milliseconds
    if (raw > 1000000000000000) return raw ~/ 1000;
    // Already milliseconds (13 digits)
    if (raw > 1000000000000) return raw;
    // Seconds (10 digits) → milliseconds
    if (raw > 1000000000) return raw * 1000;
    return raw;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'body': body,
      'timestamp': timestamp,
      'type': type,
      'origin_id': originId,
      'is_me': isMe,
      'read': read,
    };
  }
}
