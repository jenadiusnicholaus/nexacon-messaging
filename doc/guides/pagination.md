# Pagination

## Offset-Based Pagination

The Nexacon API uses **offset-based pagination** (not page-based). This allows efficient fetching of message history with infinite scrolling.

## How It Works

```
Request:  GET /nx/history/?peer=2557888111169&limit=50&offset=0
Response: { total: 72, messages: [...50 items...], next_offset: 50, has_next: true }

Request:  GET /nx/history/?peer=2557888111169&limit=50&offset=50
Response: { total: 72, messages: [...22 items...], next_offset: null, has_next: false }
```

## Implementing Infinite Scroll

```dart
class ChatHistoryLoader {
  final NexaconMessaging messaging;
  final String peer;
  
  int? _nextOffset;
  bool _hasMore = true;
  bool _isLoading = false;
  final List<NxHistoryMessage> _allMessages = [];

  ChatHistoryLoader(this.messaging, this.peer);

  Future<void> loadFirstPage() async {
    final history = await messaging.getMessageHistory(
      peer: peer,
      offset: 0,
      pageSize: 50,
    );
    
    _allMessages.addAll(history.messages);
    _nextOffset = history.nextOffset;
    _hasMore = history.hasNext;
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _nextOffset == null) return;
    
    _isLoading = true;
    try {
      final history = await messaging.getMessageHistory(
        peer: peer,
        offset: _nextOffset!,
        pageSize: 50,
      );
      
      _allMessages.addAll(history.messages);
      _nextOffset = history.nextOffset;
      _hasMore = history.hasNext;
    } finally {
      _isLoading = false;
    }
  }

  List<NxHistoryMessage> get messages => _allMessages;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
}
```

## Auto-Loading with Filtering

When filtering out signaling messages (e.g., WebRTC call invitations), a page of 50 messages may yield only a few displayable messages. Auto-load the next page when too few are visible:

```dart
Future<void> loadWithAutoPagination() async {
  var offset = 0;
  final displayable = <NxHistoryMessage>[];
  
  while (true) {
    final history = await messaging.getMessageHistory(
      peer: peer,
      offset: offset,
      pageSize: 50,
    );
    
    final filtered = history.messages.where(_isChatMessage).toList();
    displayable.addAll(filtered);
    
    if (!history.hasNext || filtered.length >= 10) {
      break;  // Enough messages or no more pages
    }
    
    offset = history.nextOffset ?? (offset + 50);
  }
}

bool _isChatMessage(NxHistoryMessage msg) {
  // Filter out call invitations, WebRTC signaling, etc.
  if (msg.body.trim().startsWith('{')) {
    try {
      final map = jsonDecode(msg.body);
      final type = map['type'] ?? '';
      return type == 'chat' || type.isEmpty;
    } catch (_) {
      return true;  // Not valid JSON, treat as plain text
    }
  }
  return true;
}
```

## Pagination Fields Reference

| Field | Type | Description |
|-------|------|-------------|
| `offset` | `int` | Starting position of current page |
| `nextOffset` | `int?` | Starting position for next page |
| `hasNext` | `bool` | Whether more pages exist |
| `hasPrev` | `bool` | Whether previous pages exist |
| `total` | `int` | Total messages matching the query |
| `limit` | `int` | Page size used in the request |
