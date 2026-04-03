import 'package:flutter/material.dart';
import '../widgets/game_board.dart';
import '../utils/lan_multiplayer_session.dart';

class GameScreen extends StatefulWidget {
  final String mode; // "PvP" or "PvC"
  final bool useGameTimer; // Whether to enable the 20-minute game timer
  final bool useMoveTimer; // Whether to enable the 2-minute move timer
  final String? difficulty; // "easy", "medium", "hard" for PvC
  final int startingPlayer; // 1 = player, 2 = computer/player 2
  final String player1Name;
  final String player2Name;
  final LanMultiplayerSession? lanSession;

  const GameScreen({
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
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Background music temporarily disabled
    // SoundService().startBackgroundMusic();
  }

  @override
  void dispose() {
    // Background music temporarily disabled
    // SoundService().stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GameBoard(
          mode: widget.mode,
          useGameTimer: widget.useGameTimer,
          useMoveTimer: widget.useMoveTimer,
          difficulty: widget.difficulty,
          startingPlayer: widget.startingPlayer,
          player1Name: widget.player1Name,
          player2Name: widget.player2Name,
          lanSession: widget.lanSession,
        ),
      ),
    );
  }
}
