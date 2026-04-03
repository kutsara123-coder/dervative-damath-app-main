import 'chip_model.dart';
import 'player_model.dart';

/// Represents the complete state of a Derivative Damath game.
class GameStateModel {
  /// Current player turn (1 = blue, 2 = red)
  int currentPlayer;

  /// List of all chips on the board
  List<ChipModel> chips;

  /// Score for player 1 (blue)
  double player1Score;

  /// Score for player 2 (red)
  double player2Score;

  /// List of captured polynomial terms by player 1
  final List<Map<int, int>> player1Captures;

  /// List of captured polynomial terms by player 2
  final List<Map<int, int>> player2Captures;

  /// Current phase of the game
  GamePhase phase;

  /// Winner of the game (null if game is not over)
  PlayerModel? winner;

  /// Number of moves made in the game
  int moveCount;

  /// Maximum moves before draw (optional)
  final int? maxMoves;

  GameStateModel({
    this.currentPlayer = 1,
    List<ChipModel>? chips,
    this.player1Score = 0,
    this.player2Score = 0,
    List<Map<int, int>>? player1Captures,
    List<Map<int, int>>? player2Captures,
    this.phase = GamePhase.playing,
    this.winner,
    this.moveCount = 0,
    this.maxMoves,
  })  : chips = chips ?? [],
        player1Captures = player1Captures ?? [],
        player2Captures = player2Captures ?? [];

  /// Creates a copy of this game state with optional parameter overrides
  GameStateModel copyWith({
    int? currentPlayer,
    List<ChipModel>? chips,
    double? player1Score,
    double? player2Score,
    List<Map<int, int>>? player1Captures,
    List<Map<int, int>>? player2Captures,
    GamePhase? phase,
    PlayerModel? winner,
    int? moveCount,
    int? maxMoves,
  }) {
    return GameStateModel(
      currentPlayer: currentPlayer ?? this.currentPlayer,
      chips: chips ?? List.from(this.chips),
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      player1Captures: player1Captures ?? List.from(this.player1Captures),
      player2Captures: player2Captures ?? List.from(this.player2Captures),
      phase: phase ?? this.phase,
      winner: winner ?? this.winner,
      moveCount: moveCount ?? this.moveCount,
      maxMoves: maxMoves ?? this.maxMoves,
    );
  }

  /// Gets the score for a specific player
  double scoreForPlayer(int playerNumber) {
    return playerNumber == 1 ? player1Score : player2Score;
  }

  /// Gets the captures for a specific player
  List<Map<int, int>> capturesForPlayer(int playerNumber) {
    return playerNumber == 1 ? player1Captures : player2Captures;
  }

  /// Adds a captured piece to the current player's captures
  void addCapture(Map<int, int> polynomial) {
    if (currentPlayer == 1) {
      player1Captures.add(Map.from(polynomial));
      player1Score += _calculatePolynomialValue(polynomial);
    } else {
      player2Captures.add(Map.from(polynomial));
      player2Score += _calculatePolynomialValue(polynomial);
    }
  }

  /// Calculates the value of a polynomial
  int _calculatePolynomialValue(Map<int, int> polynomial) {
    int total = 0;
    for (final entry in polynomial.entries) {
      total += entry.value.abs();
    }
    return total;
  }

  /// Switches to the other player's turn
  void switchTurn() {
    currentPlayer = currentPlayer == 1 ? 2 : 1;
    moveCount++;
  }

  /// Gets all chips belonging to a specific player
  List<ChipModel> chipsForPlayer(int playerNumber) {
    return chips.where((chip) => chip.owner == playerNumber).toList();
  }

  /// Gets the chip at a specific position
  ChipModel? chipAt(int x, int y) {
    try {
      return chips.firstWhere((chip) => chip.x == x && chip.y == y);
    } catch (e) {
      return null;
    }
  }

  /// Checks if a position is occupied
  bool isOccupied(int x, int y) {
    return chips.any((chip) => chip.x == x && chip.y == y);
  }

  /// Checks if the game has a winner or is a draw
  bool get isGameOver => phase != GamePhase.playing;

  /// Checks if the game is a draw
  bool get isDraw => phase == GamePhase.draw;

  /// Checks if there is a winner
  bool get hasWinner => winner != null;

  /// Checks if player 1 has won
  bool get player1Won => winner != null && winner!.playerNumber == 1;

  /// Checks if player 2 has won
  bool get player2Won => winner != null && winner!.playerNumber == 2;

  /// Evaluates the game state to check for win/draw conditions
  /// Returns true if the game state was updated
  bool evaluateGameState({
    required PlayerModel player1,
    required PlayerModel player2,
  }) {
    final player1Chips = chipsForPlayer(1);
    final player2Chips = chipsForPlayer(2);

    // Check for win by elimination (opponent has no chips left)
    if (player1Chips.isEmpty) {
      phase = GamePhase.won;
      winner = player2;
      return true;
    }

    if (player2Chips.isEmpty) {
      phase = GamePhase.won;
      winner = player1;
      return true;
    }

    // Check for win by score (if score tracking is enabled)
    // A player wins if they have a significant score advantage
    // and the opponent has no reasonable way to catch up
    if (maxMoves != null && moveCount >= maxMoves!) {
      if (player1Score > player2Score) {
        phase = GamePhase.won;
        winner = player1;
        return true;
      } else if (player2Score > player1Score) {
        phase = GamePhase.won;
        winner = player2;
        return true;
      } else {
        phase = GamePhase.draw;
        winner = null;
        return true;
      }
    }

    // Check for draw by insufficient material (simplified)
    // If both players have only one chip and neither can capture
    if (player1Chips.length == 1 && player2Chips.length == 1) {
      // Could add more sophisticated draw detection here
    }

    return false;
  }

  /// Determines the winner based on current game state
  /// Must be called with proper PlayerModel instances
  void determineWinner(PlayerModel player1, PlayerModel player2) {
    if (player1Score > player2Score) {
      winner = player1;
      phase = GamePhase.won;
    } else if (player2Score > player1Score) {
      winner = player2;
      phase = GamePhase.won;
    } else {
      // Tie - could implement tiebreaker logic
      phase = GamePhase.draw;
      winner = null;
    }
  }

  /// Resets the game to initial state
  void reset() {
    currentPlayer = 1;
    chips.clear();
    player1Score = 0;
    player2Score = 0;
    player1Captures.clear();
    player2Captures.clear();
    phase = GamePhase.playing;
    winner = null;
    moveCount = 0;
  }

  /// Returns a summary of the game state
  String get gameSummary {
    return 'Game State: $phase | '
        'Player 1 Score: $player1Score | '
        'Player 2 Score: $player2Score | '
        'Current Turn: Player $currentPlayer | '
        'Moves: $moveCount';
  }
}

/// Enum representing the phases of the game
enum GamePhase {
  /// Game is in progress
  playing,

  /// Game has been won
  won,

  /// Game ended in a draw
  draw,
}

