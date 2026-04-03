import 'dart:math';

import 'package:derivative_damath/utils/game_logic.dart';

/// Represents the difficulty level of the AI opponent.
enum AIDifficulty {
  /// Easy: Makes legal moves but still feels like a beginner.
  easy,

  /// Medium: Plays solidly with simple lookahead.
  medium,

  /// Hard: Searches cloned future positions more deeply.
  hard,
}

class AIOpponent {
  final AIDifficulty difficulty;
  final GameLogic gameLogic;

  final Random _random = Random();

  static const int _mediumSearchDepth = 1;
  static const int _hardSearchDepth = 3;
  static const int _mediumCandidateLimit = 6;
  static const int _hardCandidateLimit = 6;

  AIOpponent({
    required this.difficulty,
    required this.gameLogic,
  });

  /// Gets the best move for the AI player.
  Move? getBestMove() {
    if (gameLogic.mustContinueCapturing) {
      final chainChip = gameLogic.currentChainChipModel;
      if (chainChip == null) return null;

      final captures = gameLogic.getAvailableCaptures(chainChip);
      if (captures.isEmpty) return null;

      final chainMoves = captures
          .map(
            (capture) => Move(
              fromX: capture.fromX,
              fromY: capture.fromY,
              toX: capture.toX,
              toY: capture.toY,
              isCapture: true,
              capturedChipTerms: capture.capturedChip.terms,
            ),
          )
          .toList();

      return _chooseMove(chainMoves);
    }

    final allMoves = gameLogic.getAllValidMovesForPlayer(2);
    if (allMoves.isEmpty) return null;

    final captureMoves = allMoves.where((move) => move.isCapture).toList();
    final candidateMoves = captureMoves.isNotEmpty ? captureMoves : allMoves;

    return _chooseMove(candidateMoves);
  }

