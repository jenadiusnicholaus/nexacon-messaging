# Presence

## Overview

Presence tracking lets you know when users are online, away, busy, or offline. The SDK implements XMPP presence (RFC 6121) with a local cache for fast lookups.

## Setting Your Status

```dart
messaging.setOnline();    // Available (green)
messaging.setAway();      // Away (yellow)
messaging.setBusy();      // Do not disturb (red)
messaging.setOffline();   // Offline / unavailable
```

### Custom presence

```dart
messaging.updatePresence(show: 'away');
```

## Listening to Presence Changes

```dart
messaging.presenceStream.listen((presence) {
  print('User: ${presence.from}');
  print('Status: ${presence.status}');
  print('Show: ${presence.show}');
  print('Timestamp: ${presence.timestamp}');
});
```

### NxPresence Fields

| Field       | Type               | Description                               |
| ----------- | ------------------ | ----------------------------------------- |
| `from`      | `String?`          | Sender JID                                |
| `status`    | `NxPresenceStatus` | Parsed status enum                        |
| `show`      | `String?`          | Raw XMPP show value (`away`, `dnd`, `xa`) |
| `timestamp` | `int`              | Update timestamp in milliseconds          |

### NxPresenceStatus Values

| Status    | XMPP Type          | XMPP Show     | Description           |
| --------- | ------------------ | ------------- | --------------------- |
| `online`  | `available` / null | null          | User is available     |
| `away`    | `available`        | `away`        | User is away          |
| `busy`    | `available`        | `dnd` or `xa` | Do not disturb        |
| `offline` | `unavailable`      | —             | User is offline       |
| `unknown` | other              | —             | Unrecognized presence |

## Subscribing to a User's Presence

```dart
// Send a presence subscription request
messaging.subscribeToPresence('+255987654321');
```

!!! note
The recipient must approve the subscription request for you to receive their presence updates.

## Checking Cached Presence

The SDK maintains a local cache of presence states:

```dart
final status = messaging.getPresenceStatus('+255987654321@your-domain.com');
if (status == NxPresenceStatus.online) {
  print('User is online!');
}
```

## Querying Presence via REST API

For on-demand presence checks (not real-time):

```dart
final presence = await messaging.getPresence('+255987654321');
print('Online: ${presence['is_online']}');
print('Status: ${presence['status']}');
print('Last heartbeat: ${presence['last_heartbeat']}');
```

### REST Response Fields

| Field            | Type     | Description                     |
| ---------------- | -------- | ------------------------------- |
| `success`        | `bool`   | Whether the request succeeded   |
| `status`         | `String` | `available` or `unavailable`    |
| `is_online`      | `bool`   | Whether the user is online      |
| `last_heartbeat` | `String` | ISO timestamp of last heartbeat |
