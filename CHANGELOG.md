# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
