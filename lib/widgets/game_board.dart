import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chip_model.dart';
import '../models/player_model.dart';
import '../utils/ai_opponent.dart';
import '../utils/dexter_engine.dart';
import '../utils/dexter_voice_service.dart';
import '../utils/game_logic.dart';
import '../utils/lan_game_sync.dart';
import '../utils/lan_multiplayer_session.dart';
import '../utils/operations_layout.dart';
import '../utils/sound_service.dart';
import 'chip_widget.dart';
import 'draggable_piece.dart';
import 'move_history_modal.dart';

class GameBoard extends StatefulWidget {
  final String mode; // "PvP" or "PvC"
  final bool useGameTimer; // Whether to enable the 20-minute game timer
  final bool useMoveTimer; // Whether to enable the 2-minute move timer
  final String? difficulty; // "easy", "medium", "hard" for PvC
  final int startingPlayer; // 1 = human/player 1, 2 = opponent/computer
  final String player1Name;
  final String player2Name;
  final LanMultiplayerSession? lanSession;

  const GameBoard({
    super.key,
    required this.mode,
    this.useGameTimer = true,
    this.useMoveTimer = true,
    this.difficulty,
    this.startingPlayer = 1,
    this.player1Name = 'Player 1',
    this.player2Name = 'Player 2',
    this.lanSession,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

enum _PauseAction { resume, restart, menu }

class _BoardGeometry {
  final double cellSize;
  final double tileMargin;
  final double labelWidth;
  final double axisHeight;
  final double outerBoardPadding;
  final double innerBoardPadding;

  const _BoardGeometry({
    required this.cellSize,
    required this.tileMargin,
    required this.labelWidth,
    required this.axisHeight,
    required this.outerBoardPadding,
    required this.innerBoardPadding,
  });

  double get slotSize => cellSize + (tileMargin * 2);
  double get chipSize => cellSize * 1.08;
  double get boardPixels => slotSize * 8;
  double get innerWidth => labelWidth + boardPixels;
  double get innerHeight => boardPixels + axisHeight;
}

class _ChipSnapshot {
  final int id;
  final int owner;
  final int x;
  final int y;
  final bool isDama;
  final Map<int, int> terms;

  const _ChipSnapshot({
    required this.id,
    required this.owner,
    required this.x,
    required this.y,
    required this.isDama,
    required this.terms,
  });

  factory _ChipSnapshot.fromChip(ChipModel chip) {
    return _ChipSnapshot(
      id: chip.id,
      owner: chip.owner,
      x: chip.x,
      y: chip.y,
      isDama: chip.isDama,
      terms: Map<int, int>.from(chip.terms),
    );
  }

  ChipModel toChipModel() {
    return ChipModel(
      owner: owner,
      id: id,
      x: x,
      y: y,
      isDama: isDama,
      terms: Map<int, int>.from(terms),
    );
  }
}

class _CapturedGhostChip {
  final int batchId;
  final _ChipSnapshot snapshot;

  const _CapturedGhostChip({required this.batchId, required this.snapshot});
}

class _GameBoardState extends State<GameBoard> {
  static const List<String> _dexterIntroLines = [
    'I am Dexter, the engine on the red side. Many call me unbeatable. You may test that rumor yourself.',
    'Dexter online. I do not rely on luck. I reduce this board to numbers.',
    'You are facing Dexter now. I have already started counting your mistakes.',
  ];
  static const List<String> _dexterMoveLines = [
    'Your turn. Try to make it matter.',
    'I prefer precise moves. That was one.',
    'The board is narrowing. You should feel that.',
    'I have made my choice. Now make yours.',
  ];
  static const List<String> _dexterCaptureLines = [
    'That piece was already mine.',
    'You left me the cleanest capture.',
    'I saw that exchange long before you did.',
  ];
  static const List<String> _dexterPromotionLines = [
    'A Dama for me. This board just tilted further my way.',
    'Promotion complete. That should complicate your plans.',
    'You let Dexter grow stronger. Bold decision.',
  ];
  static const List<String> _dexterSlowTurnLines = [
    'Still thinking? Sensible.',
    'I finished calculating your position a while ago.',
    'Take your time. Pressure reveals everything eventually.',
  ];
  static const List<String> _dexterPressureLines = [
    'The clock is doing more work than your pieces.',
    'Time is almost out. My evaluation is not.',
    'Interesting. You need the full clock for this one.',
  ];
  static const List<String> _dexterTimeoutLines = [
    'The clock moved for you. Merciless.',
    'Time made your move. I will accept the charity.',
    'Even the timer refused to wait for you.',
  ];
  static const List<String> _dexterWinLines = [
    'Expected. I told you I calculate endings.',
    'Dexter wins. The board behaved exactly as predicted.',
    'Another proof that calculation beats hope.',
  ];
  static const List<String> _dexterLossLines = [
    'Well played. That result will bother me for quite some time.',
    'You found the answer. Enjoy it.',
    'Impressive. I will remember this one.',
  ];
  static const List<String> _dexterDrawLines = [
    'A draw. Acceptable, though not ideal.',
    'You escaped with equality. For now.',
  ];

  late GameLogic gameLogic;
  late List<ChipModel> chips;
  ChipModel? selectedChip;
  int currentPlayer = 1; // 1 = blue, 2 = red
  double player1Score = 0; // Player 1 (blue) score
  double player2Score = 0; // Player 2 (red) score
  int player1Captured = 0; // Number of pieces Player 1 has captured
  int player2Captured = 0; // Number of pieces Player 2 has captured
  bool isGameOver = false;
  String? winnerMessage;
  bool mustContinueCapturing =
      false; // Track if player must continue chain capture
  bool isCaptureAvailable =
      false; // Track if any capture is available (must capture rule)
  bool isAIThinking = false; // Track if AI is thinking

  // Track previous counts for sound triggers
  int _previousPlayer1Chips = 12;
  int _previousPlayer2Chips = 12;
  int _previousDamaCount = 0;
  bool _moveMade = false; // Track if a move was made (for move sound)

  // Player models for PlayerInfoCard
  late PlayerModel player1;
  late PlayerModel player2;
  late String _player1DisplayName;
  late String _player2DisplayName;

  // AI Opponent (initialized when mode is PvC)
  AIOpponent? aiOpponent;
  DexterEngine? dexterEngine;

  // Turn timer variables
  Timer? _turnTimer;
  int _remainingSeconds = 120; // Remaining time for current turn
  int _remainingGameSeconds = 1200; // Remaining time for the whole match
  static const int turnTimeLimit = 120; // 2 minutes per turn
  static const int totalGameTimeLimit = 1200; // 20 minutes per match

  static const Duration _chipSlideDuration = Duration(milliseconds: 280);
  static const Duration _boardFlipDelay = Duration(milliseconds: 320);

  final operations = getOperationsBoard(); // 8x8 String grid

  bool _isPaused = false;
  bool _isBoardPeekActive = false;
  int _boardPerspectivePlayer = 1;
  int _boardPerspectiveTicket = 0;
  int _aiPauseTicket = 0;
  final math.Random _rng = math.Random();
  Timer? _autoMoveToastTimer;
  String? _autoMoveToastMessage;
  Timer? _dexterDialogueTimer;
  Timer? _dexterIntroTimer;
  String? _dexterDialogueMessage;
  bool _isDexterIntroActive = false;
  bool _dexterResultLinePlayed = false;
  final Set<int> _dexterSlowTurnMilestones = <int>{};
  bool _gameOverDialogVisible = false;
  int _ghostBatchId = 0;
  List<_CapturedGhostChip> _capturedGhosts = [];
  bool _useGameTimerEnabled = true;
  bool _useMoveTimerEnabled = true;
  bool _lanReady = false;
  bool _lanSessionClosed = false;
  bool _lanDisconnectNoticeShown = false;
  String? _lanStatusMessage;
  StreamSubscription<Map<String, dynamic>>? _lanMessageSubscription;

  bool get _isLanMode => widget.lanSession != null || widget.mode == 'LAN';
  bool get _isComputerMode => widget.mode == 'PvC' || widget.mode == 'PvD';
  bool get _isDexterMode => widget.mode == 'PvD';
  bool get _isSharedDevicePvp => widget.mode == 'PvP' && !_isLanMode;
  bool get _isLanHost => widget.lanSession?.isHost ?? false;
  bool get _isLanGuest => _isLanMode && !_isLanHost;
  int get _localPlayerNumber =>
      _isLanMode ? widget.lanSession!.localPlayerNumber : currentPlayer;
  bool get _shouldRunLocalTimer =>
      (_useGameTimerEnabled || _useMoveTimerEnabled) &&
      (!_isLanMode || _isLanHost);
  bool get _isCaptureTimerSuspended =>
      _useMoveTimerEnabled &&
      !isGameOver &&
      (gameLogic.mustContinueCapturing || gameLogic.isCaptureAvailable);
  bool get _isBoardFlippedForLocalView => _isLanMode
      ? _localPlayerNumber == 2
      : _isSharedDevicePvp && _boardPerspectivePlayer == 2;

  @override
  void initState() {
    super.initState();
    // Initialize game logic
    gameLogic = GameLogic();
    chips = gameLogic.chips;
    _useGameTimerEnabled = widget.useGameTimer;
    _useMoveTimerEnabled = widget.useMoveTimer;
    _boardPerspectivePlayer = widget.startingPlayer;
    _player1DisplayName = widget.player1Name;
    _player2DisplayName = widget.player2Name;

    if (_isComputerMode &&
        (_player2DisplayName.trim().isEmpty ||
            _player2DisplayName == 'Player 2')) {
      _player2DisplayName = _isDexterMode
          ? DexterEngine.defaultName
          : 'Computer';
    }

    if (_isLanMode) {
      final lanSession = widget.lanSession!;
      _player1DisplayName = lanSession.localPlayerNumber == 1
          ? lanSession.localPlayerName
          : widget.player1Name;
      _player2DisplayName = lanSession.localPlayerNumber == 2
          ? lanSession.localPlayerName
          : (lanSession.remotePlayerName ?? widget.player2Name);
      _lanStatusMessage = _isLanHost
          ? 'Waiting for another phone to join...'
          : 'Connecting to ${lanSession.hostAddress ?? 'host'}...';
      _listenToLanSession();
    }

    // Initialize AI if PvC mode
    if (_isComputerMode) {
      if (_isDexterMode) {
        dexterEngine = DexterEngine(gameLogic: gameLogic);
      } else {
        // Parse difficulty from widget parameter
        AIDifficulty aiDifficulty;
        switch (widget.difficulty) {
          case 'easy':
            aiDifficulty = AIDifficulty.easy;
            break;
          case 'hard':
            aiDifficulty = AIDifficulty.hard;
            break;
          case 'medium':
          default:
            aiDifficulty = AIDifficulty.medium;
            break;
        }

        aiOpponent = AIOpponent(difficulty: aiDifficulty, gameLogic: gameLogic);
      }
    }

    // Initialize player models
    player1 = PlayerModel(
      name: _player1DisplayName,
      color: PlayerColor.blue,
      score: 0,
    );
    player2 = PlayerModel(
      name: _player2DisplayName,
      color: PlayerColor.red,
      score: 0,
      isAI: _isComputerMode,
    );

    if (_isLanGuest) {
      final cachedState = widget.lanSession?.latestStateMessage;
      final cachedPayload = cachedState == null ? null : cachedState['payload'];
      if (cachedPayload is Map) {
        _applyLanSnapshot(Map<String, dynamic>.from(cachedPayload));
      }
    }

    final deferMatchStartForDexterIntro = _isDexterMode && !_isLanMode;

    // Start the turn timer only if this device should control it.
    if (_shouldRunLocalTimer && !_isLanMode && !deferMatchStartForDexterIntro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          if (!mounted || isGameOver || _isPaused) {
            return;
          }
          _startTimer();
        });
      });
    }

