# NexaconMessaging

The main messaging manager class. Wraps `NxSocket` and `NxApiClient` to provide a high-level API for real-time messaging.

## Constructors

### `NexaconMessaging`

```dart
NexaconMessaging({
  String apiKey = '',
  String secretKey = '',
  String baseUrl = 'https://your-domain.com/api/v1.0',
})
```

| Parameter   | Type     | Default                            | Description               |
| ----------- | -------- | ---------------------------------- | ------------------------- |
| `apiKey`    | `String` | `''`                               | API key for REST calls    |
| `secretKey` | `String` | `''`                               | Secret key for REST calls |
| `baseUrl`   | `String` | `https://your-domain.com/api/v1.0` | REST API base URL         |

### `NexaconMessaging.withApiClient`

```dart
NexaconMessaging.withApiClient(NxApiClient apiClient)
```

Use when you already have a configured `NxApiClient` instance.

## Properties

| Property                | Type                        | Description                         |
| ----------------------- | --------------------------- | ----------------------------------- |
| `messageStream`         | `Stream<NxMessage>`         | Incoming chat messages              |
| `presenceStream`        | `Stream<NxPresence>`        | Presence updates                    |
| `typingStream`          | `Stream<NxTypingEvent>`     | Typing indicator events             |
| `deliveryReceiptStream` | `Stream<NxDeliveryReceipt>` | Delivery receipt events             |
| `readReceiptStream`     | `Stream<NxReadReceipt>`     | Read receipt events                 |
| `connectionStateStream` | `Stream<NxConnectionState>` | Connection state changes            |
| `connectionState`       | `NxConnectionState`         | Current connection state            |
| `isConnected`           | `bool`                      | Whether authenticated and connected |
| `currentUserId`         | `String?`                   | Current user's JID                  |
| `api`                   | `NxApiClient`               | Underlying REST API client          |

## Methods

### Connection

| Method                                            | Returns        | Description                   |
| ------------------------------------------------- | -------------- | ----------------------------- |
| `connect({nxid, password, wsUrl, resource?})`     | `Future<bool>` | Connect with JID and password |
| `connectWithToken({username, apiKey, secretKey})` | `Future<bool>` | Connect via token endpoint    |
| `disconnect()`                                    | `Future<void>` | Disconnect from server        |
| `dispose()`                                       | `void`         | Clean up all resources        |

### Messaging

| Method                                                    | Returns        | Description                            |
| --------------------------------------------------------- | -------------- | -------------------------------------- |
| `sendMessage({to, message, messageId?, deliveryTimeout})` | `Future<void>` | Send message with delivery tracking    |
| `sendRawMessage({to, message})`                           | `Future<void>` | Send message without delivery tracking |

### Typing Indicators

| Method                                | Returns | Description                 |
| ------------------------------------- | ------- | --------------------------- |
| `sendTypingIndicator(to, {isTyping})` | `void`  | Send composing/paused state |
| `sendActiveState(to)`                 | `void`  | Send active chat state      |
| `sendInactiveState(to)`               | `void`  | Send inactive chat state    |
| `sendGoneState(to)`                   | `void`  | Send gone chat state        |

### Receipts

| Method                           | Returns | Description       |
| -------------------------------- | ------- | ----------------- |
| `sendReadReceipt(to, messageId)` | `void`  | Send read receipt |

### Presence

| Method                      | Returns                        | Description                  |
| --------------------------- | ------------------------------ | ---------------------------- |
| `subscribeToPresence(nxid)` | `void`                         | Subscribe to user's presence |
| `updatePresence({show?})`   | `void`                         | Update own presence          |
| `setOnline()`               | `void`                         | Set status to available      |
| `setAway()`                 | `void`                         | Set status to away           |
| `setBusy()`                 | `void`                         | Set status to DND            |
| `setOffline()`              | `void`                         | Set status to unavailable    |
| `getPresenceStatus(nxid)`   | `NxPresenceStatus?`            | Get cached presence          |
| `getPresence([user])`       | `Future<Map<String, dynamic>>` | Query presence via REST      |

### History

| Method                                                                     | Returns                            | Description                     |
| -------------------------------------------------------------------------- | ---------------------------------- | ------------------------------- |
| `getMessageHistory({peer?, page, pageSize, offset, startDate?, endDate?})` | `Future<NxMessageHistoryResponse>` | Fetch paginated message history |

## Internal Behavior

### Auto Domain Normalization

All recipient addresses are normalized via `_normalizeRecipient()`:

- `+2557888111169` → `+2557888111169@your-domain.com`
- `+2557888111169@your-domain.com` → unchanged

The domain is extracted from the JID after `connect()` or `connectWithToken()`.

### Auto Delivery Receipt

When a message is received, the SDK automatically sends a delivery receipt back to the sender. This is handled internally in `_setupListeners()`.

### Presence Caching

All incoming presence updates are cached in `_presenceCache` keyed by bare JID. Use `getPresenceStatus()` for quick lookups without async calls.
