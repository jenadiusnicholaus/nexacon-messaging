import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:web_socket_client/web_socket_client.dart' as ws_client;

import 'models.dart';

/// Low-level NX WebSocket client
/// Handles the raw XMPP-over-WebSocket protocol for messaging
class NxSocket {
  ws_client.WebSocket? _socket;
  NxConnectionState _state = NxConnectionState.disconnected;
  String? _jid;
  String? _password;
  String? _wsUrl;
  String? _domain;
  String? _resource;
  String? _boundJid;

  final _messageController = StreamController<NxMessage>.broadcast();
  final _presenceController = StreamController<NxPresence>.broadcast();
  final _stateController = StreamController<NxConnectionState>.broadcast();
  final _receiptController = StreamController<Map<String, dynamic>>.broadcast();

  StreamSubscription? _messageSub;
  StreamSubscription? _connectionSub;
  Timer? _pingTimer;
  bool _intentionalDisconnect = false;
  Completer<bool>? _authCompleter;
  bool _streamOpened = false;

  // Public getters
  NxConnectionState get state => _state;
  bool get isAuthenticated => _state == NxConnectionState.authenticated;
  bool get isConnected =>
      _state == NxConnectionState.authenticated ||
      _state == NxConnectionState.connected;
  String? get boundJid => _boundJid;
  String? get jid => _jid;

  Stream<NxMessage> get messageStream => _messageController.stream;
  Stream<NxPresence> get presenceStream => _presenceController.stream;
  Stream<NxConnectionState> get stateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get receiptStream => _receiptController.stream;