  Move _chooseMove(List<Move> moves) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return _getEasyMove(moves);
      case AIDifficulty.medium:
        return _getMediumMove(moves);
      case AIDifficulty.hard:
        return _getHardMove(moves);
    }
  }

  Move _getEasyMove(List<Move> moves) {
    if (moves.length == 1) return moves.first;

    // Beginner-style play: legal and capture-aware, but still mistake-prone.
    if (_random.nextDouble() < 0.75) {
      return moves[_random.nextInt(moves.length)];
    }

    final scoredMoves = _scoreMoves(
      gameLogic,
      moves,
      searchDepth: 0,
      candidateLimit: 4,
      noiseScale: 18,
    );

    final shortlistLength = min(3, scoredMoves.length);
    return scoredMoves[_random.nextInt(shortlistLength)].move;
  }

  Move _getMediumMove(List<Move> moves) {
    final scoredMoves = _scoreMoves(
      gameLogic,
      moves,
      searchDepth: _mediumSearchDepth,
      candidateLimit: _mediumCandidateLimit,
      noiseScale: 3,
    );

    final shortlistLength = min(2, scoredMoves.length);
    return scoredMoves[_random.nextInt(shortlistLength)].move;
  }

  Move _getHardMove(List<Move> moves) {
    final scoredMoves = _scoreMoves(
      gameLogic,
      moves,
      searchDepth: _hardSearchDepth,
      candidateLimit: _hardCandidateLimit,
      noiseScale: 0,
    );

    return scoredMoves.first.move;
  }

  List<_ScoredMove> _scoreMoves(
    GameLogic state,
    List<Move> moves, {
    required int searchDepth,
    required int candidateLimit,
    required double noiseScale,
  }) {
    final scoredMoves = <_ScoredMove>[];

    for (final move in moves) {
      var score = _scoreMove(
        state,
        move,
        searchDepth: searchDepth,
        candidateLimit: candidateLimit,
      );

      if (noiseScale > 0) {
        score += (_random.nextDouble() - 0.5) * 2 * noiseScale;
      }

      scoredMoves.add(_ScoredMove(move: move, score: score));
    }

    scoredMoves.sort((a, b) => b.score.compareTo(a.score));
    return scoredMoves;
  }

  double _scoreMove(
    GameLogic state,
    Move move, {
    required int searchDepth,
    required int candidateLimit,
  }) {
    final simulated = _cloneGameLogic(state);
    simulated.executeMove(move);

    if (simulated.isGameOver || searchDepth <= 0) {
      return _evaluatePositionScore(simulated);
    }

    return _searchFutureScore(
      simulated,
      depth: searchDepth,
      candidateLimit: candidateLimit,
      alpha: double.negativeInfinity,
      beta: double.infinity,
    );
  }

  double _searchFutureScore(
    GameLogic state, {
    required int depth,
    required int candidateLimit,
    required double alpha,
    required double beta,
  }) {
    if (depth <= 0 || state.isGameOver) {
      return _evaluatePositionScore(state);
    }

    final currentPlayer = state.currentPlayer;
    final availableMoves = state.getAllValidMovesForPlayer(currentPlayer);
    if (availableMoves.isEmpty) {
      return _evaluatePositionScore(state);
    }

    final orderedMoves = _orderMovesForSearch(
      state,
      availableMoves,
      currentPlayer,
      candidateLimit,
    );

    if (currentPlayer == 2) {
      var bestScore = double.negativeInfinity;

      for (final move in orderedMoves) {
        final nextState = _cloneGameLogic(state);
        nextState.executeMove(move);

        final score = _searchFutureScore(
          nextState,
          depth: depth - 1,
          candidateLimit: candidateLimit,
          alpha: alpha,
          beta: beta,
        );

        bestScore = max(bestScore, score);
        alpha = max(alpha, bestScore);
        if (beta <= alpha) break;
      }

      return bestScore;
    }

    var bestScore = double.infinity;

    for (final move in orderedMoves) {
      final nextState = _cloneGameLogic(state);
      nextState.executeMove(move);

      final score = _searchFutureScore(
        nextState,
        depth: depth - 1,
        candidateLimit: candidateLimit,
        alpha: alpha,
        beta: beta,
      );

      bestScore = min(bestScore, score);
      beta = min(beta, bestScore);
      if (beta <= alpha) break;
    }

    return bestScore;
  }

  List<Move> _orderMovesForSearch(
    GameLogic state,
    List<Move> moves,
    int currentPlayer,
    int candidateLimit,
  ) {
    final scored = moves
        .map(
          (move) => _ScoredMove(
            move: move,
            score: _quickMoveHeuristic(state, move, currentPlayer),
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored
        .take(min(candidateLimit, scored.length))
        .map((item) => item.move)
        .toList();
  }

  double _quickMoveHeuristic(GameLogic state, Move move, int player) {
    var score = 0.0;

    if (move.isCapture) {
      score += 140;
      if (move.capturedChipTerms != null) {
        score += _polynomialMagnitude(move.capturedChipTerms!) * 8;
      }
    }

    if (_leadsToPromotion(move, player)) {
      score += 80;
    }

    final operation = state.getOperationAt(move.toX, move.toY);
    if (operation != null && operation.isNotEmpty) {
      score += 12;
    }

    score += _evaluateSquare(move.toX, move.toY, player);
    return score;
  }

  bool _leadsToPromotion(Move move, int player) {
    return (player == 1 && move.toY == 7) || (player == 2 && move.toY == 0);
  }

  double _evaluateSquare(int x, int y, int player) {
    final centerDistance = (3.5 - x).abs() + (3.5 - y).abs();
    var score = (7 - centerDistance) * 2;

    if (player == 2) {
      score += (7 - y) * 1.5;
    } else {
      score += y * 1.5;
    }

    return score;
  }

  double _evaluatePositionScore(GameLogic state) {
    final aiScore = state.getScore(2);
    final playerScore = state.getScore(1);
    final aiChips = state.getChipCount(2);
    final playerChips = state.getChipCount(1);
    final aiDamas = state.getDamaCount(2);
    final playerDamas = state.getDamaCount(1);

    var score = 0.0;
    score += (aiScore - playerScore) * 14;
    score += (aiChips - playerChips) * 45;
    score += (aiDamas - playerDamas) * 110;
    score += _evaluateBoardControl(state) * 4;
    score += _evaluatePieceSafety(state) * 5;
    score += _evaluatePromotionPotential(state) * 4;
    score += _evaluateOperationTileControl(state) * 2;
    score += _evaluateCaptureOpportunities(state) * 5;
    score += _evaluateMobility(state) * 2.5;
    return score;
  }

  double _evaluateBoardControl(GameLogic state) {
    var score = 0.0;

    for (final chip in state.chips) {
      final centerDistance = (3.5 - chip.x).abs() + (3.5 - chip.y).abs();
      final centerBonus = (7 - centerDistance) * 1.5;
      score += chip.owner == 2 ? centerBonus : -centerBonus;
    }

    return score;
  }

  double _evaluatePieceSafety(GameLogic state) {
    var score = 0.0;

    for (final chip in state.chips) {
      final threatened = _isThreatened(state, chip.x, chip.y, chip.owner);
      final defended = _isDefended(state, chip.x, chip.y, chip.owner);

      var chipScore = 0.0;
      if (defended) chipScore += 3;
      if (threatened) chipScore -= chip.isDama ? 12 : 6;
      if (!defended && !threatened) chipScore -= 1;

      score += chip.owner == 2 ? chipScore : -chipScore;
    }

    return score;
  }

  bool _isThreatened(GameLogic state, int x, int y, int owner) {
    for (final opponent in state.chips.where((other) => other.owner != owner)) {
      final captures = state.getAvailableCaptures(opponent);
      for (final capture in captures) {
        if (capture.capturedChip.x == x && capture.capturedChip.y == y) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isDefended(GameLogic state, int x, int y, int owner) {
    for (final ally in state.chips.where((other) => other.owner == owner)) {
      if (ally.x == x && ally.y == y) continue;
      if ((ally.x - x).abs() == 1 && (ally.y - y).abs() == 1) {
        return true;
      }
    }
    return false;
  }

  double _evaluatePromotionPotential(GameLogic state) {
    var score = 0.0;

    for (final chip in state.chips) {
      if (chip.isDama) continue;

      final distanceToPromotion = chip.owner == 2 ? chip.y : (7 - chip.y);
      final promotionBonus = (7 - distanceToPromotion) * 3;
      score += chip.owner == 2 ? promotionBonus : -promotionBonus;
    }

    return score;
  }

  double _evaluateOperationTileControl(GameLogic state) {
    var score = 0.0;

    for (final chip in state.chips) {
      final operation = state.getOperationAt(chip.x, chip.y);
      if (operation == null || operation.isEmpty) continue;
      score += chip.owner == 2 ? 8 : -8;
    }

    return score;
  }

  double _evaluateCaptureOpportunities(GameLogic state) {
    var score = 0.0;

    var aiCaptures = 0;
    for (final chip in state.chips.where((chip) => chip.owner == 2)) {
      aiCaptures += state.getAvailableCaptures(chip).length;
    }

    var playerCaptures = 0;
    for (final chip in state.chips.where((chip) => chip.owner == 1)) {
      playerCaptures += state.getAvailableCaptures(chip).length;
    }

    score += aiCaptures * 10;
    score -= playerCaptures * 10;
    return score;
  }

  double _evaluateMobility(GameLogic state) {
    final aiMoves = state.getAllValidMovesForPlayer(2).length;
    final playerMoves = state.getAllValidMovesForPlayer(1).length;
    return (aiMoves - playerMoves).toDouble();
  }

  int _polynomialMagnitude(Map<int, int> terms) {
    var total = 0;
    for (final entry in terms.entries) {
      total += entry.value.abs();
    }
    return total;
  }

  GameLogic _cloneGameLogic(GameLogic source) {
    final clone = GameLogic();
    clone.setupCustomBoard(
      source.chips
          .map(
            (chip) => <String, dynamic>{
              'x': chip.x,
              'y': chip.y,
              'owner': chip.owner,
              'isDama': chip.isDama,
              'terms': Map<int, int>.from(chip.terms),
            },
          )
          .toList(),
    );
    clone.currentPlayer = source.currentPlayer;
    clone.player1Score = source.player1Score;
    clone.player2Score = source.player2Score;
    return clone;
  }
}

class _ScoredMove {
  final Move move;
  final double score;

  const _ScoredMove({
    required this.move,
    required this.score,
  });
}

