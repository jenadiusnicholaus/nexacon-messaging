# Message History

## Overview

The SDK fetches message history via the Nexacon REST API at `/nx/history/`. Messages include the `is_me` field from the API for reliable sender detection, and timestamps are automatically normalized to milliseconds.

## Fetching History

```dart
final history = await messaging.getMessageHistory(
  peer: '255987654321',  // Phone number without +
  offset: 0,
  pageSize: 50,
);

print('Status: ${history.status}');
print('Total: ${history.total}');
print('Messages: ${history.messages.length}');
print('Has next: ${history.hasNext}');
print('Next offset: ${history.nextOffset}');
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `peer` | `String?` | No | — | Filter by peer phone number (without `+`) |
| `offset` | `int` | No | `0` | Offset for pagination |
| `pageSize` | `int` | No | `20` | Number of messages per page |
| `startDate` | `DateTime?` | No | — | Filter messages from this date |
| `endDate` | `DateTime?` | No | — | Filter messages up to this date |

!!! tip "Peer format"
    The `peer` parameter should be the phone number **without** the `+` prefix (e.g., `2557888111169`, not `+2557888111169`).

## NxMessageHistoryResponse

| Field | Type | Description |
|-------|------|-------------|
| `status` | `String` | API response status (`ok`, `success`) |
| `total` | `int` | Total number of messages matching the query |
| `limit` | `int` | Page size used |
| `offset` | `int` | Current offset |
| `nextOffset` | `int?` | Offset for the next page (null if no more pages) |
| `hasNext` | `bool` | Whether more pages are available |
| `hasPrev` | `bool` | Whether previous pages exist |
| `messages` | `List<NxHistoryMessage>` | List of messages |

## NxHistoryMessage

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Message ID |
| `from` | `String` | Sender JID |
| `to` | `String` | Recipient JID |
| `body` | `String` | Message body |
| `timestamp` | `int` | Timestamp in **milliseconds** (auto-converted) |
| `type` | `String` | Message type (usually `chat`) |
| `originId` | `String?` | Origin ID |
| `isMe` | `bool` | Whether the message was sent by the current user |
| `read` | `bool` | Whether the message has been read |

## Using isMe for Sender Detection

```dart
for (final msg in history.messages) {
  final sender = msg.isMe ? 'Me' : msg.from;
  final time = DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
  print('[$time] $sender: ${msg.body}');
}
```

## Timestamp Handling

The SDK automatically normalizes timestamps to milliseconds:

| Input Format | Digits | Example | Conversion |
|-------------|--------|---------|------------|
| Microseconds | 16+ | `1786366457345144` | `÷ 1000` |
| Milliseconds | 13 | `1786366457345` | No change |
| Seconds | 10 | `1786366457` | `× 1000` |

```dart
// Always safe to use directly
final dt = DateTime.fromMillisecondsSinceEpoch(msg.timestamp);
```

## Fetching All Messages (No Peer Filter)

```dart
final history = await messaging.getMessageHistory(
  offset: 0,
  pageSize: 100,
);

for (final msg in history.messages) {
  final peer = msg.isMe ? msg.to : msg.from;
  print('$peer: ${msg.body}');
}
```
