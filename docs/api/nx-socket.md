# NxSocket

Low-level WebSocket client handling the XMPP-over-WebSocket protocol (RFC 7395).

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `state` | `NxConnectionState` | Current connection state |
| `isAuthenticated` | `bool` | Whether authenticated |
| `isConnected` | `bool` | Whether connected or authenticated |
| `jid` | `String?` | Configured JID |
| `boundJid` | `String?` | JID after resource binding |
| `messageStream` | `Stream<NxMessage>` | Incoming messages |
| `presenceStream` | `Stream<NxPresence>` | Presence updates |
| `stateStream` | `Stream<NxConnectionState>` | Connection state changes |
| `receiptStream` | `Stream<Map<String, dynamic>>` | Receipt events |

## Methods

### `connect`

```dart
Future<bool> connect({
  required String jid,
  required String password,
  required String wsUrl,
  String? resource,
})
```

Connects to the NX WebSocket server. Performs SASL PLAIN authentication and resource binding automatically.

### `disconnect`

```dart
Future<void> disconnect()
```

Sends a close frame and closes the WebSocket connection.

### `sendMessage`

```dart
Future<void> sendMessage(String to, String body, {String? id})
```

Sends a chat message stanza with a delivery receipt request.

### `sendPresence`

```dart
Future<void> sendPresence({String? type, String? show})
```

Sends a presence stanza. Use `type: 'unavailable'` for offline, `show: 'away'` for away, etc.

### `sendPresenceSubscription`

```dart
Future<void> sendPresenceSubscription(String to)
```

Sends a presence subscription request to the specified JID.

### `sendChatState`

```dart
Future<void> sendChatState(String to, String state)
```

Sends a chat state notification. Valid states: `composing`, `paused`, `active`, `inactive`, `gone`.

### `sendDeliveryReceipt`

```dart
Future<void> sendDeliveryReceipt(String to, String messageId)
```

Sends a delivery receipt (XEP-0184) for a received message.

### `reconnect`

```dart
Future<bool> reconnect()
```

Reconnects using the stored JID, password, and WebSocket URL.

### `dispose`

```dart
void dispose()
```

Closes all stream controllers and cleans up resources.

## Protocol Details

### Authentication Flow

1. Open WebSocket connection
2. Send XMPP `<open>` frame
3. Receive `<stream:features>` with SASL mechanisms
4. Send SASL PLAIN auth (base64-encoded `\0username\0password`)
5. Receive `<success>`
6. Re-open stream
7. Bind resource via `<iq type="set">`
8. Start session
9. Send initial presence

### Heartbeat

A ping (`<iq type="get"><ping/></iq>`) is sent every 30 seconds after authentication to keep the connection alive (XEP-0199).

### Auto-Reconnect

Uses `LinearBackoff` from `web_socket_client`:

| Setting | Value |
|---------|-------|
| Initial delay | 1 second |
| Increment | 2 seconds |
| Maximum delay | 30 seconds |

### XML Escaping

All outgoing XML is escaped via `_escapeXml()`:

| Character | Escaped |
|-----------|---------|
| `&` | `&amp;` |
| `<` | `&lt;` |
| `>` | `&gt;` |
| `"` | `&quot;` |
| `'` | `&apos;` |

Incoming message bodies are unescaped via `_unescapeXml()`.
