# NxApiClient

REST API client for Nexacon messaging endpoints.

## Constructor

```dart
NxApiClient({
  required String apiKey,
  required String secretKey,
  String baseUrl = 'https://your-domain.com/api/v1.0',
  Duration timeout = const Duration(seconds: 30),
})
```

| Parameter   | Type       | Default                            | Description                              |
| ----------- | ---------- | ---------------------------------- | ---------------------------------------- |
| `apiKey`    | `String`   | —                                  | API key sent as `X-API-Key` header       |
| `secretKey` | `String`   | —                                  | Secret key sent as `X-Secret-Key` header |
| `baseUrl`   | `String`   | `https://your-domain.com/api/v1.0` | API base URL                             |
| `timeout`   | `Duration` | 30s                                | Request timeout                          |

## Properties

| Property    | Type       | Description     |
| ----------- | ---------- | --------------- |
| `apiKey`    | `String`   | API key         |
| `secretKey` | `String`   | Secret key      |
| `baseUrl`   | `String`   | Base URL        |
| `timeout`   | `Duration` | Request timeout |

## Methods

### `setToken`

```dart
void setToken(String token)
```

Sets the NX token used for authenticated requests (sent as `X-NX-Token` header).

### `getToken`

```dart
String? getToken()
```

Returns the currently set NX token.

### `request`

```dart
Future<Map<String, dynamic>> request(
  String method,
  String endpoint, {
  Map<String, dynamic>? data,
  Map<String, dynamic>? params,
})
```

Generic request method. Supports `GET`, `POST`, `PUT`, `DELETE`.

### `getNxToken`

```dart
Future<Map<String, dynamic>> getNxToken(String username)
```

Fetches an NX token from `/nexacon-auth/nxm-token/`.

**Response:**

```json
{
  "token": "nx-token-string",
  "jid": "+255123456789@your-domain.com",
  "nxws": "wss://your-domain.com/xmpp-websocket"
}
```

### `refreshNxToken`

```dart
Future<Map<String, dynamic>> refreshNxToken(String refreshToken)
```

Refreshes an expired NX token via `/nexacon-auth/nxm-token/refresh/`.

### `getMessageHistory`

```dart
Future<NxMessageHistoryResponse> getMessageHistory({
  String? peer,
  int page = 1,
  int pageSize = 20,
  int offset = 0,
  DateTime? startDate,
  DateTime? endDate,
})
```

Fetches message history from `/nx/history/`.

**Query parameters sent:**

| Parameter    | Description                    |
| ------------ | ------------------------------ |
| `limit`      | Page size                      |
| `offset`     | Pagination offset              |
| `peer`       | Phone number (without `+`)     |
| `start_date` | Start date filter (YYYY-MM-DD) |
| `end_date`   | End date filter (YYYY-MM-DD)   |

### `getPresence`

```dart
Future<Map<String, dynamic>> getPresence([String? user])
```

Queries presence from `/nx/presence/`.

### `close`

```dart
void close()
```

Closes the underlying HTTP client.

## Request Headers

All requests include:

| Header         | Value              |
| -------------- | ------------------ |
| `Content-Type` | `application/json` |
| `X-API-Key`    | `apiKey`           |
| `X-Secret-Key` | `secretKey`        |
| `X-NX-Token`   | NX token (if set)  |

## Error Handling

Requests throw an `Exception` if:

- The HTTP status code is >= 400
- The request times out
- The HTTP call fails (network error, etc.)
