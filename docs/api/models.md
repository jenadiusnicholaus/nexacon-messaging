# Models

## Enums

### NxConnectionState

| Value | Description |
|-------|-------------|
| `disconnected` | Not connected |
| `connecting` | WebSocket connecting |
| `connected` | WebSocket connected, pre-auth |
| `authenticating` | SASL authentication in progress |
| `authenticated` | Fully authenticated |
| `failed` | Connection or auth failed |

### NxPresenceStatus

| Value | Description |
|-------|-------------|
| `online` | User is available |
| `away` | User is away |
| `busy` | Do not disturb |
| `offline` | User is offline |
| `unknown` | Unrecognized presence |

## Classes

### NxMessage

Real-time incoming message from the WebSocket stream.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String?` | Message ID |
| `from` | `String?` | Sender JID |
| `to` | `String?` | Recipient JID |
| `body` | `String?` | Message body |
| `type` | `String?` | Message type (`chat`, `chat_state_composing`, etc.) |
| `timestamp` | `int` | Timestamp in milliseconds |
| `originId` | `String?` | Origin ID |

**Factory:** `NxMessage.fromJson(Map<String, dynamic> json)`

### NxPresence

Presence update event.

| Field | Type | Description |
|-------|------|-------------|
| `from` | `String?` | User JID |
| `status` | `NxPresenceStatus` | Parsed status |
| `show` | `String?` | Raw XMPP show value |
| `timestamp` | `int` | Update timestamp in milliseconds |

**Factory:** `NxPresence.fromXmpp(String? from, String? type, String? show)`

### NxTypingEvent

Typing indicator event.

| Field | Type | Description |
|-------|------|-------------|
| `from` | `String?` | Sender JID |
| `isTyping` | `bool` | `true` = composing, `false` = paused |
| `timestamp` | `int` | Event timestamp in milliseconds |

### NxDeliveryReceipt

Delivery receipt event (XEP-0184).

| Field | Type | Description |
|-------|------|-------------|
| `from` | `String?` | Recipient JID |
| `messageId` | `String?` | Delivered message ID |
| `timestamp` | `int` | Receipt timestamp in milliseconds |

### NxReadReceipt

Read receipt event.

| Field | Type | Description |
|-------|------|-------------|
| `from` | `String?` | Recipient JID |
| `messageId` | `String?` | Read message ID |
| `timestamp` | `int` | Receipt timestamp in milliseconds |

### NxMessageHistoryResponse

Response from the message history REST API.

| Field | Type | Description |
|-------|------|-------------|
| `status` | `String` | API status (`ok`, `success`) |
| `total` | `int` | Total messages matching query |
| `limit` | `int` | Page size |
| `offset` | `int` | Current offset |
| `nextOffset` | `int?` | Next page offset (null if no more) |
| `hasNext` | `bool` | More pages available |
| `hasPrev` | `bool` | Previous pages exist |
| `messages` | `List<NxHistoryMessage>` | Message list |

**Factory:** `NxMessageHistoryResponse.fromJson(Map<String, dynamic> json)`

The `fromJson` factory is robust — it tries multiple possible keys for the messages list (`messages`, `data`, `results`, `items`) and logs parse failures for individual items.

### NxHistoryMessage

Individual message from history.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Message ID |
| `from` | `String` | Sender JID |
| `to` | `String` | Recipient JID |
| `body` | `String` | Message body |
| `timestamp` | `int` | Timestamp in **milliseconds** (auto-normalized) |
| `type` | `String` | Message type |
| `originId` | `String?` | Origin ID |
| `isMe` | `bool` | Whether sent by current user (from API `is_me` field) |
| `read` | `bool` | Whether message has been read |

**Factory:** `NxHistoryMessage.fromJson(Map<String, dynamic> json)`

The `fromJson` factory tries multiple field names for `from` (`from`, `from_jid`, `fromNxid`, `sender`) and `to` (`to`, `to_jid`, `toNxid`).

#### Timestamp Normalization

The `_parseTimestamp` method auto-detects the input unit:

| Input | Detection | Output |
|-------|-----------|-------|
| `1786366457345144` | > 1e15 (microseconds) | `1786366457345` (÷1000) |
| `1786366457345` | > 1e12 (milliseconds) | `1786366457345` (unchanged) |
| `1786366457` | > 1e9 (seconds) | `1786366457000` (×1000) |
