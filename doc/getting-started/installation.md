# Installation

## pub.dev

Add to your `pubspec.yaml`:

```yaml
dependencies:
  nexacon_messaging: ^1.0.1
```

Then run:

```bash
flutter pub get
```

## Git (latest development version)

```yaml
dependencies:
  nexacon_messaging:
    git:
      url: https://github.com/jenadiusnicholaus/nexacon-messaging.git
      ref: main
```

## Local path (for development)

```yaml
dependencies:
  nexacon_messaging:
    path: /path/to/nexacon-messaging
```

## Requirements

- Dart SDK: `>=3.0.0 <4.0.0`
- Flutter: `>=3.0.0`

## Dependencies

The SDK uses:

- [`http`](https://pub.dev/packages/http) — REST API calls
- [`web_socket_client`](https://pub.dev/packages/web_socket_client) — WebSocket connectivity

## Import

```dart
import 'package:nexacon_messaging/nexacon_messaging.dart';
```

This exports all public classes:

- `NexaconMessaging` — Main messaging manager
- `NxSocket` — Low-level WebSocket client
- `NxApiClient` — REST API client
- All models (`NxMessage`, `NxPresence`, `NxHistoryMessage`, etc.)