  /// Connect to the NX server via WebSocket
  Future<bool> connect({
    required String jid,
    required String password,
    required String wsUrl,
    String? resource,
  }) async {
    _jid = jid;
    _password = password;
    _wsUrl = wsUrl;
    _resource = resource ?? '';
    _domain = jid.contains('@')
        ? jid.split('@')[1]
        : 'nxservice.quantumvision-tech.com';
    _intentionalDisconnect = false;

    _setState(NxConnectionState.connecting);
    log('🔌 NxSocket: Connecting to $wsUrl as $jid');

    try {
      _socket = ws_client.WebSocket(
        Uri.parse(wsUrl),
        protocols: ['xmpp'],
        timeout: const Duration(seconds: 15),
        backoff: ws_client.LinearBackoff(
          initial: const Duration(seconds: 1),
          increment: const Duration(seconds: 2),
          maximum: const Duration(seconds: 30),
        ),
      );

      _authCompleter = Completer<bool>();

      _messageSub = _socket!.messages.listen(
        _onData,
        onError: _onError,
        cancelOnError: false,
      );

      _connectionSub = _socket!.connection.listen(_onConnectionState);

      await _socket!.connection
          .firstWhere(
        (s) => s is ws_client.Connected || s is ws_client.Disconnected,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('WebSocket connection timed out');
        },
      );

      final connState = _socket!.connection.state;
      if (connState is ws_client.Disconnected) {
        throw Exception('WebSocket failed to connect');
      }

      _sendStreamOpen();

      final authenticated = await _authCompleter!.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          log('❌ NxSocket: Authentication timed out');
          _setState(NxConnectionState.failed);
          return false;
        },
      );

      if (authenticated) {
        _startPing();
      }

      return authenticated;
    } catch (e) {
      log('❌ NxSocket: Connection error: $e');
      _setState(NxConnectionState.failed);
      _authCompleter?.complete(false);
      return false;
    }
  }

  void _onConnectionState(ws_client.ConnectionState state) {
    log('🔌 NxSocket connection state: $state');
    if (state is ws_client.Reconnected) {
      if (_intentionalDisconnect) {
        _socket?.close(1000, 'Intentional disconnect');
        return;
      }
      _streamOpened = false;
      _setState(NxConnectionState.connecting);
      _authCompleter = Completer<bool>();
      _sendStreamOpen();
    } else if (state is ws_client.Disconnected) {
      if (!_intentionalDisconnect) {
        _setState(NxConnectionState.disconnected);
      }
    }
  }

  /// Disconnect from the NX server
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _pingTimer?.cancel();
    _messageSub?.cancel();
    _connectionSub?.cancel();

    if (_socket != null && _streamOpened) {
      try {
        _send('<close xmlns="urn:ietf:params:xml:ns:xmpp-framing"/>');
      } catch (_) {}
    }

    _socket?.close(1000, 'Normal closure');
    _socket = null;
    _streamOpened = false;
    _setState(NxConnectionState.disconnected);
  }

  /// Send a chat message
  Future<void> sendMessage(String to, String body, {String? id}) async {
    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    final msgId = id ??
        'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final stanza =
        '<message type="chat" to="${_escapeXml(to)}" id="$msgId" from="${_escapeXml(_boundJid ?? _jid!)}">'
        '<body>${_escapeXml(body)}</body>'
        '<request xmlns="urn:xmpp:receipts"/>'
        '</message>';

    _send(stanza);
    log('📤 NxSocket: Sent message to $to');
  }

  /// Send presence
  Future<void> sendPresence({String? type, String? show}) async {
    if (!isAuthenticated) return;

    String stanza = '<presence';
    if (type != null) stanza += ' type="$type"';
    stanza += '>';
    if (show != null) stanza += '<show>$show</show>';
    stanza += '</presence>';

    _send(stanza);
  }

  /// Send a directed presence subscription request
  Future<void> sendPresenceSubscription(String to) async {
    if (!isAuthenticated) return;
    _send('<presence type="subscribe" to="${_escapeXml(to)}"/>');
  }

  /// Send a directed presence to a specific user (works even without
  /// a subscription — the server will deliver it to that user).
  Future<void> sendDirectedPresence(String to, {String? show}) async {
    if (!isAuthenticated) return;
    String stanza = '<presence to="${_escapeXml(to)}"';
    if (show != null) {
      stanza += '><show>$show</show></presence>';
    } else {
      stanza += '/>';
    }
    _send(stanza);
  }

  /// Approve a presence subscription request from another user.
  Future<void> sendPresenceSubscribed(String to) async {
    if (!isAuthenticated) return;
    _send('<presence type="subscribed" to="${_escapeXml(to)}"/>');
  }

  /// Send a typing indicator (XEP-0085 chat state notifications)
  Future<void> sendChatState(String to, String state) async {
    if (!isAuthenticated) return;

    const stateMap = {
      'composing': 'composing',
      'paused': 'paused',
      'active': 'active',
      'inactive': 'inactive',
      'gone': 'gone',
    };

    final stateValue = stateMap[state] ?? 'active';
    final stanza =
        '<message type="chat" to="${_escapeXml(to)}" from="${_escapeXml(_boundJid ?? _jid!)}">'
        '<$stateValue xmlns="http://jabber.org/protocol/chatstates"/>'
        '</message>';

    _send(stanza);
  }

  /// Send a delivery receipt
  Future<void> sendDeliveryReceipt(String to, String messageId) async {
    if (!isAuthenticated) return;

    final stanza =
        '<message to="${_escapeXml(to)}" from="${_escapeXml(_boundJid ?? _jid!)}">'
        '<received xmlns="urn:xmpp:receipts" id="$messageId"/>'
        '</message>';

    _send(stanza);
  }

  /// Reconnect using stored credentials
  Future<bool> reconnect() async {
    if (_jid == null || _password == null || _wsUrl == null) return false;
    return connect(
      jid: _jid!,
      password: _password!,
      wsUrl: _wsUrl!,
      resource: _resource,
    );
  }

  /// Clean up resources
  void dispose() {
    _intentionalDisconnect = true;
    _pingTimer?.cancel();
    _messageSub?.cancel();
    _connectionSub?.cancel();
    _socket?.close(1000, 'Disposing');
    _messageController.close();
    _presenceController.close();
    _stateController.close();
    _receiptController.close();
  }

  // ─── Private methods ───────────────────────────────────────────────────

  void _setState(NxConnectionState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void _send(String data) {
    if (_socket == null) {
      log('⚠️ NxSocket: Cannot send, socket is null');
      return;
    }
    try {
      _socket!.send(data);
    } catch (e) {
      log('⚠️ NxSocket: Cannot send: ${e.toString()}');
    }
  }

  void _sendStreamOpen() {
    _send('<open xmlns="urn:ietf:params:xml:ns:xmpp-framing" '
        'to="$_domain" '
        'version="1.0"/>');
  }

  void _onData(dynamic data) {
    final text = data.toString();
    log(
      '📨 NxSocket raw: ${text.length > 2000 ? '${text.substring(0, 2000)}...' : text}',
    );

    if (text.contains('<open ') || text.contains('<stream:stream')) {
      _streamOpened = true;
      _setState(NxConnectionState.connected);
      return;
    }

    if (text.contains('</stream:stream') || text.contains('<close ')) {
      _streamOpened = false;
      _setState(NxConnectionState.disconnected);
      return;
    }

    if (text.contains('<stream:error') || text.contains('stream:error>')) {
      _intentionalDisconnect = true;
      _pingTimer?.cancel();
      _setState(NxConnectionState.failed);
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(false);
      }
      _socket?.close(1001, 'Stream error');
      return;
    }

    if (text.contains('<stream:features') || text.contains('<features ')) {
      _handleFeatures(text);
      return;
    }

    if (text.contains('<success ') || text.contains('<success>')) {
      _handleAuthSuccess();
      return;
    }

    if (text.contains('<failure ')) {
      _handleAuthFailure(text);
      return;
    }

    if (text.contains('<iq ')) {
      _handleIq(text);
      return;
    }

    if (text.contains('<message ')) {
      _handleMessage(text);
      return;
    }

    if (text.contains('<presence ')) {
      _handlePresence(text);
      return;
    }
  }

  void _onError(dynamic error) {
    log('❌ NxSocket: WebSocket error: $error');
    _setState(NxConnectionState.failed);
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete(false);
    }
  }

  void _handleFeatures(String xml) {
    if (_state == NxConnectionState.authenticated) {
      _bindResource();
      return;
    }

    if (xml.contains('PLAIN')) {
      _setState(NxConnectionState.authenticating);
      _authenticatePlain();
    } else if (xml.contains('<bind')) {
      _setState(NxConnectionState.authenticating);
      _bindResource();
    } else {
      _setState(NxConnectionState.authenticating);
      _authenticatePlain();
    }
  }

  void _authenticatePlain() {
    final username = _jid!.split('@')[0];
    final authString = '\u0000$username\u0000$_password';
    final base64Auth = base64.encode(utf8.encode(authString));

    _send(
      '<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" '
      'mechanism="PLAIN">$base64Auth</auth>',
    );
  }

  void _handleAuthSuccess() {
    _setState(NxConnectionState.authenticated);
    _sendStreamOpen();
  }

  void _handleAuthFailure(String xml) {
    log('❌ Authentication failed');
    _pingTimer?.cancel();
    _setState(NxConnectionState.failed);
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete(false);
    }
    _socket?.close(3000, 'Auth failed');
  }

  void _bindResource() {
    final resource = _resource?.isNotEmpty == true
        ? _resource
        : 'nxmsg_${Random().nextInt(9999)}';
    _send(
      '<iq type="set" id="bind_1">'
      '<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind">'
      '<resource>$resource</resource>'
      '</bind></iq>',
    );
  }

  void _handleIq(String xml) {
    if (xml.contains('bind') && xml.contains('<jid>')) {
      final jidMatch = RegExp(r'<jid>([^<]+)</jid>').firstMatch(xml);
      if (jidMatch != null) {
        _boundJid = jidMatch.group(1);
        _startSession();
      }
    } else if (xml.contains('session') || xml.contains('result')) {
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _setState(NxConnectionState.authenticated);
        _authCompleter!.complete(true);
        sendPresence();
      }
    }
  }

  void _startSession() {
    _send(
      '<iq type="set" id="session_1">'
      '<session xmlns="urn:ietf:params:xml:ns:xmpp-session"/>'
      '</iq>',
    );
  }

  void _handleMessage(String xml) {
    final typeMatch = RegExp(r'''type=['"]([^'"']*)['"]''').firstMatch(xml);
    final fromMatch = RegExp(r'''from=['"]([^'"']*)['"]''').firstMatch(xml);
    final toMatch = RegExp(r'''to=['"]([^'"']*)['"]''').firstMatch(xml);
    final idMatch = RegExp(r'''\sid=['"]([^'"']*)['"]''').firstMatch(xml);
    final bodyMatch = RegExp(r'<body[^>]*>([^<]*)</body>').firstMatch(xml);

    final type = typeMatch?.group(1);
    final from = fromMatch?.group(1);
    final to = toMatch?.group(1);
    final id = idMatch?.group(1);
    final body = bodyMatch?.group(1);

    if (type == 'error') return;

    // Check for delivery receipts
    if (xml.contains('urn:xmpp:receipts') && xml.contains('<received')) {
      final receivedIdMatch = RegExp(
        r'''id=['"]([^'"']*)['"]''',
      ).firstMatch(xml.split('<received')[1]);
      if (receivedIdMatch != null) {
        final receiptId = receivedIdMatch.group(1);
        if (!_receiptController.isClosed) {
          _receiptController.add({
            'type': 'delivery',
            'from': from,
            'message_id': receiptId,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }
      return;
    }

    // Check for chat state notifications (typing indicators)
    if (xml.contains('chatstates')) {
      String? chatState;
      for (final state in [
        'composing',
        'paused',
        'active',
        'inactive',
        'gone',
      ]) {
        if (xml.contains('<$state ')) {
          chatState = state;
          break;
        }
      }
      if (chatState != null && !_messageController.isClosed) {
        _messageController.add(
          NxMessage(
            id: id,
            from: from,
            to: to,
            body: null,
            type: 'chat_state_$chatState',
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
      // If there's also a body, fall through to send the message
      if (body == null || body.isEmpty) return;
    }

    if (body != null && body.isNotEmpty) {
      final message = NxMessage(
        id: id,
        from: from,
        to: to,
        body: _unescapeXml(body),
        type: type,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      if (!_messageController.isClosed) {
        _messageController.add(message);
      }
    }
  }

  void _handlePresence(String xml) {
    final fromMatch = RegExp(r'''from=['"]([^'"']*)['"]''').firstMatch(xml);
    final typeMatch = RegExp(r'''type=['"]([^'"']*)['"]''').firstMatch(xml);
    final showMatch = RegExp(r'<show>([^<]*)</show>').firstMatch(xml);

    final type = typeMatch?.group(1);
    final from = fromMatch?.group(1);

    // Auto-approve incoming presence subscription requests so that
    // presence flows bidirectionally without manual approval.
    if (type == 'subscribe' && from != null) {
      log('NxSocket: Auto-approving presence subscription from $from');
      sendPresenceSubscribed(from);
      // Also send a subscription request back so we receive their
      // presence too (mutual subscription).
      sendPresenceSubscription(from);
      // Send our current presence directly to them so they see us
      // online immediately.
      sendDirectedPresence(from);
    }

    final presence = NxPresence.fromXmpp(
      from,
      type,
      showMatch?.group(1),
    );

    if (!_presenceController.isClosed) {
      _presenceController.add(presence);
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isAuthenticated) {
        _send(
          '<iq type="get" id="ping_${DateTime.now().millisecondsSinceEpoch}">'
          '<ping xmlns="urn:xmpp:ping"/></iq>',
        );
      }
    });
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _unescapeXml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}
