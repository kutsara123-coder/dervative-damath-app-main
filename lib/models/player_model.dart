/// Represents a player in the Derivative Damath game.
class PlayerModel {
  /// Player's display name
  final String name;

  /// Player's color identifier (blue = 1, red = 2)
  final PlayerColor color;

  /// Current score of the player
  double score;

  /// List of captured polynomial terms from opponent
  /// Each map represents a polynomial term as {exponent: coefficient}
  final List<Map<int, int>> capturedPieces;

  /// Whether this player is controlled by AI
  final bool isAI;

  PlayerModel({
    required this.name,
    required this.color,
    this.score = 0,
    List<Map<int, int>>? capturedPieces,
    this.isAI = false,
  }) : capturedPieces = capturedPieces ?? [];

  /// Creates a copy of this player with optional parameter overrides
  PlayerModel copyWith({
    String? name,
    PlayerColor? color,
    double? score,
    List<Map<int, int>>? capturedPieces,
    bool? isAI,
  }) {
    return PlayerModel(
      name: name ?? this.name,
      color: color ?? this.color,
      score: score ?? this.score,
      capturedPieces: capturedPieces ?? List.from(this.capturedPieces),
      isAI: isAI ?? this.isAI,
    );
  }

  /// Adds captured polynomial terms to the player's captured pieces
  void addCapture(Map<int, int> polynomial) {
    capturedPieces.add(Map.from(polynomial));
  }

  /// Calculates the total value of captured pieces
  int get capturedValue {
    int total = 0;
    for (final poly in capturedPieces) {
      for (final entry in poly.entries) {
        total += entry.value;
      }
    }
    return total;
  }

  /// Returns the numeric representation of player color (1 = blue, 2 = red)
  int get playerNumber => color == PlayerColor.blue ? 1 : 2;
}

/// Enum representing player colors
enum PlayerColor {
  blue,
  red,
}