    if (_isComputerMode && widget.startingPlayer == 2) {
      gameLogic.currentPlayer = 2;
      currentPlayer = 2;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshState();
        if (deferMatchStartForDexterIntro) {
          _beginDexterMatchIntro();
          return;
        }
        _triggerAIMove();
      });
    } else if (deferMatchStartForDexterIntro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshState();
        _beginDexterMatchIntro();
      });
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _autoMoveToastTimer?.cancel();
    _dexterDialogueTimer?.cancel();
    _dexterIntroTimer?.cancel();
    unawaited(DexterVoiceService.instance.stop());
    _lanMessageSubscription?.cancel();
    unawaited(_closeLanSession());
    super.dispose();
  }

  Future<void> _closeLanSession() async {
    if (!_isLanMode || _lanSessionClosed) {
      return;
    }

    _lanSessionClosed = true;
    await widget.lanSession?.close();
  }

  void _listenToLanSession() {
    final lanSession = widget.lanSession;
    if (lanSession == null) {
      return;
    }

    _lanMessageSubscription = lanSession.messages.listen(_handleLanMessage);
  }

  Future<void> _handleLanMessage(Map<String, dynamic> message) async {
    final type = message['type'] as String? ?? '';

    switch (type) {
      case 'join':
        if (_isLanHost) {
          await _handleLanGuestJoined(message);
        }
        break;
      case 'move_request':
        if (_isLanHost) {
          await _handleLanMoveRequest(message);
        }
        break;
      case 'state':
        if (_isLanGuest) {
          _applyLanSnapshot(
            Map<String, dynamic>.from(
              (message['payload'] as Map?) ?? const <String, dynamic>{},
            ),
          );
        }
        break;
      case 'leave':
        if (_isLanHost) {
          await _handleLanSessionEnded('The other player left the match.');
        }
        break;
      case 'session_end':
        await _handleLanSessionEnded(
          message['message'] as String? ?? 'The match has ended.',
        );
        break;
      case 'connection_status':
        final status = message['status'] as String? ?? '';
        if (status == 'disconnected') {
          await _handleLanSessionEnded(
            message['message'] as String? ?? 'The other phone disconnected.',
          );
        } else if (status == 'connected' && mounted && _isLanGuest) {
          setState(() {
            _lanStatusMessage = 'Connected. Waiting for the host to start...';
          });
        }
        break;
      case 'error':
        final payload = message['payload'];
        if (_isLanGuest && payload is Map) {
          _applyLanSnapshot(Map<String, dynamic>.from(payload));
        }
        _showTransientMessage(
          message['message'] as String? ?? 'Something went wrong.',
        );
        break;
    }
  }

  Future<void> _handleLanGuestJoined(Map<String, dynamic> message) async {
    final remoteName = (message['playerName'] as String?)?.trim();

    if (mounted) {
      setState(() {
        _lanReady = true;
        _lanStatusMessage = null;
        _player2DisplayName = (remoteName == null || remoteName.isEmpty)
            ? 'Player 2'
            : remoteName;
        _syncPlayerModels();
      });
    }

    if (_shouldRunLocalTimer &&
        !_isPaused &&
        !isGameOver &&
        _turnTimer == null) {
      _startTimer();
    }

    await _broadcastLanState();
  }

  Future<void> _handleLanMoveRequest(Map<String, dynamic> message) async {
    if (!_lanReady) {
      return;
    }

    final fromX = message['fromX'] as int?;
    final fromY = message['fromY'] as int?;
    final toX = message['toX'] as int?;
    final toY = message['toY'] as int?;

    if (fromX == null || fromY == null || toX == null || toY == null) {
      await widget.lanSession?.sendJson({
        'type': 'error',
        'message': 'Received an incomplete move from the guest phone.',
        'payload': _lanSnapshotPayload(),
      });
      return;
    }

    if (gameLogic.currentPlayer != 2) {
      await widget.lanSession?.sendJson({
        'type': 'error',
        'message': 'It is not Player 2\'s turn.',
        'payload': _lanSnapshotPayload(),
      });
      return;
    }

    final previousPlayer = currentPlayer;
    final previousBoard = _snapshotBoard();
    final previousMoveCount = gameLogic.history.length;

    gameLogic.executeMove(Move(fromX: fromX, fromY: fromY, toX: toX, toY: toY));

    _moveMade = gameLogic.history.length > previousMoveCount;
    _syncCapturedCounts();
    _refreshState(previousBoard: previousBoard);

    if (currentPlayer != previousPlayer &&
        !mustContinueCapturing &&
        _shouldRunLocalTimer) {
      _startTimer();
    }

    await _broadcastLanState();
  }

  void _applyLanSnapshot(Map<String, dynamic> payload) {
    final previousBoard = _snapshotBoard();
    LanGameSync.apply(gameLogic: gameLogic, payload: payload);

    _useGameTimerEnabled =
        payload['useGameTimer'] as bool? ?? _useGameTimerEnabled;
    _useMoveTimerEnabled =
        payload['useMoveTimer'] as bool? ?? _useMoveTimerEnabled;
    _remainingSeconds =
        payload['remainingSeconds'] as int? ?? _remainingSeconds;
    _remainingGameSeconds =
        payload['remainingGameSeconds'] as int? ?? _remainingGameSeconds;
    _isPaused = payload['isPaused'] as bool? ?? false;
    _player1DisplayName =
        payload['player1Name'] as String? ?? _player1DisplayName;
    _player2DisplayName =
        payload['player2Name'] as String? ?? _player2DisplayName;
    _lanReady = true;
    _lanStatusMessage = null;
    _syncCapturedCounts();
    _syncPlayerModels();

    if (!gameLogic.isGameOver) {
      winnerMessage = null;
      _gameOverDialogVisible = false;
    }

    _refreshState(previousBoard: previousBoard);
  }

  Future<void> _broadcastLanState() async {
    if (!_isLanHost || !_lanReady) {
      return;
    }

    await widget.lanSession?.sendJson({
      'type': 'state',
      'payload': _lanSnapshotPayload(),
    });
  }

  Map<String, dynamic> _lanSnapshotPayload() {
    return LanGameSync.encode(
      gameLogic: gameLogic,
      remainingSeconds: _remainingSeconds,
      remainingGameSeconds: _remainingGameSeconds,
      isPaused: _isPaused,
      player1Name: _player1DisplayName,
      player2Name: _player2DisplayName,
      useGameTimer: _useGameTimerEnabled,
      useMoveTimer: _useMoveTimerEnabled,
    );
  }

  Future<void> _handleLanSessionEnded(String message) async {
    if (!_isLanMode || _lanDisconnectNoticeShown || !mounted) {
      return;
    }

    _lanDisconnectNoticeShown = true;
    _stopTimer();

    setState(() {
      _lanReady = false;
      _lanStatusMessage = message;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Match Ended'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    await _returnToMenu(notifyPeer: false);
  }

  void _showTransientMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _syncCapturedCounts() {
    player1Captured = 12 - gameLogic.getChipCount(1);
    player2Captured = 12 - gameLogic.getChipCount(2);
  }

  void _syncPlayerModels() {
    player1 = player1.copyWith(name: _player1DisplayName, score: player1Score);
    player2 = player2.copyWith(
      name: _player2DisplayName,
      score: player2Score,
      isAI: _isComputerMode,
    );
  }

  String _pickDexterLine(List<String> lines) {
    return lines[_rng.nextInt(lines.length)];
  }

  Duration _dexterBannerDurationFor(
    String message, {
    Duration minimum = const Duration(milliseconds: 3000),
  }) {
    final calculatedMs = 2000 + (message.length * 34);
    return Duration(
      milliseconds: math.max(
        minimum.inMilliseconds,
        math.min(calculatedMs, 5200),
      ),
    );
  }

  void _showDexterDialogue(
    String message, {
    Duration? duration,
    bool speak = true,
  }) {
    if (!_isDexterMode || !mounted) {
      return;
    }

    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return;
    }

    final visibleDuration = duration ?? _dexterBannerDurationFor(trimmedMessage);
    _dexterDialogueTimer?.cancel();

    setState(() {
      _dexterDialogueMessage = trimmedMessage;
    });

    if (speak) {
      unawaited(DexterVoiceService.instance.speak(trimmedMessage));
    }

    _dexterDialogueTimer = Timer(visibleDuration, () {
      if (!mounted || _dexterDialogueMessage != trimmedMessage) {
        return;
      }

      setState(() {
        _dexterDialogueMessage = null;
      });
    });
  }

  void _clearDexterDialogue({bool stopVoice = false}) {
    _dexterDialogueTimer?.cancel();
    _dexterIntroTimer?.cancel();

    if (stopVoice) {
      unawaited(DexterVoiceService.instance.stop());
    }

    if (!mounted) {
      _dexterDialogueMessage = null;
      return;
    }

    if (_dexterDialogueMessage == null) {
      return;
    }

    setState(() {
      _dexterDialogueMessage = null;
    });
  }

  void _beginDexterMatchIntro() {
    if (!_isDexterMode || isGameOver) {
      return;
    }

    _stopTimer();
    _dexterIntroTimer?.cancel();
    _dexterSlowTurnMilestones.clear();
    _dexterResultLinePlayed = false;

    if (mounted) {
      setState(() {
        _isDexterIntroActive = true;
      });
    } else {
      _isDexterIntroActive = true;
    }

    final introLine = _pickDexterLine(_dexterIntroLines);
    final introDuration = _dexterBannerDurationFor(
      introLine,
      minimum: const Duration(milliseconds: 4200),
    );

    _showDexterDialogue(introLine, duration: introDuration);

    _dexterIntroTimer = Timer(
      introDuration + const Duration(milliseconds: 220),
      _completeDexterMatchIntro,
    );
  }

  void _completeDexterMatchIntro() {
    if (!_isDexterMode || !mounted) {
      return;
    }

    setState(() {
      _isDexterIntroActive = false;
    });

    if (isGameOver || _isPaused) {
      return;
    }

    if (gameLogic.currentPlayer == 2) {
      _triggerAIMove();
      return;
    }

    if (_shouldRunLocalTimer) {
      _startTimer();
    }
  }

  void _maybeTriggerDexterSlowTurnLine() {
    if (!_isDexterMode ||
        _isDexterIntroActive ||
        !_useMoveTimerEnabled ||
        gameLogic.currentPlayer != 1 ||
        isGameOver ||
        _isPaused) {
      return;
    }

    if (_remainingSeconds == 60 && _dexterSlowTurnMilestones.add(60)) {
      _showDexterDialogue(
        _pickDexterLine(_dexterSlowTurnLines),
        duration: const Duration(milliseconds: 3200),
      );
      return;
    }

    if (_remainingSeconds == 20 && _dexterSlowTurnMilestones.add(20)) {
      _showDexterDialogue(
        _pickDexterLine(_dexterPressureLines),
        duration: const Duration(milliseconds: 3200),
      );
    }
  }

  void _maybeAnnounceDexterMove(
    Move move,
    Map<int, _ChipSnapshot> previousBoard,
  ) {
    if (!_isDexterMode ||
        _isPaused ||
        isGameOver ||
        gameLogic.currentPlayer != 1 ||
        !mounted) {
      return;
    }

    final promotedToDama = _didMovePromoteToDama(move, previousBoard);
    String? line;

    if (promotedToDama) {
      line = _pickDexterLine(_dexterPromotionLines);
    } else if (move.isCapture) {
      line = _pickDexterLine(_dexterCaptureLines);
    } else if (_rng.nextDouble() < 0.55) {
      line = _pickDexterLine(_dexterMoveLines);
    }

    if (line != null) {
      _showDexterDialogue(line);
    }
  }

  void _maybeAnnounceDexterResult() {
    if (!_isDexterMode || !isGameOver || _dexterResultLinePlayed) {
      return;
    }

    _dexterResultLinePlayed = true;

    final winner = gameLogic.currentWinner;
    final line = winner == null
        ? _pickDexterLine(_dexterDrawLines)
        : winner.playerNumber == 2
        ? _pickDexterLine(_dexterWinLines)
        : _pickDexterLine(_dexterLossLines);

    _showDexterDialogue(
      line,
      duration: _dexterBannerDurationFor(
        line,
        minimum: const Duration(milliseconds: 3600),
      ),
    );
  }

  bool _didMovePromoteToDama(
    Move move,
    Map<int, _ChipSnapshot> previousBoard,
  ) {
    _ChipSnapshot? movingSnapshot;
    for (final snapshot in previousBoard.values) {
      if (snapshot.x == move.fromX && snapshot.y == move.fromY) {
        movingSnapshot = snapshot;
        break;
      }
    }

    if (movingSnapshot == null || movingSnapshot.isDama) {
      return false;
    }

    for (final chip in chips) {
      if (chip.id == movingSnapshot.id) {
        return chip.isDama;
      }
    }

    return false;
  }

  /// Start the turn timer - resets to full 2 minutes for each new turn
  void _startTimer({bool reset = true}) {
    _stopTimer();
    if (!_shouldRunLocalTimer) {
      return;
    }

    if (reset && _useMoveTimerEnabled) {
      _remainingSeconds = turnTimeLimit;
    }

    if (_isDexterMode && gameLogic.currentPlayer == 1 && reset) {
      _dexterSlowTurnMilestones.clear();
    }

    if (_isLanHost) {
      unawaited(_broadcastLanState());
    }

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isPaused) {
        timer.cancel();
        return;
      }

      final captureTimerSuspended = _isCaptureTimerSuspended;
      setState(() {
        if (_useGameTimerEnabled && _remainingGameSeconds > 0) {
          _remainingGameSeconds--;
        }
        if (_useMoveTimerEnabled &&
            !captureTimerSuspended &&
            _remainingSeconds > 0) {
          _remainingSeconds--;
        }
      });

      if (_isLanHost) {
        unawaited(_broadcastLanState());
      }

      // Play timer warning sound when timer is <= 10 seconds
      if (_useMoveTimerEnabled &&
          !captureTimerSuspended &&
          _remainingSeconds <= 10 &&
          _remainingSeconds > 0) {
        SoundService().playTimerWarning();
      }

      if (_isDexterMode && !captureTimerSuspended) {
        _maybeTriggerDexterSlowTurnLine();
      }

      if (_useGameTimerEnabled && _remainingGameSeconds <= 0) {
        _onGamePeriodExpired();
        return;
      }

      if (_useMoveTimerEnabled &&
          !captureTimerSuspended &&
          _remainingSeconds <= 0) {
        _onTurnTimeout();
      }
    });
  }

  /// Stop the turn timer
  void _stopTimer() {
    _turnTimer?.cancel();
    _turnTimer = null;
  }

  Map<int, _ChipSnapshot> _snapshotBoard() {
    return {for (final chip in chips) chip.id: _ChipSnapshot.fromChip(chip)};
  }

  bool get _isInteractionLocked {
    if (isGameOver || _isPaused || _isBoardPeekActive || _isDexterIntroActive) {
      return true;
    }

    if (_isLanMode) {
      return !_lanReady || gameLogic.currentPlayer != _localPlayerNumber;
    }

    return _isComputerMode && (gameLogic.currentPlayer == 2 || isAIThinking);
  }

  void _queueBoardPerspectiveSync(
    int player, {
    Duration delay = _boardFlipDelay,
    bool immediate = false,
  }) {
    if (!_isSharedDevicePvp) {
      return;
    }

    final ticket = ++_boardPerspectiveTicket;

    void applyPerspective() {
      if (!mounted || ticket != _boardPerspectiveTicket) {
        return;
      }

      if (_boardPerspectivePlayer != player) {
        setState(() {
          _boardPerspectivePlayer = player;
        });
      }
    }

    if (immediate) {
      applyPerspective();
      return;
    }

    Future.delayed(delay, applyPerspective);
  }

  void _addCapturedGhosts(Map<int, _ChipSnapshot>? previousBoard) {
    if (previousBoard == null || previousBoard.isEmpty) {
      return;
    }

    final remainingIds = gameLogic.chips.map((chip) => chip.id).toSet();
    final removedSnapshots = previousBoard.values
        .where((snapshot) => !remainingIds.contains(snapshot.id))
        .toList();

    if (removedSnapshots.isEmpty || !mounted) {
      return;
    }

    final batchId = ++_ghostBatchId;
    setState(() {
      _capturedGhosts = [
        ..._capturedGhosts,
        ...removedSnapshots.map(
          (snapshot) =>
              _CapturedGhostChip(batchId: batchId, snapshot: snapshot),
        ),
      ];
    });

    Future.delayed(_chipSlideDuration, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _capturedGhosts = _capturedGhosts
            .where((ghost) => ghost.batchId != batchId)
            .toList();
      });
    });
  }

  /// Handle turn timeout based on the timed rules.
  void _onTurnTimeout() {
    _stopTimer();

    SoundService().playTimeout();
    _aiPauseTicket++;
    isAIThinking = false;
    gameLogic.selectedChip = null;
    selectedChip = null;
    gameLogic.lastErrorMessage =
        '${_playerNameForNumber(currentPlayer)} ran out of move time.';

    _performTimeoutAutoMove();

    if (_isLanHost) {
      unawaited(_broadcastLanState());
    }
  }

  void _forceEndTurnFromTimeout() {
    gameLogic.currentPlayer = gameLogic.currentPlayer == 1 ? 2 : 1;
    gameLogic.selectedChip = null;
    gameLogic.captureChainDepth = 0;
    gameLogic.mustContinueCapture = false;
    gameLogic.currentChainChip = null;
  }

  void _performTimeoutAutoMove() {
    if (isGameOver || _isPaused) {
      return;
    }

    final previousPlayer = gameLogic.currentPlayer;
    final legalMoves = gameLogic.getLegalMovesForPlayer(previousPlayer);

    if (legalMoves.isEmpty) {
      _switchTurnWithTimer();
      return;
    }

    final previousBoard = _snapshotBoard();
    final previousMoveCount = gameLogic.history.length;
    final randomMove = legalMoves[_rng.nextInt(legalMoves.length)];

    gameLogic.executeMove(randomMove);

    if (gameLogic.history.length > previousMoveCount) {
      _moveMade = true;
    }

    _syncCapturedCounts();
    _refreshState(previousBoard: previousBoard);

    if (!isGameOver && gameLogic.currentPlayer == previousPlayer) {
      _forceEndTurnFromTimeout();
      _refreshState();
    }

    _showAutoMoveToast(previousPlayer);

    if (_isDexterMode && previousPlayer == 1 && !isGameOver) {
      _showDexterDialogue(
        _pickDexterLine(_dexterTimeoutLines),
        duration: const Duration(milliseconds: 3200),
      );
    }

    if (!isGameOver && _shouldRunLocalTimer) {
      _startTimer();
    }

    if (!isGameOver) {
      _queueBoardPerspectiveSync(gameLogic.currentPlayer);
    }

    if (_isComputerMode &&
        gameLogic.currentPlayer == 2 &&
        !mustContinueCapturing &&
        !isGameOver) {
      _triggerAIMove();
    }
  }

  void _showAutoMoveToast(int playerNumber) {
    if (!mounted) {
      return;
    }

    final playerName = _playerNameForNumber(playerNumber);
    _autoMoveToastTimer?.cancel();

    setState(() {
      _autoMoveToastMessage = "Time's up - $playerName auto-moved.";
    });

    _autoMoveToastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _autoMoveToastMessage = null;
      });
    });
  }

  void _onGamePeriodExpired() {
    _stopTimer();
    gameLogic.endGameByScore();
    _refreshState();

    if (_isLanHost) {
      unawaited(_broadcastLanState());
    }
  }

  /// Switch turn to opponent and start their timer
  void _switchTurnWithTimer() {
    gameLogic.currentPlayer = gameLogic.currentPlayer == 1 ? 2 : 1;

    _refreshState();
    _queueBoardPerspectiveSync(gameLogic.currentPlayer);

    // Start timer only if this device controls it.
    if (_shouldRunLocalTimer) {
      _startTimer();
    }

    // In PvC mode, if it's now AI's turn (player 2), trigger AI move
    if (_isComputerMode && gameLogic.currentPlayer == 2 && !isGameOver) {
      _triggerAIMove();
    }
  }

  /// Refreshes state from gameLogic
  void _refreshState({Map<int, _ChipSnapshot>? previousBoard}) {
    // Check for capture sound (when chip count decreases)
    final currentP1Chips = gameLogic.getChipCount(1);
    final currentP2Chips = gameLogic.getChipCount(2);
    final currentDamaCount =
        gameLogic.getDamaCount(1) + gameLogic.getDamaCount(2);

    // Detect captures
    if (currentP1Chips < _previousPlayer1Chips ||
        currentP2Chips < _previousPlayer2Chips) {
      SoundService().playCaptured();
    } else if (_moveMade && !isGameOver) {
      // No capture happened but a move was made - play move sound
      SoundService().playMove();
    }

    // Reset move flag after handling
    _moveMade = false;

    // Detect Dama promotion
    if (currentDamaCount > _previousDamaCount) {
      SoundService().playDama();
    }

    // Update previous counts
    _previousPlayer1Chips = currentP1Chips;
    _previousPlayer2Chips = currentP2Chips;
    _previousDamaCount = currentDamaCount;

    setState(() {
      chips = gameLogic.chips;
      currentPlayer = gameLogic.currentPlayer;
      player1Score = gameLogic.isGameOver
          ? gameLogic.getFinalScore(1)
          : gameLogic.player1Score;
      player2Score = gameLogic.isGameOver
          ? gameLogic.getFinalScore(2)
          : gameLogic.player2Score;
      selectedChip = gameLogic.selectedChip;
      isGameOver = gameLogic.isGameOver;
      mustContinueCapturing = gameLogic.mustContinueCapturing;
      isCaptureAvailable = gameLogic.isCaptureAvailable; // Must capture rule
      winnerMessage = null;

      // Update player models
      _syncCapturedCounts();
      _syncPlayerModels();

      // Check for winner
      if (isGameOver) {
        final winner = gameLogic.currentWinner;
        if (winner != null) {
          winnerMessage = '${_playerNameForNumber(winner.playerNumber)} Wins!';
        } else if (gameLogic.isDraw) {
          winnerMessage = 'Draw!';
        }
        if (!_gameOverDialogVisible) {
          // Play game over sound once when the result first appears.
          SoundService().playGameOver();
          // Stop the timer when game is over
          _stopTimer();
          _gameOverDialogVisible = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showGameOverDialog();
          });
        }
      }
    });

    if (!isGameOver) {
      _dexterResultLinePlayed = false;
    } else {
      _maybeAnnounceDexterResult();
    }

    _addCapturedGhosts(previousBoard);
  }

  bool isOccupied(int x, int y) => gameLogic.isOccupied(x, y);

  ChipModel? chipAt(int x, int y) {
    return gameLogic.chipAt(x, y);
  }

  bool isOpponent(ChipModel a, ChipModel b) => gameLogic.isOpponent(a, b);

  /// Check if a chip can move (considering must capture rule)
  bool _canChipMove(ChipModel chip) {
    // If must continue capturing (chain capture), only the chain chip can move
    if (mustContinueCapturing) {
      return gameLogic.currentChainChipModel != null &&
          gameLogic.currentChainChipModel!.x == chip.x &&
          gameLogic.currentChainChipModel!.y == chip.y;
    }
    // If capture is available, only chips that can capture can move
    if (isCaptureAvailable) {
      return gameLogic.chipCanCapture(chip);
    }
    // Otherwise, chip can move
    return true;
  }

  /// Build chip with glow effect for chips that can capture
  Widget _buildChipWithGlow(ChipModel chip, double chipSize) {
    final bool canCapture = gameLogic.chipCanCapture(chip);
    final bool shouldGlow =
        isCaptureAvailable &&
        !mustContinueCapturing &&
        canCapture &&
        chip.owner == currentPlayer;

    return Container(
      decoration: shouldGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7CFFB0).withValues(alpha: 0.82),
                  blurRadius: chipSize * 0.30,
                  spreadRadius: chipSize * 0.02,
                ),
              ],
            )
          : null,
      child: DraggablePiece(
        chip: chip,
        isDraggable:
            chip.owner == currentPlayer &&
            !_isInteractionLocked &&
            _canChipMove(chip),
        size: chipSize,
      ),
    );
  }

  /// Check if a tile is a valid drop target
  bool _isValidDropTarget(int x, int y, {ChipModel? chip}) {
    final chipToCheck = chip ?? selectedChip;
    if (chipToCheck == null) return false;

    // Can't drop on occupied tiles
    if (isOccupied(x, y)) return false;

    // Check if it's a valid move for the selected chip using public API
    final validMoves = gameLogic.getValidMoves(chipToCheck);
    return validMoves.any((move) => move.toX == x && move.toY == y);
  }

  /// Handle chip drop
  void _onChipDropped(ChipModel chip, int toX, int toY) {
    if (_isInteractionLocked) return;
    // Only allow dropping if it's the chip's turn and it's a valid move
    if (chip.owner != currentPlayer) return;
    if (!_isValidDropTarget(toX, toY, chip: chip)) return;

    // Select the chip and make the move
    selectedChip = chip;
    gameLogic.selectedChip = chip;
    _moveMade = true; // Mark that a move was attempted
    onTileTap(toX, toY);
  }

  void onTileTap(int x, int y) {
    if (_isInteractionLocked) {
      return;
    }

    final moveSourceChip = selectedChip;
    final moveFromX = moveSourceChip?.x;
    final moveFromY = moveSourceChip?.y;

    // Save the current player BEFORE making the move
    final previousPlayer = currentPlayer;
    final previousBoard = _snapshotBoard();

    // Check if a valid move was made by comparing move history
    // The gameLogic.onTileTap will only make a move if it's valid
    final previousMoveCount = gameLogic.history.length;

    // Delegate to game logic
    gameLogic.onTileTap(x, y);

    // If move history increased, a valid move was made - set flag for sound
    // This must be done BEFORE _refreshState() because it checks and resets this flag
    final validMoveMade = gameLogic.history.length > previousMoveCount;
    if (validMoveMade) {
      _moveMade = true;
    }

    _syncCapturedCounts();

    // Refresh state from game logic - this plays the move sound if _moveMade is true
    _refreshState(previousBoard: previousBoard);

    // Restart timer after a valid move (only if turn switched and timer is enabled)
    // Check if player changed (turn was switched)
    if (currentPlayer != previousPlayer && !mustContinueCapturing) {
      _queueBoardPerspectiveSync(currentPlayer);
      if (_shouldRunLocalTimer) {
        _startTimer();
      }
    }

    if (validMoveMade &&
        _isLanGuest &&
        moveFromX != null &&
        moveFromY != null) {
      unawaited(
        widget.lanSession?.sendJson({
              'type': 'move_request',
              'fromX': moveFromX,
              'fromY': moveFromY,
              'toX': x,
              'toY': y,
            }) ??
            Future<void>.value(),
      );
    } else if (validMoveMade && _isLanHost) {
      unawaited(_broadcastLanState());
    }

    // Trigger AI move if it's PvC mode and now AI's turn
    // Use gameLogic.currentPlayer to check if it's AI's turn after the move
    // Only trigger if NOT must continue capturing (chain capture)
    if (_isComputerMode &&
        gameLogic.currentPlayer == 2 &&
        !mustContinueCapturing &&
        !isGameOver) {
      _triggerAIMove();
    }
  }

  /// Triggers AI move execution with a small delay for better UX
  void _triggerAIMove() async {
    if ((!_isDexterMode && aiOpponent == null) ||
        (_isDexterMode && dexterEngine == null) ||
        isGameOver ||
        _isPaused ||
        _isDexterIntroActive ||
        gameLogic.currentPlayer != 2) {
      return;
    }

    final pauseTicket = _aiPauseTicket;
    setState(() {
      isAIThinking = true;
    });

    final dexterThinkingBudget = _isDexterMode
        ? _recommendedDexterThinkingTime()
        : null;
    final delayMs = _isDexterMode
        ? 420
        : switch (widget.difficulty) {
            'easy' => 1400,
            'medium' => 2200,
            'hard' => 3200,
            _ => 1800,
          };
    await Future.delayed(Duration(milliseconds: delayMs));

    if (!mounted ||
        isGameOver ||
        _isPaused ||
        pauseTicket != _aiPauseTicket ||
        gameLogic.currentPlayer != 2) {
      if (mounted) {
        setState(() {
          isAIThinking = false;
        });
      }
      return;
    }

    // Get the best move from AI
    final move = _isDexterMode
        ? dexterEngine!.getBestMove(maxThinkingTime: dexterThinkingBudget)
        : aiOpponent!.getBestMove();

    if (move != null) {
      final previousBoard = _snapshotBoard();
      // Execute the AI move
      _moveMade = true; // Mark that AI made a move
      gameLogic.executeMove(move);

      _syncCapturedCounts();

      // Refresh state
      _refreshState(previousBoard: previousBoard);

      // Check if AI must continue capturing (chain capture)
      // If still AI's turn and must continue, trigger another move
      if (!isGameOver &&
          !_isPaused &&
          gameLogic.currentPlayer == 2 &&
          gameLogic.mustContinueCapturing) {
        // Continue with chain capture after a short delay
        await Future.delayed(const Duration(milliseconds: 600));
        if (!isGameOver && !_isPaused && pauseTicket == _aiPauseTicket) {
          _triggerAIMove();
        }
      }

      _maybeAnnounceDexterMove(move, previousBoard);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isAIThinking = false;
    });

    // Restart timer after AI move (if turn switched to human and timer is enabled)
    if (!isGameOver && gameLogic.currentPlayer == 1 && _shouldRunLocalTimer) {
      _startTimer();
    }

    if (!isGameOver && gameLogic.currentPlayer == 1) {
      _queueBoardPerspectiveSync(gameLogic.currentPlayer);
    }
  }

  Duration _recommendedDexterThinkingTime() {
    final pieceCount = gameLogic.chips.length;
    final legalMoves = gameLogic.getLegalMovesForPlayer(2);
    final hasCapture = legalMoves.any((move) => move.isCapture);

    if (pieceCount <= 8) {
      return const Duration(milliseconds: 8000);
    }

    if (pieceCount <= 12 || hasCapture || gameLogic.mustContinueCapturing) {
      return const Duration(milliseconds: 6000);
    }

    if (pieceCount <= 18) {
      return const Duration(milliseconds: 4200);
    }

    return const Duration(milliseconds: 3200);
  }

  /// Shows game over dialog
  void _showGameOverDialog() {
    if (!isGameOver || winnerMessage == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF4FBFF), Color(0xFFD7E8FF)],
              ),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Game Over',
                  style: TextStyle(
                    color: Color(0xFF1C3159),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  winnerMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF13345C),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _buildDialogButton(
                  label: 'View History',
                  color: const Color(0xFF5CB6FF),
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    _gameOverDialogVisible = false;
                    await _showMoveHistory(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildDialogButton(
                  label: _isLanGuest ? 'Back To Menu' : 'Play Again',
                  color: const Color(0xFF8BFF88),
                  onTap: () async {
                    Navigator.of(dialogContext).pop();
                    if (_isLanGuest) {
                      await _returnToMenu();
                      return;
                    }
                    _restartGame();
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _gameOverDialogVisible = false;
    });
  }

  void _restartGame() {
    _stopTimer();
    _aiPauseTicket++;
    _boardPerspectiveTicket++;
    _gameOverDialogVisible = false;
    _clearDexterDialogue(stopVoice: true);

    player1Captured = 0;
    player2Captured = 0;
    winnerMessage = null;
    _capturedGhosts = [];
    _isPaused = false;
    _isBoardPeekActive = false;
    _isDexterIntroActive = false;
    _dexterResultLinePlayed = false;
    _dexterSlowTurnMilestones.clear();
    _remainingSeconds = turnTimeLimit;
    _remainingGameSeconds = totalGameTimeLimit;

    gameLogic.reset();
    gameLogic.currentPlayer = widget.startingPlayer;
    _boardPerspectivePlayer = widget.startingPlayer;
    _refreshState();
    _queueBoardPerspectiveSync(widget.startingPlayer, immediate: true);

    if (_shouldRunLocalTimer && !_isDexterMode) {
      _startTimer();
    }

    if (_isComputerMode && widget.startingPlayer == 2) {
      if (_isDexterMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _beginDexterMatchIntro();
        });
      } else {
        _triggerAIMove();
      }
    } else if (_isDexterMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _beginDexterMatchIntro();
      });
    }

    if (_isLanHost) {
      unawaited(_broadcastLanState());
    }
  }

  /// Shows the move history modal
  Future<void> _showMoveHistory(BuildContext context) async {
    final shouldReopenGameOver = isGameOver;

    await showDialog(
      context: context,
      builder: (context) => MoveHistoryModal(
        history: gameLogic.history,
        player1Name: _playerNameForNumber(1),
        player2Name: _playerNameForNumber(2),
      ),
    );

    if (!mounted) {
      return;
    }

    if (shouldReopenGameOver &&
        isGameOver &&
        winnerMessage != null &&
        !_gameOverDialogVisible) {
      _gameOverDialogVisible = true;
      _showGameOverDialog();
    }
  }

  Future<void> _openPauseMenu() async {
    if (_isPaused) {
      return;
    }

    if (isGameOver) {
      if (!_gameOverDialogVisible && winnerMessage != null) {
        _gameOverDialogVisible = true;
        _showGameOverDialog();
      }
      return;
    }

    final syncPauseAcrossPhones = !_isLanGuest;

    if (syncPauseAcrossPhones) {
      _stopTimer();
      _aiPauseTicket++;
    }

    if (mounted) {
      setState(() {
        if (syncPauseAcrossPhones) {
          _isPaused = true;
          isAIThinking = false;
        }
      });
    }

    if (_isDexterMode) {
      unawaited(DexterVoiceService.instance.stop());
    }

    if (syncPauseAcrossPhones && _isLanHost) {
      unawaited(_broadcastLanState());
    }

    final action = await showDialog<_PauseAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE9F8FF), Color(0xFFB9D3F7)],
            ),
            border: Border.all(color: Colors.white, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF8AB7FF), width: 2),
                ),
                child: const Text(
                  'Settings',
                  style: TextStyle(
                    color: Color(0xFF1D4375),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isLanGuest
                    ? 'This menu is only on your phone. The host timer keeps running.'
                    : _isLanMode
                    ? 'Paused - Two phone match'
                    : _isSharedDevicePvp
                    ? 'Paused - Player vs Player'
                    : 'Paused - Player vs ${_playerNameForNumber(2)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF315276),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              _buildDialogButton(
                label: 'Resume',
                color: const Color(0xFF8BFF88),
                onTap: () =>
                    Navigator.of(dialogContext).pop(_PauseAction.resume),
              ),
              if (!_isLanGuest) ...[
                const SizedBox(height: 12),
                _buildDialogButton(
                  label: 'Restart',
                  color: const Color(0xFFFFE96C),
                  textColor: const Color(0xFF5A4300),
                  onTap: () =>
                      Navigator.of(dialogContext).pop(_PauseAction.restart),
                ),
              ],
              const SizedBox(height: 12),
              _buildDialogButton(
                label: _isLanMode ? 'Leave Match' : 'Back To Menu',
                color: const Color(0xFFFF99CC),
                textColor: const Color(0xFF5B1230),
                onTap: () => Navigator.of(dialogContext).pop(_PauseAction.menu),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    switch (action ?? _PauseAction.resume) {
      case _PauseAction.resume:
        if (syncPauseAcrossPhones) {
          setState(() {
            _isPaused = false;
          });
        }
        if (syncPauseAcrossPhones && _shouldRunLocalTimer && !isGameOver) {
          _startTimer(reset: false);
        }
        if (syncPauseAcrossPhones && _isLanHost) {
          unawaited(_broadcastLanState());
        }
        if (_isComputerMode && gameLogic.currentPlayer == 2 && !isGameOver) {
          _triggerAIMove();
        }
        break;
      case _PauseAction.restart:
        _restartGame();
        break;
      case _PauseAction.menu:
        await _returnToMenu();
        break;
    }
  }

  Future<void> _returnToMenu({bool notifyPeer = true}) async {
    _stopTimer();
    _aiPauseTicket++;
    _clearDexterDialogue(stopVoice: true);
    if (_isLanMode && notifyPeer) {
      await widget.lanSession?.sendJson({
        'type': _isLanHost ? 'session_end' : 'leave',
        'message': _isLanHost
            ? 'The host ended the match.'
            : '${_playerNameForNumber(_localPlayerNumber)} left the match.',
      });
    }
    await _closeLanSession();
    if (!mounted) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /*

  /// Shows the capture scenarios test dialog
  void _showCaptureScenariosDialog(BuildContext context) {
    final scenariosByCategory = getScenariosByCategory();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Capture Rules Test'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Allowed scenarios
                const Text(
                  '✅ ALLOWED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ...scenariosByCategory['Allowed']!.map(
                  (scenario) => _buildScenarioTile(context, scenario),
                ),
                const SizedBox(height: 16),
                // Not allowed scenarios
                const Text(
                  '❌ NOT ALLOWED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...scenariosByCategory['Not Allowed']!.map(
                  (scenario) => _buildScenarioTile(context, scenario),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build a list tile for a scenario
  Widget _buildScenarioTile(BuildContext context, CaptureScenario scenario) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          scenario.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: scenario.isAllowed ? Colors.green[700] : Colors.red[700],
          ),
        ),
        subtitle: Text(scenario.description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Apply the scenario
          Navigator.of(context).pop();
          _applyScenario(scenario);
        },
      ),
    );
  }

  /// Apply a capture scenario to the board
  void _applyScenario(CaptureScenario scenario) {
    // Setup custom board with the scenario chips
    gameLogic.setupCustomBoard(scenario.chips);

    // Reset captured count
    player1Captured = 0;
    player2Captured = 0;

    // Refresh state
    _refreshState();

    // Show a snackbar with the result
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          scenario.isAllowed
              ? '✅ Capture is ALLOWED in this position'
              : '❌ Capture is NOT ALLOWED in this position',
        ),
        backgroundColor: scenario.isAllowed ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

*/
  /// Gets the number of chips remaining for a player
  int chipsRemainingForPlayer(int playerNumber) {
    return gameLogic.getChipCount(playerNumber);
  }

  String _playerNameForNumber(int playerNumber) {
    if (playerNumber == 1) {
      return _player1DisplayName;
    }

    return _player2DisplayName;
  }

  int get _displayTurnNumber {
    final moveEntries = gameLogic.history
        .where((entry) => !entry.isEndgameBonus)
        .length;
    return (moveEntries ~/ 2) + 1;
  }

  String _formatTimerLabel(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildDialogButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    Color textColor = const Color(0xFF18304D),
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildTopHud({required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17325B), Color(0xFF274C86), Color(0xFF122646)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPlayerHud(
              name: _playerNameForNumber(1),
              accent: const Color(0xFF5FB2FF),
              score: player1Score,
              chipsRemaining: chipsRemainingForPlayer(1),
              capturedCount: player1Captured,
              isActive: currentPlayer == 1,
              alignStart: true,
              compact: compact,
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          _buildCenterHud(compact: compact),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: _buildPlayerHud(
              name: _playerNameForNumber(2),
              accent: const Color(0xFFFF7F95),
              score: player2Score,
              chipsRemaining: chipsRemainingForPlayer(2),
              capturedCount: player2Captured,
              isActive: currentPlayer == 2,
              alignStart: false,
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHud({
    required String name,
    required Color accent,
    required double score,
    required int chipsRemaining,
    required int capturedCount,
    required bool isActive,
    required bool alignStart,
    required bool compact,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: accent.withValues(alpha: isActive ? 0.20 : 0.10),
        border: Border.all(
          color: isActive
              ? accent.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.10),
          width: isActive ? 1.8 : 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: alignStart
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignStart
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Text(
                name,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 2 : 3),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignStart
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Text(
                '${score.toStringAsFixed(2)} pts',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: accent,
                  fontSize: compact ? 20 : 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 3 : 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignStart
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPlayerStat(
                    'Chips',
                    chipsRemaining.toString(),
                    compact: compact,
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  _buildPlayerStat(
                    'Taken',
                    capturedCount.toString(),
                    compact: compact,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStat(String label, String value, {required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(
        '$label $value',
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: Color(0xFFE2EEFF),
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCenterHud({required bool compact}) {
    final timerText = !_useMoveTimerEnabled
        ? 'MOVE OFF'
        : _isCaptureTimerSuspended
        ? 'CAPTURE'
        : _formatTimerLabel(_remainingSeconds);
    final timerColor = !_useMoveTimerEnabled
        ? const Color(0xFFE9F5FF)
        : _isCaptureTimerSuspended
        ? const Color(0xFFFFD37A)
        : _remainingSeconds <= 15
        ? const Color(0xFFFFD37A)
        : Colors.white;
    final gameTimerText = _useGameTimerEnabled
        ? 'GAME ${_formatTimerLabel(_remainingGameSeconds)}'
        : 'GAME OFF';

    final statusText = _isLanMode && !_lanReady
        ? (_lanStatusMessage ??
              (_isLanHost ? 'Waiting for Player 2' : 'Waiting for the host'))
        : _isPaused
        ? 'Paused'
        : _isDexterMode && _isDexterIntroActive
        ? '${_playerNameForNumber(2)} is speaking'
        : _useMoveTimerEnabled && _isCaptureTimerSuspended
        ? 'Mandatory capture: move timer paused'
        : _isComputerMode && isAIThinking
        ? '${_playerNameForNumber(2)} thinking'
        : '${_playerNameForNumber(currentPlayer)} to move';

    return Container(
      width: compact ? 112 : 126,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101B2D), Color(0xFF213352)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TURN $_displayTurnNumber',
            style: TextStyle(
              color: Color(0xFF9FBCFF),
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                timerText,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: timerColor,
                  fontSize: compact ? 21 : 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                gameTimerText,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF9FBCFF),
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            statusText,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFFDCE8FF),
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock({required bool compact}) {
    return SizedBox(
      height: compact ? 88 : 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildHistoryDock(compact: compact)),
          SizedBox(width: compact ? 10 : 12),
          _buildPeekDockButton(compact: compact),
          SizedBox(width: compact ? 10 : 12),
          _buildSettingsDockButton(compact: compact),
        ],
      ),
    );
  }

  Widget _buildDexterDialogueBanner({required bool compact}) {
    final message = _dexterDialogueMessage;
    if (!_isDexterMode || message == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 9 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151515), Color(0xFF2C2B33), Color(0xFF5C1B24)],
        ),
        border: Border.all(color: const Color(0xFFFF9CAA), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0x66461A20),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 32 : 36,
            height: compact ? 32 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.graphic_eq_rounded,
              color: const Color(0xFFFFB8C3),
              size: compact ? 18 : 20,
            ),
          ),
          SizedBox(width: compact ? 9 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _playerNameForNumber(2),
                  style: TextStyle(
                    color: const Color(0xFFFFC7D0),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: compact ? 2 : 3),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoMoveToastBanner({required bool compact}) {
    final message = _autoMoveToastMessage;
    if (message == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF2C6), Color(0xFFFFD97A)],
        ),
        border: Border.all(color: const Color(0xFFFFF7DC), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0x66C58A00),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt_rounded,
            color: const Color(0xFF7B4A00),
            size: compact ? 18 : 20,
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFF583400),
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDock({required bool compact}) {
    final recentMoves = gameLogic.history.reversed
        .take(compact ? 1 : 2)
        .toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMoveHistory(context),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 8 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1D365E), Color(0xFF132644)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: compact ? 16 : 18,
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Text(
                    'Move History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 7 : 8,
                      vertical: compact ? 2 : 3,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    child: Text(
                      '${gameLogic.history.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 4 : 8),
              if (recentMoves.isEmpty)
                Text(
                  'No moves yet. Tap to open the full history panel.',
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFD5E4FF),
                    fontSize: compact ? 9 : 11,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                  ),
                )
              else
                ...recentMoves.map((entry) {
                  final playerName = compact
                      ? (entry.player == 1 ? 'P1' : 'P2')
                      : _playerNameForNumber(entry.player);
                  return Padding(
                    padding: EdgeInsets.only(bottom: compact ? 0 : 2),
                    child: Text(
                      '$playerName: ${entry.moveString}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFD5E4FF),
                        fontSize: compact ? 9 : 11,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeekDockButton({required bool compact}) {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() {
          _isBoardPeekActive = true;
        });
      },
      onLongPressEnd: (_) {
        setState(() {
          _isBoardPeekActive = false;
        });
      },
      onLongPressCancel: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _isBoardPeekActive = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: compact ? 86 : 96,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isBoardPeekActive
                ? const [Color(0xFF5AD97A), Color(0xFF1E9F4B)]
                : const [Color(0xFF8DF7A6), Color(0xFF2DBE5C)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.75),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF2DBE5C,
              ).withValues(alpha: _isBoardPeekActive ? 0.40 : 0.24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isBoardPeekActive
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: const Color(0xFF163722),
              size: compact ? 20 : 22,
            ),
            SizedBox(height: compact ? 3 : 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _isBoardPeekActive ? 'Release' : 'Hold',
                maxLines: 1,
                style: TextStyle(
                  color: Color(0xFF163722),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Hide',
                maxLines: 1,
                style: TextStyle(
                  color: Color(0xFF163722),
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsDockButton({required bool compact}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openPauseMenu,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: compact ? 68 : 72,
          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFD16D), Color(0xFFE09C27)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.75),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings_rounded,
                color: const Color(0xFF503208),
                size: compact ? 22 : 24,
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                'Menu',
                style: TextStyle(
                  color: Color(0xFF503208),
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _displayColumnFor(int x, bool isBoardFlipped) {
    return isBoardFlipped ? 7 - x : x;
  }

  int _displayRowFor(int y, bool isBoardFlipped) {
    return isBoardFlipped ? y : 7 - y;
  }

  double _chipLeftFor(int x, _BoardGeometry geometry, bool isBoardFlipped) {
    return geometry.tileMargin +
        (_displayColumnFor(x, isBoardFlipped) * geometry.slotSize) +
        ((geometry.cellSize - geometry.chipSize) / 2);
  }

  double _chipTopFor(int y, _BoardGeometry geometry, bool isBoardFlipped) {
    return geometry.tileMargin +
        (_displayRowFor(y, isBoardFlipped) * geometry.slotSize) +
        ((geometry.cellSize - geometry.chipSize) / 2);
  }

  Widget _buildModernLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 760 || constraints.maxWidth < 360;
        final horizontalPadding = constraints.maxWidth < 380 ? 4.0 : 10.0;
        final verticalGap = compact ? 6.0 : 10.0;
        final topPadding = compact ? 6.0 : 8.0;
        final bottomPadding = compact ? 8.0 : 10.0;
        final visibleBannerCount =
            (_dexterDialogueMessage != null ? 1 : 0) +
            (_autoMoveToastMessage != null ? 1 : 0);
        final bannerHeightAllowance =
            visibleBannerCount * (compact ? 48.0 : 56.0);
        final bannerGapAllowance = visibleBannerCount * verticalGap;
        final boardFrameSize = math.max(
          220.0,
          math.min(
            constraints.maxWidth - (horizontalPadding * 2),
            constraints.maxHeight -
                (compact ? 160.0 : 182.0) -
                bannerHeightAllowance -
                bannerGapAllowance -
                topPadding -
                bottomPadding -
                (verticalGap * 2),
          ),
        );

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF345B93),
                Color(0xFF203F6E),
                Color(0xFF142A49),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopHud(compact: compact),
                    SizedBox(height: verticalGap),
                    if (_dexterDialogueMessage != null) ...[
                      _buildDexterDialogueBanner(compact: compact),
                      SizedBox(height: verticalGap),
                    ],
                    if (_autoMoveToastMessage != null) ...[
                      _buildAutoMoveToastBanner(compact: compact),
                      SizedBox(height: verticalGap),
                    ],
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: boardFrameSize,
                          height: boardFrameSize,
                          child: _buildBoardFrame(
                            boardFrameSize,
                            compact: compact,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: verticalGap),
                    _buildBottomDock(compact: compact),
                  ],
                ),
                if (_isLanMode && !_lanReady)
                  Positioned.fill(
                    child: _buildLanWaitingOverlay(compact: compact),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanWaitingOverlay({required bool compact}) {
    final addresses = widget.lanSession?.localAddresses ?? const <String>[];

    return IgnorePointer(
      ignoring: false,
      child: Container(
        color: Colors.black.withValues(alpha: 0.42),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: EdgeInsets.all(compact ? 18 : 22),
          decoration: BoxDecoration(
            color: const Color(0xFF10233E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLanHost ? Icons.wifi_tethering_rounded : Icons.link_rounded,
                color: Colors.white,
                size: compact ? 34 : 38,
              ),
              SizedBox(height: compact ? 10 : 12),
              Text(
                _isLanHost ? 'Waiting For Player 2' : 'Connecting To Host',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 20 : 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: compact ? 8 : 10),
              Text(
                _lanStatusMessage ??
                    (_isLanHost
                        ? 'Share this IP address with the other phone.'
                        : 'Please wait while the host accepts the match.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFD8E6FF),
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isLanHost && addresses.isNotEmpty) ...[
                SizedBox(height: compact ? 12 : 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Share this to the joining phone',
                        style: TextStyle(
                          color: Color(0xFF9FBCFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final address in addresses)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '$address:4040',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 16 : 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardFrame(double frameSize, {required bool compact}) {
    final outerBoardPadding = compact ? 5.0 : 6.0;
    final innerBoardPadding = compact ? 5.0 : 6.0;
    final labelWidth = compact ? 11.0 : 13.0;
    final axisHeight = compact ? 14.0 : 16.0;
    final tileMargin = compact ? 0.28 : 0.42;
    final boardChrome =
        (outerBoardPadding * 2) +
        (innerBoardPadding * 2) +
        labelWidth +
        axisHeight +
        (tileMargin * 16);

    final geometry = _BoardGeometry(
      cellSize: (frameSize - boardChrome) / 8,
      tileMargin: tileMargin,
      labelWidth: labelWidth,
      axisHeight: axisHeight,
      outerBoardPadding: outerBoardPadding,
      innerBoardPadding: innerBoardPadding,
    );

    final isBoardFlipped = _isBoardFlippedForLocalView;
    final displayRows = List<int>.generate(
      8,
      (rowIndex) => isBoardFlipped ? rowIndex : 7 - rowIndex,
    );
    final displayColumns = List<int>.generate(
      8,
      (columnIndex) => isBoardFlipped ? 7 - columnIndex : columnIndex,
    );
    final axisRows = List<int>.generate(8, (rowIndex) => 7 - rowIndex);
    final axisColumns = List<int>.generate(8, (columnIndex) => columnIndex);

    return Container(
        padding: EdgeInsets.all(outerBoardPadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5FAFF), Color(0xFFC0D5F1), Color(0xFF7EA0CC)],
          ),
          border: Border.all(color: const Color(0xFFEDF6FF), width: 2.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(innerBoardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF123B61), Color(0xFF284D79), Color(0xFF163558)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: geometry.innerWidth,
              height: geometry.innerHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.10),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(8, (rowIndex) {
                        final y = displayRows[rowIndex];
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: labelWidth,
                              child: Text(
                                '${axisRows[rowIndex]}',
                                textAlign: TextAlign.center,
                                textScaler: const TextScaler.linear(1.0),
                                style: TextStyle(
                                  color: Color(0xFFD7E7FF),
                                  fontSize: compact ? 10 : 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            ...displayColumns.map((x) {
                              final isLightTile = (x + y) % 2 != 0;
                              final isSelected =
                                  selectedChip != null &&
                                  selectedChip!.x == x &&
                                  selectedChip!.y == y;
                              final isChainChip =
                                  mustContinueCapturing &&
                                  gameLogic.currentChainChipModel != null &&
                                  gameLogic.currentChainChipModel!.x == x &&
                                  gameLogic.currentChainChipModel!.y == y;
                              final op = operations[y][x];

                              return DragTarget<ChipModel>(
                                onWillAcceptWithDetails: (details) {
                                  if (_isInteractionLocked) {
                                    return false;
                                  }
                                  return _isValidDropTarget(
                                    x,
                                    y,
                                    chip: details.data,
                                  );
                                },
                                onAcceptWithDetails: (details) {
                                  _onChipDropped(details.data, x, y);
                                },
                                builder:
                                    (context, candidateData, rejectedData) {
                                      final isValidTarget =
                                          candidateData.isNotEmpty;
                                      final borderColor = isSelected
                                          ? const Color(0xFFFFE27C)
                                          : isChainChip
                                          ? const Color(0xFFFF9F52)
                                          : isValidTarget
                                          ? const Color(0xFF9CFFB2)
                                          : isLightTile
                                          ? const Color(0xFFE6EADC)
                                          : const Color(0xFF4A7871);
                                      final tileGlowColor = isSelected
                                          ? const Color(0x44FFE27C)
                                          : isChainChip
                                          ? const Color(0x55FF9F52)
                                          : const Color(0x449CFFB2);

                                      return GestureDetector(
                                        onTap: () => onTileTap(x, y),
                                        child: Container(
                                          width: geometry.cellSize,
                                          height: geometry.cellSize,
                                          margin: EdgeInsets.all(tileMargin),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: isLightTile
                                                  ? const [
                                                      Color(0xFFF8F5EA),
                                                      Color(0xFFE7E1D0),
                                                    ]
                                                  : const [
                                                      Color(0xFF5D827D),
                                                      Color(0xFF365A57),
                                                    ],
                                            ),
                                            border: Border.all(
                                              color: borderColor,
                                              width:
                                                  isSelected ||
                                                      isChainChip ||
                                                      isValidTarget
                                                  ? 2.2
                                                  : 1.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: isLightTile
                                                      ? 0.06
                                                      : 0.14,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 3),
                                              ),
                                              if (isSelected ||
                                                  isChainChip ||
                                                  isValidTarget)
                                                BoxShadow(
                                                  color: tileGlowColor,
                                                  blurRadius: 14,
                                                  spreadRadius: 0.4,
                                                ),
                                            ],
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Positioned.fill(
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Colors.white.withValues(
                                                          alpha: isLightTile
                                                              ? 0.22
                                                              : 0.09,
                                                        ),
                                                        Colors.transparent,
                                                        Colors.black.withValues(
                                                          alpha: isLightTile
                                                              ? 0.05
                                                              : 0.12,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (op.isNotEmpty)
                                                Text(
                                                  op,
                                                  textScaler:
                                                      const TextScaler.linear(
                                                        1.0,
                                                      ),
                                                  style: TextStyle(
                                                    color: isLightTile
                                                        ? const Color(
                                                            0xFF6B8B80,
                                                          )
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.88,
                                                              ),
                                                    fontSize:
                                                        geometry.cellSize *
                                                        0.54,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                              );
                            }),
                          ],
                        );
                      }),
                      SizedBox(
                        height: axisHeight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: labelWidth),
                            ...List.generate(8, (columnIndex) {
                              return SizedBox(
                                width: geometry.slotSize,
                                child: Center(
                                  child: Text(
                                    '${axisColumns[columnIndex]}',
                                    textAlign: TextAlign.center,
                                    textScaler: const TextScaler.linear(1.0),
                                    style: TextStyle(
                                      color: Color(0xFFD7E7FF),
                                      fontSize: compact ? 10 : 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: labelWidth,
                    top: 0,
                    width: geometry.boardPixels,
                    height: geometry.boardPixels,
                    child: _isBoardPeekActive
                        ? const SizedBox.shrink()
                        : Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ..._capturedGhosts.map(
                                (ghost) => _buildCapturedGhost(
                                  ghost.snapshot,
                                  geometry,
                                  isBoardFlipped,
                                ),
                              ),
                              ...chips.map(
                                (chip) => _buildAnimatedChip(
                                  chip,
                                  geometry,
                                  isBoardFlipped,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildCapturedGhost(
    _ChipSnapshot snapshot,
    _BoardGeometry geometry,
    bool isBoardFlipped,
  ) {
    return Positioned(
      left: _chipLeftFor(snapshot.x, geometry, isBoardFlipped),
      top: _chipTopFor(snapshot.y, geometry, isBoardFlipped),
      width: geometry.chipSize,
      height: geometry.chipSize,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1, end: 0),
          duration: _chipSlideDuration,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.84 + (value * 0.16),
                child: child,
              ),
            );
          },
          child: ChipWidget(
            chip: snapshot.toChipModel(),
            size: geometry.chipSize,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedChip(
    ChipModel chip,
    _BoardGeometry geometry,
    bool isBoardFlipped,
  ) {
    return AnimatedPositioned(
      key: ValueKey<int>(chip.id),
      duration: _chipSlideDuration,
      curve: Curves.easeInOutCubic,
      left: _chipLeftFor(chip.x, geometry, isBoardFlipped),
      top: _chipTopFor(chip.y, geometry, isBoardFlipped),
      width: geometry.chipSize,
      height: geometry.chipSize,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => onTileTap(chip.x, chip.y),
        child: _buildChipWithGlow(chip, geometry.chipSize),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildModernLayout(context);

    /*
    const double tileMargin = 0.75;
    final double cellSize = (MediaQuery.of(context).size.width - 92) / 8;
    const double labelWidth = 16;
    const double outerBoardPadding = 10;
    const double innerBoardPadding = 10;
    final isBoardFlipped = widget.mode == 'PvP' && currentPlayer == 2;
    final displayRows = List<int>.generate(
      8,
      (rowIndex) => isBoardFlipped ? rowIndex : 7 - rowIndex,
    );
    final displayColumns = List<int>.generate(
      8,
      (columnIndex) => isBoardFlipped ? 7 - columnIndex : columnIndex,
    );
    final axisRows = List<int>.generate(8, (rowIndex) => 7 - rowIndex);
    final axisColumns = List<int>.generate(8, (columnIndex) => columnIndex);

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Player Info Cards - displays detailed player information
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: PlayerInfoCard(
                    player: player1,
                    chipsRemaining: chipsRemainingForPlayer(1),
                    capturedCount: player1Captured,
                    isActive: currentPlayer == 1,
                    remainingTime: _useMoveTimerEnabled && currentPlayer == 1
                        ? _remainingSeconds
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PlayerInfoCard(
                    player: player2,
                    chipsRemaining: chipsRemainingForPlayer(2),
                    capturedCount: player2Captured,
                    isActive: currentPlayer == 2,
                    remainingTime: _useMoveTimerEnabled && currentPlayer == 2
                        ? _remainingSeconds
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Score Board - displays scores for both players
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                ScoreBoard(
                  player1Score: player1Score,
                  player2Score: player2Score,
                  currentPlayer: currentPlayer,
                  player1Name: _playerNameForNumber(1),
                  player2Name: _playerNameForNumber(2),
                ),
                if (_isComputerMode && isAIThinking)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_playerNameForNumber(2)} is thinking...',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                // Reset Game Button
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // History Button
                      IconButton(
                        onPressed: () => _showMoveHistory(context),
                        icon: const Icon(Icons.history),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                        ),
                        tooltip: 'Move History',
                      ),
                      const SizedBox(width: 12),
                      // // Capture Test Button (only for PvP)
                      // if (widget.mode == 'PvP')
                      //   IconButton(
                      //     onPressed: () => _showCaptureScenariosDialog(context),
                      //     icon: const Icon(Icons.science),
                      //     style: IconButton.styleFrom(
                      //       backgroundColor: Colors.purple[700],
                      //       foregroundColor: Colors.white,
                      //       padding: const EdgeInsets.all(8),
                      //     ),
                      //     tooltip: 'Capture Rules Test',
                      //   ),
                      if (widget.mode == 'PvP') const SizedBox(width: 12),
                      // Reset Button
                      IconButton(
                        onPressed: () => _showResetConfirmationDialog(),
                        icon: const Icon(Icons.refresh),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Container(
                  key: ValueKey<bool>(isBoardFlipped),
                  padding: const EdgeInsets.all(outerBoardPadding),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF9C704A),
                        Color(0xFF623A24),
                        Color(0xFFB8895B),
                      ],
                    ),
                    border: Border.all(
                      color: const Color(0xFF442819),
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.26),
                        blurRadius: 22,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: const Color(0x66563420),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(innerBoardPadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.30),
                          Colors.white.withValues(alpha: 0.08),
                          const Color(0x33835E43),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                        width: 1.4,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.18),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.10),
                                    ],
                                    stops: const [0.0, 0.45, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(8, (rowIndex) {
                                final y = displayRows[rowIndex];
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: labelWidth,
                                      child: Text(
                                        '${axisRows[rowIndex]}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD8C7B2),
                                        ),
                                      ),
                                    ),
                                    ...displayColumns.map((x) {
                                      final isWhite = (x + y) % 2 == 0;
                                      final tileGradient = isWhite
                                          ? const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFFF8EED8),
                                                Color(0xFFE2C9A4),
                                              ],
                                            )
                                          : const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF8B654D),
                                                Color(0xFF4B2C1F),
                                              ],
                                            );
                                      final tileEdgeColor = isWhite
                                          ? Colors.white.withValues(alpha: 0.16)
                                          : Colors.white.withValues(
                                              alpha: 0.08,
                                            );
                                      final tileGlossColor = isWhite
                                          ? Colors.white.withValues(alpha: 0.30)
                                          : const Color(0x55D8AA7E);

                                      final chipHere = chipAt(x, y);
                                      final isSelected =
                                          selectedChip != null &&
                                          selectedChip!.x == x &&
                                          selectedChip!.y == y;
                                      final isChainChip =
                                          mustContinueCapturing &&
                                          gameLogic.currentChainChipModel !=
                                              null &&
                                          gameLogic.currentChainChipModel!.x ==
                                              x &&
                                          gameLogic.currentChainChipModel!.y ==
                                              y;

                                      final op = operations[y][x];

                                      return DragTarget<ChipModel>(
                                        onWillAcceptWithDetails: (details) {
                                          final chip = details.data;
                                          if (chip.owner == currentPlayer &&
                                              !isOccupied(x, y)) {
                                            final validMoves = gameLogic
                                                .getValidMoves(chip);
                                            return validMoves.any(
                                              (move) =>
                                                  move.toX == x &&
                                                  move.toY == y,
                                            );
                                          }
                                          return false;
                                        },
                                        onAcceptWithDetails: (details) {
                                          _onChipDropped(details.data, x, y);
                                        },
                                        builder: (context, candidateData, rejectedData) {
                                          final isValidTarget =
                                              candidateData.isNotEmpty;
                                          final hasTileGlow =
                                              isSelected ||
                                              isChainChip ||
                                              isValidTarget;
                                          final tileGlowColor = isSelected
                                              ? Colors.amberAccent.withValues(
                                                  alpha: 0.48,
                                                )
                                              : isChainChip
                                              ? Colors.orange.withValues(
                                                  alpha: 0.38,
                                                )
                                              : Colors.green.withValues(
                                                  alpha: 0.34,
                                                );

                                          return GestureDetector(
                                            onTap: () => onTileTap(x, y),
                                            child: Container(
                                              width: cellSize,
                                              height: cellSize,
                                              margin: const EdgeInsets.all(
                                                tileMargin,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: tileGradient,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: isSelected
                                                    ? Border.all(
                                                        color:
                                                            Colors.yellowAccent,
                                                        width: 2.8,
                                                      )
                                                    : isChainChip
                                                    ? Border.all(
                                                        color: Colors.orange,
                                                        width: 2.8,
                                                      )
                                                    : isValidTarget
                                                    ? Border.all(
                                                        color: Colors.green,
                                                        width: 2.8,
                                                      )
                                                    : Border.all(
                                                        color: tileEdgeColor,
                                                        width: 1.1,
                                                      ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: isWhite
                                                              ? 0.12
                                                              : 0.22,
                                                        ),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                  if (hasTileGlow)
                                                    BoxShadow(
                                                      color: tileGlowColor,
                                                      blurRadius: 12,
                                                      spreadRadius: 0.8,
                                                    ),
                                                ],
                                              ),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Positioned.fill(
                                                    child: IgnorePointer(
                                                      child: DecoratedBox(
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                          gradient: LinearGradient(
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                            colors: [
                                                              tileGlossColor,
                                                              Colors
                                                                  .transparent,
                                                              Colors.black
                                                                  .withValues(
                                                                    alpha:
                                                                        isWhite
                                                                        ? 0.05
                                                                        : 0.14,
                                                                  ),
                                                            ],
                                                            stops: const [
                                                              0.0,
                                                              0.42,
                                                              1.0,
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (op.isNotEmpty)
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal:
                                                                cellSize * 0.10,
                                                            vertical:
                                                                cellSize * 0.05,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              cellSize * 0.24,
                                                            ),
                                                        gradient:
                                                            LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.18,
                                                                    ),
                                                                Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.05,
                                                                    ),
                                                              ],
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        op,
                                                        style: TextStyle(
                                                          fontSize:
                                                              cellSize * 0.42,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: isWhite
                                                              ? const Color(
                                                                  0xFF3F2B1A,
                                                                )
                                                              : Colors.white,
                                                          shadows: [
                                                            Shadow(
                                                              color: Colors
                                                                  .black
                                                                  .withValues(
                                                                    alpha: 0.16,
                                                                  ),
                                                              blurRadius: 4,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  if (chipHere != null)
                                                    _buildChipWithGlow(
                                                      chipHere,
                                                      cellSize,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  ],
                                );
                              }),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: labelWidth),
                                  ...List.generate(8, (columnIndex) {
                                    return SizedBox(
                                      width: cellSize + (tileMargin * 2),
                                      child: Text(
                                        '${axisColumns[columnIndex]}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD8C7B2),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    */
  }
}

