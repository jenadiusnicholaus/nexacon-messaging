# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-08-10

### Added

- **API Improvement**: Auto-append domain to recipient addresses
  - Users can now use phone numbers directly (e.g., `+255123456789`)
  - No need to manually add `@nxservice.quantumvision-tech.com`
  - Domain is extracted from JID after connection and applied automatically
  - Backward compatible — full JIDs still work

### Changed

- **Message History**: Switched from page-based to offset-based pagination
  - API now uses `offset` and `limit` parameters
  - Response includes `next_offset` for easy pagination
  - `hasNext` falls back to checking if full page was returned

### Fixed

- **Timestamp Parsing**: Auto-detect and normalize timestamp units
  - Microseconds (16+ digits) → milliseconds (÷1000)
  - Seconds (10 digits) → milliseconds (×1000)
  - Milliseconds (13 digits) → unchanged

### Added

- **`is_me` field**: `NxHistoryMessage` now parses `is_me` from API response
  - Reliable sender detection without phone number comparison
  - `read` field also parsed for read status

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
