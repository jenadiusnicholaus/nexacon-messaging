# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] - 2026-08-22

### Changed

- Renamed `docs/` to `doc/` to follow pub.dev package layout convention

## [1.0.4] - 2026-08-12

### Changed

- Consolidated `NexaconConfig`: all URLs and domains now derive from single `host` constant
- Renamed `xmppDomain` → `nxDomain` (same as `host`)
- Removed duplicate hardcoded domain strings

## [1.0.3] - 2026-08-12

### Added

- Auto-approve incoming presence subscription requests for bidirectional presence flow
- `sendDirectedPresence()` method on `NexaconMessaging` — send presence to a specific user directly
- `subscribeToPresence()` now also sends directed presence so contacts see you online immediately

### Fixed

- Fixed `curly_braces_in_flow_control_structures` lint in `nx_socket.dart`

## [1.0.2] - 2026-08-12

### Changed

- `connect()` `wsUrl` parameter is now optional — when omitted, the SDK derives the WebSocket URL from `baseUrl`
- Updated README quick start to omit `wsUrl`

## [1.0.1] - 2026-08-10

### Added

- **API Improvement**: Auto-append domain to recipient addresses
  - Users can now use phone numbers directly (e.g., `+255123456789`)
  - No need to manually add `@nxservice.quantumvision-tech.com`
  - Domain is extracted from JID after connection and applied automatically
  - Backward compatible - full JIDs still work

## [1.0.0] - 2026-08-10

### Added

- `NexaconMessaging` — main real-time messaging manager
- Real-time send/receive messages over WebSocket (NX protocol)
- Presence tracking with `NxPresenceStatus` (online, offline, away, busy)
- Typing indicators via XEP-0085 chat state notifications (composing, paused, active, inactive, gone)
- Delivery receipts via XEP-0184 with `Completer`-based delivery tracking
- Read receipts
- Message history via REST API with `NxMessageHistoryResponse` and `NxHistoryMessage` models
- Auto-reconnect with exponential backoff
- Heartbeat/ping to keep connection alive
- `NxSocket` — low-level WebSocket client handling NX protocol
- `NxApiClient` — REST API client for token management, message history, and presence queries
- `connectWithToken()` — one-step connect using NX token endpoint
- Presence cache for quick status lookups
- `subscribeToPresence()` — send presence subscription requests
- Presence management: `setOnline()`, `setAway()`, `setBusy()`, `setOffline()`
