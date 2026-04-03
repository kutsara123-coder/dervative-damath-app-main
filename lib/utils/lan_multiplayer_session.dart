import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum LanSessionStatus {
  waitingForOpponent,
  connecting,
  connected,
  disconnected,
}

class LanMultiplayerSession {
  final bool isHost;
  final int localPlayerNumber;
  final String localPlayerName;
  final int port;
  final List<String> localAddresses;
  final String? hostAddress;

  ServerSocket? _serverSocket;
  Socket? _socket;
  StreamSubscription<String>? _socketSubscription;
  StreamSubscription<Socket>? _serverSubscription;
  final StreamController<Map<String, dynamic>> _messages =
      StreamController<Map<String, dynamic>>.broadcast();

  LanSessionStatus status;
  String? remotePlayerName;
  Map<String, dynamic>? latestStateMessage;

  LanMultiplayerSession._({
    required this.isHost,
    required this.localPlayerNumber,
    required this.localPlayerName,
    required this.port,
    required this.localAddresses,
    required this.hostAddress,
    required this.status,
  });

  Stream<Map<String, dynamic>> get messages => _messages.stream;

  bool get isConnected =>
      status == LanSessionStatus.connected && _socket != null;

  static Future<LanMultiplayerSession> host({
    required String playerName,
    int port = 4040,
  }) async {
    final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    final session = LanMultiplayerSession._(
      isHost: true,
      localPlayerNumber: 1,
      localPlayerName: playerName,
      port: port,
      localAddresses: await _resolveLocalIpv4Addresses(),
      hostAddress: null,
      status: LanSessionStatus.waitingForOpponent,
    );

    session._serverSocket = serverSocket;
    session._serverSubscription = serverSocket.listen(session._handleSocket);

    return session;
  }

  static Future<LanMultiplayerSession> join({
    required String playerName,
    required String hostAddress,
    int port = 4040,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final socket = await Socket.connect(hostAddress, port, timeout: timeout);

    final session = LanMultiplayerSession._(
      isHost: false,
      localPlayerNumber: 2,
      localPlayerName: playerName,
      port: port,
      localAddresses: const [],
      hostAddress: hostAddress,
      status: LanSessionStatus.connecting,
    );

    await session._attachSocket(socket);
    await session.sendJson({'type': 'join', 'playerName': playerName});

    return session;
  }

  Future<void> sendJson(Map<String, dynamic> message) async {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    socket.write('${jsonEncode(message)}\n');
    await socket.flush();
  }

  Future<void> close() async {
    status = LanSessionStatus.disconnected;
    await _socketSubscription?.cancel();
    await _serverSubscription?.cancel();
    await _socket?.close();
    await _serverSocket?.close();
    await _messages.close();
  }

  void _handleSocket(Socket socket) {
    if (_socket != null) {
      socket.write(
        '${jsonEncode({'type': 'error', 'message': 'A guest is already connected.'})}\n',
      );
      socket.flush();
      socket.destroy();
      return;
    }

    unawaited(_attachSocket(socket));
  }

  Future<void> _attachSocket(Socket socket) async {
    _socket = socket;
    status = LanSessionStatus.connected;

    await _emit({'type': 'connection_status', 'status': 'connected'});

    _socketSubscription = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _handleLine,
          onDone: _handleSocketClosed,
          onError: (Object error) {
            _emit({
              'type': 'connection_status',
              'status': 'error',
              'message': error.toString(),
            });
          },
          cancelOnError: false,
        );
  }

  void _handleLine(String line) {
    if (line.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        return;
      }

      final message = Map<String, dynamic>.from(decoded);
      if (message['type'] == 'join') {
        remotePlayerName = message['playerName'] as String?;
      }

      if (message['type'] == 'state') {
        latestStateMessage = Map<String, dynamic>.from(message);
        final payload = message['payload'];
        if (payload is Map) {
          final player1Name = payload['player1Name'] as String?;
          final player2Name = payload['player2Name'] as String?;
          remotePlayerName = localPlayerNumber == 1 ? player2Name : player1Name;
        }
      }

      _emit(message);
    } catch (error) {
      _emit({
        'type': 'connection_status',
        'status': 'error',
        'message': 'Failed to decode message: $error',
      });
    }
  }

  void _handleSocketClosed() {
    status = LanSessionStatus.disconnected;
    _emit({
      'type': 'connection_status',
      'status': 'disconnected',
      'message': 'The other phone disconnected.',
    });
  }

  Future<void> _emit(Map<String, dynamic> message) async {
    if (_messages.isClosed) {
      return;
    }

    _messages.add(message);
  }

  static Future<List<String>> _resolveLocalIpv4Addresses() async {
    try {
      final discovered = <String>{};
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final raw = address.address;
          if (raw.startsWith('169.254.')) {
            continue;
          }
          discovered.add(raw);
        }
      }

      return discovered.toList()..sort();
    } catch (_) {
      return const <String>[];
    }
  }
}
