import 'dart:async';

import 'models.dart';
import 'nx_socket.dart';
import 'nx_api_client.dart';

/// Main messaging manager for Nexacon real-time messaging
///
/// Provides:
/// - Real-time send/receive messages
/// - Presence tracking (online/offline/away/busy)
/// - Typing indicators (composing/paused)
/// - Delivery receipts
/// - Read receipts
/// - Message history via REST API
class NexaconMessaging {
  late final NxSocket _socket;
  late final NxApiClient _api;

  // Stream controllers for the public API
  final _messageController = StreamController<NxMessage>.broadcast();
  final _presenceController = StreamController<NxPresence>.broadcast();
  final _typingController = StreamController<NxTypingEvent>.broadcast();
  final _deliveryReceiptController =
      StreamController<NxDeliveryReceipt>.broadcast();
  final _readReceiptController = StreamController<NxReadReceipt>.broadcast();
  final _connectionStateController =
      StreamController<NxConnectionState>.broadcast();

  // Track presence state per user
  final Map<String, NxPresenceStatus> _presenceCache = {};

  // Subscriptions
  StreamSubscription? _socketMessageSub;
  StreamSubscription? _socketPresenceSub;
  StreamSubscription? _socketReceiptSub;
  StreamSubscription? _socketStateSub;

  // Track pending messages for delivery tracking
  final Map<String, Completer<void>> _pendingDeliveries = {};

  /// Stream of incoming chat messages
  Stream<NxMessage> get messageStream => _messageController.stream;

  /// Stream of presence changes (online/offline/away/busy)
  Stream<NxPresence> get presenceStream => _presenceController.stream;

  /// Stream of typing indicator events
  Stream<NxTypingEvent> get typingStream => _typingController.stream;

  /// Stream of delivery receipts
  Stream<NxDeliveryReceipt> get deliveryReceiptStream =>
      _deliveryReceiptController.stream;

  /// Stream of read receipts
  Stream<NxReadReceipt> get readReceiptStream => _readReceiptController.stream;

  /// Stream of connection state changes
  Stream<NxConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Current connection state
  NxConnectionState get connectionState => _socket.state;

  /// Whether the socket is connected
  bool get isConnected => _socket.isConnected;

  /// Current user's NX ID
  String? get currentUserId => _socket.jid;

  /// Get the API client for REST calls
  NxApiClient get api => _api;

  /// XMPP domain (extracted from JID after connection)
  String? _domain;

  /// Presence cache — check a user's last known status
  NxPresenceStatus? getPresenceStatus(String nxid) {
    return _presenceCache[nxid];
  }

  /// Normalize recipient address - auto-append domain if not present
  /// Accepts: "+255788811169" or "+255788811169@nxservice.quantumvision-tech.com"
  /// Returns: "+255788811169@nxservice.quantumvision-tech.com"
  String _normalizeRecipient(String recipient) {
    if (recipient.contains('@')) {
      return recipient; // Already has domain
    }
    if (_domain != null) {
      return '$recipient@$_domain'; // Append stored domain
    }
    // Fallback to default domain if not connected yet
    return '$recipient@nxservice.quantumvision-tech.com';
  }

  NexaconMessaging({
    String apiKey = '',
    String secretKey = '',
    String baseUrl = 'https://nxservice.quantumvision-tech.com/api/v1.0',
  }) {
    _socket = NxSocket();
    _api = NxApiClient(apiKey: apiKey, secretKey: secretKey, baseUrl: baseUrl);
    _setupListeners();
  }

  /// Create with an existing API client (e.g., if you already have NX tokens)
  NexaconMessaging.withApiClient(this._api) {
    _socket = NxSocket();
    _setupListeners();
  }

  void _setupListeners() {
    // Route socket messages
    _socketMessageSub = _socket.messageStream.listen((msg) {
      // Check if it's a chat state notification (typing)
      if (msg.type != null && msg.type!.startsWith('chat_state_')) {
        final state = msg.type!.substring('chat_state_'.length);
        final isTyping = state == 'composing';
        _typingController.add(
          NxTypingEvent(
            from: msg.from,
            isTyping: isTyping,
            timestamp: msg.timestamp,
          ),
        );
        return;
      }

      // Regular message
      if (msg.body != null && msg.body!.isNotEmpty) {
        _messageController.add(msg);

        // Auto-send delivery receipt
        if (msg.id != null && msg.from != null) {
          _socket.sendDeliveryReceipt(msg.from!, msg.id!);
        }
      }
    });

    // Route presence
    _socketPresenceSub = _socket.presenceStream.listen((presence) {
      if (presence.from != null) {
        final bareFrom = presence.from!.split('/').first;
        _presenceCache[bareFrom] = presence.status;
      }
      _presenceController.add(presence);
    });

    // Route receipts
    _socketReceiptSub = _socket.receiptStream.listen((data) {
      final type = data['type'] as String?;
      if (type == 'delivery') {
        final receipt = NxDeliveryReceipt(
          from: data['from'] as String?,
          messageId: data['message_id'] as String?,
          timestamp: data['timestamp'] as int,
        );
        _deliveryReceiptController.add(receipt);

        // Complete any pending delivery future
        if (receipt.messageId != null) {
          _pendingDeliveries.remove(receipt.messageId)?.complete();
        }
      }
    });

    // Route connection state
    _socketStateSub = _socket.stateStream.listen((state) {
      _connectionStateController.add(state);
    });
  }

