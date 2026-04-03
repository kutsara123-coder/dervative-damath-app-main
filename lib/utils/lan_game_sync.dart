import '../models/chip_model.dart';
import '../models/game_state_model.dart';
import '../models/move_history_model.dart';
import '../models/player_model.dart';
import 'game_logic.dart';

class LanGameSync {
  static Map<String, dynamic> encode({
    required GameLogic gameLogic,
    required int remainingSeconds,
    required int remainingGameSeconds,
    required bool isPaused,
    required String player1Name,
    required String player2Name,
    required bool useGameTimer,
    required bool useMoveTimer,
  }) {
    return {
      'currentPlayer': gameLogic.currentPlayer,
      'player1Score': gameLogic.player1Score,
      'player2Score': gameLogic.player2Score,
      'chips': gameLogic.chips.map((chip) => chip.toJson()).toList(),
      'selectedChipId': gameLogic.selectedChip?.id,
      'mustContinueCapture': gameLogic.mustContinueCapturing,
      'currentChainChipId': gameLogic.currentChainChipModel?.id,
      'captureChainDepth': gameLogic.captureChainDepth,
      'gamePhase': gameLogic.gamePhase.name,
      'winnerPlayerNumber': gameLogic.currentWinner?.playerNumber,
      'positionHistory': List<String>.from(gameLogic.positionHistory),
      'moveHistory': gameLogic.history.map((entry) => entry.toJson()).toList(),
      'lastErrorMessage': gameLogic.lastErrorMessage,
      'remainingSeconds': remainingSeconds,
      'remainingGameSeconds': remainingGameSeconds,
      'isPaused': isPaused,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'useGameTimer': useGameTimer,
      'useMoveTimer': useMoveTimer,
    };
  }

  static void apply({
    required GameLogic gameLogic,
    required Map<String, dynamic> payload,
  }) {
    final chips = ((payload['chips'] as List?) ?? const [])
        .map(
          (chip) => ChipModel.fromJson(Map<String, dynamic>.from(chip as Map)),
        )
        .toList();

    gameLogic.chips = chips;
    gameLogic.currentPlayer = payload['currentPlayer'] as int? ?? 1;
    gameLogic.player1Score = (payload['player1Score'] as num?)?.toDouble() ?? 0;
    gameLogic.player2Score = (payload['player2Score'] as num?)?.toDouble() ?? 0;
    gameLogic.lastErrorMessage = payload['lastErrorMessage'] as String?;
    gameLogic.mustContinueCapture =
        payload['mustContinueCapture'] as bool? ?? false;
    gameLogic.captureChainDepth = payload['captureChainDepth'] as int? ?? 0;
    gameLogic.gamePhase = _parseGamePhase(payload['gamePhase'] as String?);

    final chipById = <int, ChipModel>{for (final chip in chips) chip.id: chip};
    final selectedChipId = payload['selectedChipId'] as int?;
    final currentChainChipId = payload['currentChainChipId'] as int?;
    gameLogic.selectedChip = selectedChipId == null
        ? null
        : chipById[selectedChipId];
    gameLogic.currentChainChip = currentChainChipId == null
        ? null
        : chipById[currentChainChipId];

    final winnerPlayerNumber = payload['winnerPlayerNumber'] as int?;
    if (winnerPlayerNumber == null) {
      gameLogic.winner = null;
    } else {
      final playerName = winnerPlayerNumber == 1
          ? (payload['player1Name'] as String? ?? 'Player 1')
          : (payload['player2Name'] as String? ?? 'Player 2');
      gameLogic.winner = PlayerModel(
        name: playerName,
        color: winnerPlayerNumber == 1 ? PlayerColor.blue : PlayerColor.red,
      );
    }

    gameLogic.positionHistory
      ..clear()
      ..addAll(
        ((payload['positionHistory'] as List?) ?? const []).map(
          (entry) => entry.toString(),
        ),
      );

    gameLogic.moveHistory
      ..clear()
      ..addAll(
        ((payload['moveHistory'] as List?) ?? const [])
            .map(
              (entry) => MoveHistoryEntry.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList(),
      );
  }

  static GamePhase _parseGamePhase(String? rawValue) {
    switch (rawValue) {
      case 'won':
        return GamePhase.won;
      case 'draw':
        return GamePhase.draw;
      case 'playing':
      default:
        return GamePhase.playing;
    }
  }
}
