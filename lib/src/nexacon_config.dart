/// Central configuration for the Nexacon messaging SDK.
///
/// Edit [host] to change the server — all URLs and domains derive from it.
abstract class NexaconConfig {
  /// Host domain for all Nexacon services.
  static const String host = 'nxservice.quantumvision-tech.com';

  /// NX domain (used for NX IDs) — same as [host].
  static const String nxDomain = host;

  /// REST API base URL.
  static const String baseUrl = 'https://$host/api/v1.0';

  /// NX WebSocket URL.
  static const String wsUrl = 'wss://$host/nx-websocket/';

  /// Default HTTP request timeout.
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Default WebSocket ping interval.
  static const Duration pingInterval = Duration(seconds: 30);

  /// Endpoint for fetching an NX auth token.
  static const String nxTokenEndpoint = '/nexacon-auth/nxm-token/';

  /// Endpoint for refreshing an NX auth token.
  static const String nxTokenRefreshEndpoint =
      '/nexacon-auth/nxm-token/refresh/';

  /// Endpoint for fetching message history.
  static const String historyEndpoint = '/nx/history/';

  /// Endpoint for fetching presence.
  static const String presenceEndpoint = '/nx/presence/';
}
