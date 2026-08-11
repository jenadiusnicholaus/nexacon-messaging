# Connection

## Connecting with NX ID

```dart
final messaging = NexaconMessaging(
  apiKey: 'your-api-key',
  secretKey: 'your-secret-key',
);

final connected = await messaging.connect(
  nxid: '+255123456789@your-domain.com',
  password: 'nx-token',
  wsUrl: 'wss://your-domain.com/xmpp-websocket',
);
```

### Parameters

| Parameter  | Type      | Required | Description                                      |
| ---------- | --------- | -------- | ------------------------------------------------ |
| `nxid`     | `String`  | Yes      | Full JID (e.g., `+255123456789@your-domain.com`) |
| `password` | `String`  | Yes      | NX authentication token                          |
| `wsUrl`    | `String`  | Yes      | WebSocket endpoint URL                           |
| `resource` | `String?` | No       | XMPP resource (auto-generated if omitted)        |

## Connecting with Token

Fetches a token from the API and connects in one step:

```dart
final connected = await messaging.connectWithToken(
  username: '+255123456789',
  apiKey: 'your-api-key',
  secretKey: 'your-secret-key',
);
```

This calls the `/nexacon-auth/nxm-token/` endpoint, retrieves the JID, token, and WebSocket URL, then connects automatically.

## Connection States

```dart
messaging.connectionStateStream.listen((state) {
  switch (state) {
    case NxConnectionState.disconnected:
      print('Disconnected');
    case NxConnectionState.connecting:
      print('Connecting...');
    case NxConnectionState.connected:
      print('Connected (pre-auth)');
    case NxConnectionState.authenticating:
      print('Authenticating...');
    case NxConnectionState.authenticated:
      print('Authenticated');
    case NxConnectionState.failed:
      print('Connection failed');
  }
});
```

### NxConnectionState Values

| State            | Description                                   |
| ---------------- | --------------------------------------------- |
| `disconnected`   | Not connected to the server                   |
| `connecting`     | WebSocket connection in progress              |
| `connected`      | WebSocket connected, before authentication    |
| `authenticating` | SASL PLAIN authentication in progress         |
| `authenticated`  | Fully authenticated and ready to send/receive |
| `failed`         | Connection or authentication failed           |

## Auto-Reconnect

The SDK uses `web_socket_client` with `LinearBackoff` for automatic reconnection:

- Initial delay: 1 second
- Increment: 2 seconds per attempt
- Maximum delay: 30 seconds

No manual intervention is needed — the SDK reconnects automatically and re-authenticates.

## Heartbeat

A ping is sent every 30 seconds (XEP-0199) to keep the connection alive:

```dart
// Automatic — no code needed
// Ping is started after successful authentication
```

## Disconnecting

```dart
// Graceful disconnect
await messaging.disconnect();

// Full cleanup (call after disconnect)
messaging.dispose();
```

!!! warning
Always call `dispose()` after `disconnect()` to close stream controllers and release resources.

## Checking Connection Status

```dart
// Quick check
if (messaging.isConnected) {
  // Safe to send messages
}

// Detailed state
final state = messaging.connectionState;
print('Current state: $state');

// Current user JID
print('Connected as: ${messaging.currentUserId}');
```