  /// Connect to the NX server
  Future<bool> connect({
    required String nxid,
    required String password,
    required String wsUrl,
    String? resource,
  }) async {
    final connected = await _socket.connect(
      jid: nxid,
      password: password,
      wsUrl: wsUrl,
      resource: resource,
    );

    // Extract and store domain from JID
    if (connected && nxid.contains('@')) {
      _domain = nxid.split('@')[1];
    }

    return connected;
  }

  /// Connect using an NX token (fetches token from API first)
  Future<bool> connectWithToken({
    required String username,
    required String apiKey,
    required String secretKey,
  }) async {
    final tokenData = await NxApiClient(
      apiKey: apiKey,
      secretKey: secretKey,
      baseUrl: _api.baseUrl,
    ).getNxToken(username);
    final token = tokenData['token'] as String;
    final jid = tokenData['jid'] as String;
    final wsUrl = tokenData['nxws'] as String;

    _api.setToken(token);

    return _socket.connect(jid: jid, password: token, wsUrl: wsUrl);
  }

  /// Send a real-time message
  ///
  /// Returns a [Future] that completes when a delivery receipt is received,
  /// or times out after [deliveryTimeout].
  Future<void> sendMessage({
    required String to,
    required String message,
    String? messageId,
    Duration deliveryTimeout = const Duration(seconds: 30),
  }) async {
    final id = messageId ?? 'msg_${DateTime.now().millisecondsSinceEpoch}';

    final completer = Completer<void>();
    _pendingDeliveries[id] = completer;

    await _socket.sendMessage(_normalizeRecipient(to), message, id: id);

    // Set up delivery timeout
    completer.future.timeout(
      deliveryTimeout,
      onTimeout: () {
        _pendingDeliveries.remove(id);
      },
    );
  }

  /// Send a raw text message (no JSON wrapping)
  Future<void> sendRawMessage({
    required String to,
    required String message,
  }) async {
    await _socket.sendMessage(_normalizeRecipient(to), message);
  }

  /// Send a typing indicator
  void sendTypingIndicator(String to, {bool isTyping = true}) {
    _socket.sendChatState(
        _normalizeRecipient(to), isTyping ? 'composing' : 'paused');
  }

  /// Send "active" chat state (user is active in the chat)
  void sendActiveState(String to) {
    _socket.sendChatState(_normalizeRecipient(to), 'active');
  }

  /// Send "inactive" chat state (user left the chat)
  void sendInactiveState(String to) {
    _socket.sendChatState(_normalizeRecipient(to), 'inactive');
  }

  /// Send "gone" chat state (user closed the chat)
  void sendGoneState(String to) {
    _socket.sendChatState(_normalizeRecipient(to), 'gone');
  }

  /// Send a read receipt for a message
  void sendReadReceipt(String to, String messageId) {
    _socket.sendDeliveryReceipt(_normalizeRecipient(to), messageId);
  }

  /// Subscribe to a user's presence updates
  void subscribeToPresence(String nxid) {
    _socket.sendPresenceSubscription(_normalizeRecipient(nxid));
  }

  /// Update your own presence
  void updatePresence({String? show}) {
    _socket.sendPresence(show: show);
  }

  /// Set status to away
  void setAway() {
    _socket.sendPresence(show: 'away');
  }

  /// Set status to busy (do not disturb)
  void setBusy() {
    _socket.sendPresence(show: 'dnd');
  }

  /// Set status to available (online)
  void setOnline() {
    _socket.sendPresence();
  }

  /// Set status to offline
  void setOffline() {
    _socket.sendPresence(type: 'unavailable');
  }

  /// Fetch message history from the API
  Future<NxMessageHistoryResponse> getMessageHistory({
    String? peer,
    int page = 1,
    int pageSize = 20,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _api.getMessageHistory(
      peer: peer,
      page: page,
      pageSize: pageSize,
      offset: offset,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get presence for a user via REST API
  Future<Map<String, dynamic>> getPresence([String? user]) async {
    return _api.getPresence(user);
  }

  /// Disconnect from the NX server
  Future<void> disconnect() async {
    await _socket.disconnect();
  }

  /// Clean up all resources
  void dispose() {
    _socketMessageSub?.cancel();
    _socketPresenceSub?.cancel();
    _socketReceiptSub?.cancel();
    _socketStateSub?.cancel();
    _socket.dispose();
    _api.close();
    _messageController.close();
    _presenceController.close();
    _typingController.close();
    _deliveryReceiptController.close();
    _readReceiptController.close();
    _connectionStateController.close();
    _pendingDeliveries.clear();
  }
}
