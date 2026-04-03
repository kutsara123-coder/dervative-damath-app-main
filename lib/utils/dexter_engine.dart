import 'dart:math';

import 'package:derivative_damath/models/chip_model.dart';
import 'package:derivative_damath/models/move_history_model.dart';
import 'package:derivative_damath/utils/game_logic.dart';

/// Dexter is a dedicated strategy engine that keeps the original PvC AI intact.
///
/// It combines:
/// - strategy stealing during symmetric openings,
/// - greedy capture valuation,
/// - trap detection for forced negative replies,
/// - deeper search with position cloning.
class DexterEngine {
  static const String defaultName = 'Dexter';
  static const List<_OpeningRule> _openingRules = [
    _OpeningRule(
      name: 'Strategy Stealing 1',
      history: [
        _BookHistoryMove(player: 1, fromX: 1, fromY: 2, toX: 0, toY: 3),
      ],
      response: _BookMove(fromX: 6, fromY: 5, toX: 7, toY: 4),
    ),
    _OpeningRule(
      name: 'Strategy Stealing 2',
      history: [
        _BookHistoryMove(player: 1, fromX: 1, fromY: 2, toX: 0, toY: 3),
        _BookHistoryMove(player: 2, fromX: 6, fromY: 5, toX: 7, toY: 4),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 2, toX: 4, toY: 3),
      ],
      response: _BookMove(fromX: 4, fromY: 5, toX: 3, toY: 4),
    ),
    _OpeningRule(
      name: 'Strategy Stealing 3',
      history: [
        _BookHistoryMove(player: 1, fromX: 1, fromY: 2, toX: 0, toY: 3),
        _BookHistoryMove(player: 2, fromX: 6, fromY: 5, toX: 7, toY: 4),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 2, toX: 4, toY: 3),
        _BookHistoryMove(player: 2, fromX: 4, fromY: 5, toX: 3, toY: 4),
        _BookHistoryMove(player: 1, fromX: 7, fromY: 2, toX: 6, toY: 3),
      ],
      response: _BookMove(fromX: 0, fromY: 5, toX: 1, toY: 4),
    ),
    _OpeningRule(
      name: 'Strategy Stealing 4',
      history: [
        _BookHistoryMove(player: 1, fromX: 1, fromY: 2, toX: 0, toY: 3),
        _BookHistoryMove(player: 2, fromX: 6, fromY: 5, toX: 7, toY: 4),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 2, toX: 4, toY: 3),
        _BookHistoryMove(player: 2, fromX: 4, fromY: 5, toX: 3, toY: 4),
        _BookHistoryMove(player: 1, fromX: 7, fromY: 2, toX: 6, toY: 3),
        _BookHistoryMove(player: 2, fromX: 0, fromY: 5, toX: 1, toY: 4),
        _BookHistoryMove(player: 1, fromX: 6, fromY: 1, toX: 7, toY: 2),
      ],
      response: _BookMove(fromX: 1, fromY: 6, toX: 0, toY: 5),
    ),
    _OpeningRule(
      name: 'Strategy Stealing 5',
      history: [
        _BookHistoryMove(player: 1, fromX: 1, fromY: 2, toX: 0, toY: 3),
        _BookHistoryMove(player: 2, fromX: 6, fromY: 5, toX: 7, toY: 4),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 2, toX: 4, toY: 3),
        _BookHistoryMove(player: 2, fromX: 4, fromY: 5, toX: 3, toY: 4),
        _BookHistoryMove(player: 1, fromX: 7, fromY: 2, toX: 6, toY: 3),
        _BookHistoryMove(player: 2, fromX: 0, fromY: 5, toX: 1, toY: 4),
        _BookHistoryMove(player: 1, fromX: 6, fromY: 1, toX: 7, toY: 2),
        _BookHistoryMove(player: 2, fromX: 1, fromY: 6, toX: 0, toY: 5),
        _BookHistoryMove(player: 1, fromX: 5, fromY: 0, toX: 6, toY: 1),
      ],
      response: _BookMove(fromX: 2, fromY: 7, toX: 1, toY: 6),
    ),
    _OpeningRule(
      name: 'Strategy Stealing 6',
      history: [
        _BookHistoryMove(player: 1, fromX: 1, fromY: 2, toX: 0, toY: 3),
        _BookHistoryMove(player: 2, fromX: 6, fromY: 5, toX: 7, toY: 4),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 2, toX: 4, toY: 3),
        _BookHistoryMove(player: 2, fromX: 4, fromY: 5, toX: 3, toY: 4),
        _BookHistoryMove(player: 1, fromX: 7, fromY: 2, toX: 6, toY: 3),
        _BookHistoryMove(player: 2, fromX: 0, fromY: 5, toX: 1, toY: 4),
        _BookHistoryMove(player: 1, fromX: 6, fromY: 1, toX: 7, toY: 2),
        _BookHistoryMove(player: 2, fromX: 1, fromY: 6, toX: 0, toY: 5),
        _BookHistoryMove(player: 1, fromX: 5, fromY: 0, toX: 6, toY: 1),
        _BookHistoryMove(player: 2, fromX: 2, fromY: 7, toX: 1, toY: 6),
        _BookHistoryMove(player: 1, fromX: 4, fromY: 1, toX: 3, toY: 2),
      ],
      response: _BookMove(fromX: 3, fromY: 6, toX: 4, toY: 5),
    ),
    _OpeningRule(
      name: 'Strategy Stealing 7',
      history: [
        _BookHistoryMove(player: 1, fromX: 1, fromY: 2, toX: 0, toY: 3),
        _BookHistoryMove(player: 2, fromX: 6, fromY: 5, toX: 7, toY: 4),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 2, toX: 4, toY: 3),
        _BookHistoryMove(player: 2, fromX: 4, fromY: 5, toX: 3, toY: 4),
        _BookHistoryMove(player: 1, fromX: 7, fromY: 2, toX: 6, toY: 3),
        _BookHistoryMove(player: 2, fromX: 0, fromY: 5, toX: 1, toY: 4),
        _BookHistoryMove(player: 1, fromX: 6, fromY: 1, toX: 7, toY: 2),
        _BookHistoryMove(player: 2, fromX: 1, fromY: 6, toX: 0, toY: 5),
        _BookHistoryMove(player: 1, fromX: 5, fromY: 0, toX: 6, toY: 1),
        _BookHistoryMove(player: 2, fromX: 2, fromY: 7, toX: 1, toY: 6),
        _BookHistoryMove(player: 1, fromX: 4, fromY: 1, toX: 3, toY: 2),
        _BookHistoryMove(player: 2, fromX: 3, fromY: 6, toX: 4, toY: 5),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 0, toX: 4, toY: 1),
      ],
      response: _BookMove(fromX: 4, fromY: 7, toX: 3, toY: 6),
    ),
    _OpeningRule(
      name: 'Strategy Stealing 8',
      history: [
        _BookHistoryMove(player: 1, fromX: 1, fromY: 2, toX: 0, toY: 3),
        _BookHistoryMove(player: 2, fromX: 6, fromY: 5, toX: 7, toY: 4),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 2, toX: 4, toY: 3),
        _BookHistoryMove(player: 2, fromX: 4, fromY: 5, toX: 3, toY: 4),
        _BookHistoryMove(player: 1, fromX: 7, fromY: 2, toX: 6, toY: 3),
        _BookHistoryMove(player: 2, fromX: 0, fromY: 5, toX: 1, toY: 4),
        _BookHistoryMove(player: 1, fromX: 6, fromY: 1, toX: 7, toY: 2),
        _BookHistoryMove(player: 2, fromX: 1, fromY: 6, toX: 0, toY: 5),
        _BookHistoryMove(player: 1, fromX: 5, fromY: 0, toX: 6, toY: 1),
        _BookHistoryMove(player: 2, fromX: 2, fromY: 7, toX: 1, toY: 6),
        _BookHistoryMove(player: 1, fromX: 4, fromY: 1, toX: 3, toY: 2),
        _BookHistoryMove(player: 2, fromX: 3, fromY: 6, toX: 4, toY: 5),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 0, toX: 4, toY: 1),
        _BookHistoryMove(player: 2, fromX: 4, fromY: 7, toX: 3, toY: 6),
        _BookHistoryMove(player: 1, fromX: 0, fromY: 1, toX: 1, toY: 2),
      ],
      response: _BookMove(fromX: 7, fromY: 6, toX: 6, toY: 5),
    ),
    _OpeningRule(
      name: 'Strategy Stealing 9',
      history: [
        _BookHistoryMove(player: 1, fromX: 1, fromY: 2, toX: 0, toY: 3),
        _BookHistoryMove(player: 2, fromX: 6, fromY: 5, toX: 7, toY: 4),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 2, toX: 4, toY: 3),
        _BookHistoryMove(player: 2, fromX: 4, fromY: 5, toX: 3, toY: 4),
        _BookHistoryMove(player: 1, fromX: 7, fromY: 2, toX: 6, toY: 3),
        _BookHistoryMove(player: 2, fromX: 0, fromY: 5, toX: 1, toY: 4),
        _BookHistoryMove(player: 1, fromX: 6, fromY: 1, toX: 7, toY: 2),
        _BookHistoryMove(player: 2, fromX: 1, fromY: 6, toX: 0, toY: 5),
        _BookHistoryMove(player: 1, fromX: 5, fromY: 0, toX: 6, toY: 1),
        _BookHistoryMove(player: 2, fromX: 2, fromY: 7, toX: 1, toY: 6),
        _BookHistoryMove(player: 1, fromX: 4, fromY: 1, toX: 3, toY: 2),
        _BookHistoryMove(player: 2, fromX: 3, fromY: 6, toX: 4, toY: 5),
        _BookHistoryMove(player: 1, fromX: 3, fromY: 0, toX: 4, toY: 1),
        _BookHistoryMove(player: 2, fromX: 4, fromY: 7, toX: 3, toY: 6),
        _BookHistoryMove(player: 1, fromX: 0, fromY: 1, toX: 1, toY: 2),
        _BookHistoryMove(player: 2, fromX: 7, fromY: 6, toX: 6, toY: 5),
        _BookHistoryMove(player: 1, fromX: 1, fromY: 0, toX: 0, toY: 1),
      ],
      response: _BookMove(fromX: 6, fromY: 7, toX: 7, toY: 6),
    ),
    _OpeningRule(
      name: 'Give And Take Invitation',
      history: [
        _BookHistoryMove(player: 1, fromX: 5, fromY: 2, toX: 4, toY: 3),
      ],
      response: _BookMove(fromX: 2, fromY: 5, toX: 3, toY: 4),
    ),
    _OpeningRule(
      name: 'Give And Take Reclaim',
      history: [
        _BookHistoryMove(player: 1, fromX: 5, fromY: 2, toX: 4, toY: 3),
        _BookHistoryMove(player: 2, fromX: 2, fromY: 5, toX: 3, toY: 4),
        _BookHistoryMove(
          player: 1,
          fromX: 4,
          fromY: 3,
          toX: 2,
          toY: 5,
          isCapture: true,
        ),
      ],
      response: _BookMove(fromX: 3, fromY: 6, toX: 1, toY: 4, isCapture: true),
    ),
    _OpeningRule(
      name: 'Greedy Counter Opening',
      history: [
        _BookHistoryMove(player: 1, fromX: 5, fromY: 2, toX: 6, toY: 3),
      ],
      response: _BookMove(fromX: 4, fromY: 5, toX: 5, toY: 4),
    ),
    _OpeningRule(
      name: 'Greedy Counter Reclaim',
      history: [
        _BookHistoryMove(player: 1, fromX: 5, fromY: 2, toX: 6, toY: 3),
        _BookHistoryMove(player: 2, fromX: 4, fromY: 5, toX: 5, toY: 4),
        _BookHistoryMove(
          player: 1,
          fromX: 6,
          fromY: 3,
          toX: 4,
          toY: 5,
          isCapture: true,
        ),
      ],
      response: _BookMove(fromX: 3, fromY: 6, toX: 5, toY: 4, isCapture: true),
    ),
  ];

  final GameLogic gameLogic;
  final Map<String, _TranspositionEntry> _transpositionTable =
      <String, _TranspositionEntry>{};
  final Map<String, _TranspositionEntry> _exactEndgameTable =
      <String, _TranspositionEntry>{};
  final Map<String, int> _historyTable = <String, int>{};
  final Map<int, List<String>> _killerMoves = <int, List<String>>{};

  Stopwatch? _searchStopwatch;
  Duration _timeBudget = Duration.zero;
  int _softNodeLimit = 0;
  int _nodeCount = 0;
  static const int _transpositionTableLimit = 200000;
  static const double _searchWindowEpsilon = 0.01;

  static const _DexterProfile _openingProfile = _DexterProfile(
    maxDepth: 8,
    quiescenceDepth: 12,
    timeBudgetMs: 1400,
    softNodeLimit: 170000,
  );

  static const _DexterProfile _midgameProfile = _DexterProfile(
    maxDepth: 11,
    quiescenceDepth: 18,
    timeBudgetMs: 3200,
    softNodeLimit: 450000,
  );

  static const _DexterProfile _tacticalProfile = _DexterProfile(
    maxDepth: 12,
    quiescenceDepth: 20,
    timeBudgetMs: 4500,
    softNodeLimit: 650000,
  );

  static const _DexterProfile _endgameProfile = _DexterProfile(
    maxDepth: 15,
    quiescenceDepth: 26,
    timeBudgetMs: 6500,
    softNodeLimit: 1000000,
  );

  DexterEngine({required this.gameLogic});

  Move? getBestMove({Duration? maxThinkingTime}) {
    final legalMoves = gameLogic.getLegalMovesForPlayer(2);
    if (legalMoves.isEmpty) {
      return null;
    }

    final openingMove = _openingBookMove(legalMoves);
    if (openingMove != null) {
      return openingMove;
    }

    final profile = _profileForPosition(gameLogic, legalMoves);
    _pruneSearchTables();
    _historyTable.clear();
    _killerMoves.clear();
    _searchStopwatch = Stopwatch()..start();
    _timeBudget =
        maxThinkingTime ?? Duration(milliseconds: profile.timeBudgetMs);
    _softNodeLimit = profile.softNodeLimit;
    _nodeCount = 0;
    _exactEndgameTable.clear();

    final exactEndgameMove = _tryExactEndgameSolve(gameLogic, legalMoves);
    if (exactEndgameMove != null) {
      return exactEndgameMove;
    }

    var rootMoves = _orderMovesForSearch(gameLogic, legalMoves, 2, ply: 0);
    var bestMove = rootMoves.first;
    var bestScore = double.negativeInfinity;

    for (var depth = 1; depth <= profile.maxDepth; depth++) {
      if (_ranOutOfBudget(threshold: 0.94)) {
        break;
      }

      try {
        final result = depth == 1
            ? _searchRoot(
                gameLogic,
                rootMoves,
                depth: depth,
                profile: profile,
                alpha: double.negativeInfinity,
                beta: double.infinity,
              )
            : _searchRootWithAspiration(
                gameLogic,
                rootMoves,
                depth: depth,
                profile: profile,
                previousScore: bestScore,
              );
        bestMove = result.move;
        bestScore = result.score;

        final bestMoveKey = _moveKey(bestMove);
        rootMoves = <Move>[
          bestMove,
          ...rootMoves.where((move) => _moveKey(move) != bestMoveKey),
        ];

        if (_isDecisiveScore(bestScore)) {
          break;
        }
      } on _SearchTimeout {
        break;
      }
    }

    return bestMove;
  }

  _DexterProfile _profileForPosition(GameLogic state, List<Move> rootMoves) {
    final remainingPieces = state.chips.length;

    if (remainingPieces <= 10 || rootMoves.length <= 4) {
      return _endgameProfile;
    }

    if (state.mustContinueCapturing ||
        rootMoves.any((move) => move.isCapture)) {
      return _tacticalProfile;
    }

    if (state.history.length <= 6) {
      return _openingProfile;
    }

    return _midgameProfile;
  }

  Move? _openingBookMove(List<Move> legalMoves) {
    if (gameLogic.history.isEmpty || gameLogic.history.length > 18) {
      return null;
    }

    for (final rule in _openingRules) {
      if (!rule.matches(gameLogic.history)) {
        continue;
      }

      final move = _findMatchingBookMove(legalMoves, rule.response);
      if (move != null) {
        return move;
      }
    }

    if (legalMoves.any((move) => move.isCapture)) {
      return null;
    }

    for (final move in legalMoves) {
      if (_strategyStealingBonus(gameLogic, move) > 0) {
        return move;
      }
    }

    final thematicMove = _thematicOpeningMove(legalMoves);
    if (thematicMove != null) {
      return thematicMove;
    }

    return null;
  }

  Move? _findMatchingBookMove(List<Move> legalMoves, _BookMove pattern) {
    for (final move in legalMoves) {
      if (pattern.matches(move)) {
        return move;
      }
    }
    return null;
  }

  Move? _thematicOpeningMove(List<Move> legalMoves) {
    final sortedMoves = List<Move>.from(legalMoves)
      ..sort(
        (a, b) => _quickMoveHeuristic(
          gameLogic,
          b,
          2,
        ).compareTo(_quickMoveHeuristic(gameLogic, a, 2)),
      );

    for (final move in sortedMoves) {
      if (_strategyStealingBonus(gameLogic, move) > 0) {
        return move;
      }

      final operation = gameLogic.getOperationAt(move.toX, move.toY);
      if ((operation ?? '').isNotEmpty) {
        return move;
      }
    }

    return sortedMoves.isEmpty ? null : sortedMoves.first;
  }

  Move? _tryExactEndgameSolve(GameLogic state, List<Move> legalMoves) {
    if (state.chips.length > 14 || legalMoves.length > 30) {
      return null;
    }

    try {
      final orderedMoves = _orderMovesForSearch(state, legalMoves, 2, ply: 0);
      var bestMove = orderedMoves.first;
      var bestScore = double.negativeInfinity;

      for (final move in orderedMoves) {
        _throwIfOutOfBudget();

        final nextState = state.clone();
        nextState.executeMove(move);

        final score = _solveEndgameExactly(
          nextState,
          ply: 1,
          alpha: double.negativeInfinity,
          beta: double.infinity,
        );

        if (score > bestScore) {
          bestScore = score;
          bestMove = move;
        }
      }

      return bestMove;
    } on _SearchTimeout {
      return null;
    }
  }

  void _pruneSearchTables() {
    if (_transpositionTable.length > _transpositionTableLimit) {
      _transpositionTable.clear();
    }

    if (_exactEndgameTable.length > (_transpositionTableLimit ~/ 3)) {
      _exactEndgameTable.clear();
    }
  }

  _RootSearchResult _searchRootWithAspiration(
    GameLogic state,
    List<Move> rootMoves, {
    required int depth,
    required _DexterProfile profile,
    required double previousScore,
  }) {
    var window = 60.0;

    while (true) {
      final alpha = previousScore - window;
      final beta = previousScore + window;
      final result = _searchRoot(
        state,
        rootMoves,
        depth: depth,
        profile: profile,
        alpha: alpha,
        beta: beta,
      );

      if (result.score <= alpha) {
        window *= 2.0;
        continue;
      }

      if (result.score >= beta) {
        window *= 2.0;
        continue;
      }

      return result;
    }
  }

  double _solveEndgameExactly(
    GameLogic state, {
    required int ply,
    required double alpha,
    required double beta,
  }) {
    _nodeCount++;
    _throwIfOutOfBudget();

    final cacheKey = 'E|${_buildStateCacheKey(state)}';
    final cached = _exactEndgameTable[cacheKey];
    if (cached != null) {
      switch (cached.bound) {
        case _SearchBound.exact:
          return cached.score;
        case _SearchBound.lower:
          alpha = max(alpha, cached.score);
          break;
        case _SearchBound.upper:
          beta = min(beta, cached.score);
          break;
      }
      if (alpha >= beta) {
        return cached.score;
      }
    }

    if (state.isGameOver) {
      return _evaluatePositionScore(state, ply: ply);
    }

    final originalAlpha = alpha;
    final originalBeta = beta;
    final currentPlayer = state.currentPlayer;
    final legalMoves = state.getLegalMovesForPlayer(currentPlayer);

    if (legalMoves.isEmpty) {
      return _evaluatePositionScore(state, ply: ply);
    }

    final orderedMoves = _orderMovesForSearch(
      state,
      legalMoves,
      currentPlayer,
      ply: ply,
    );

    var bestMoveKey = _moveKey(orderedMoves.first);

    if (currentPlayer == 2) {
      var bestScore = double.negativeInfinity;
      for (final move in orderedMoves) {
        final nextState = state.clone();
        nextState.executeMove(move);
        final score = _solveEndgameExactly(
          nextState,
          ply: ply + 1,
          alpha: alpha,
          beta: beta,
        );

        if (score > bestScore) {
          bestScore = score;
          bestMoveKey = _moveKey(move);
        }

        alpha = max(alpha, bestScore);
        if (alpha >= beta) {
          break;
        }
      }

      _exactEndgameTable[cacheKey] = _TranspositionEntry(
        score: bestScore,
        depth: 999 - ply,
        bound: _boundForScore(
          bestScore,
          originalAlpha: originalAlpha,
          originalBeta: originalBeta,
        ),
        bestMoveKey: bestMoveKey,
      );
      return bestScore;
    }

    var bestScore = double.infinity;
    for (final move in orderedMoves) {
      final nextState = state.clone();
      nextState.executeMove(move);
      final score = _solveEndgameExactly(
        nextState,
        ply: ply + 1,
        alpha: alpha,
        beta: beta,
      );

      if (score < bestScore) {
        bestScore = score;
        bestMoveKey = _moveKey(move);
      }

      beta = min(beta, bestScore);
      if (alpha >= beta) {
        break;
      }
    }

    _exactEndgameTable[cacheKey] = _TranspositionEntry(
      score: bestScore,
      depth: 999 - ply,
      bound: _boundForScore(
        bestScore,
        originalAlpha: originalAlpha,
        originalBeta: originalBeta,
      ),
      bestMoveKey: bestMoveKey,
    );
    return bestScore;
  }

  _RootSearchResult _searchRoot(
    GameLogic state,
    List<Move> rootMoves, {
    required int depth,
    required _DexterProfile profile,
    required double alpha,
    required double beta,
  }) {
    var localAlpha = alpha;
    final rootBeta = beta;
    var bestMove = rootMoves.first;
    var bestScore = double.negativeInfinity;
    var bestHeuristic = double.negativeInfinity;
    var firstMove = true;

    for (final move in rootMoves) {
      _throwIfOutOfBudget();

      final nextState = state.clone();
      nextState.executeMove(move);

      final nextDepth = _nextDepth(
        currentDepth: depth,
        currentPlayer: 2,
        nextState: nextState,
      );
      final score = firstMove
          ? _searchFutureScore(
              nextState,
              depth: nextDepth,
              ply: 1,
              profile: profile,
              alpha: localAlpha,
              beta: rootBeta,
            )
          : _principalVariationProbe(
              nextState,
              depth: nextDepth,
              ply: 1,
              profile: profile,
              alpha: localAlpha,
              beta: rootBeta,
            );

      final heuristic = _quickMoveHeuristic(state, move, 2);
      if (score > bestScore ||
          (score == bestScore && heuristic > bestHeuristic)) {
        bestScore = score;
        bestMove = move;
        bestHeuristic = heuristic;
      }

      localAlpha = max(localAlpha, bestScore);
      firstMove = false;
    }

    return _RootSearchResult(move: bestMove, score: bestScore);
  }

  double _searchFutureScore(
    GameLogic state, {
    required int depth,
    required int ply,
    required _DexterProfile profile,
    required double alpha,
    required double beta,
  }) {
    _nodeCount++;
    _throwIfOutOfBudget();

    if (state.isGameOver) {
      return _evaluatePositionScore(state, ply: ply);
    }

    final originalAlpha = alpha;
    final originalBeta = beta;
    final cacheKey = _buildStateCacheKey(state);
    final ttEntry = _transpositionTable[cacheKey];
    if (ttEntry != null && ttEntry.depth >= depth) {
      switch (ttEntry.bound) {
        case _SearchBound.exact:
          return ttEntry.score;
        case _SearchBound.lower:
          alpha = max(alpha, ttEntry.score);
          break;
        case _SearchBound.upper:
          beta = min(beta, ttEntry.score);
          break;
      }

      if (alpha >= beta) {
        return ttEntry.score;
      }
    }

    if (depth <= 0) {
      return _quiescenceSearch(
        state,
        depthLeft: profile.quiescenceDepth,
        ply: ply,
        alpha: alpha,
        beta: beta,
      );
    }

    final currentPlayer = state.currentPlayer;
    final legalMoves = state.getLegalMovesForPlayer(currentPlayer);
    if (legalMoves.isEmpty) {
      return _evaluatePositionScore(state, ply: ply);
    }

    final orderedMoves = _orderMovesForSearch(
      state,
      legalMoves,
      currentPlayer,
      ply: ply,
      ttMoveKey: ttEntry?.bestMoveKey,
    );

    var bestMoveKey = _moveKey(orderedMoves.first);

    if (currentPlayer == 2) {
      var bestScore = double.negativeInfinity;
      var firstMove = true;

      for (var i = 0; i < orderedMoves.length; i++) {
        final move = orderedMoves[i];
        _throwIfOutOfBudget();

        final nextState = state.clone();
        nextState.executeMove(move);

        final score = _searchChildScore(
          nextState,
          move: move,
          parentState: state,
          depth: depth,
          ply: ply,
          profile: profile,
          alpha: alpha,
          beta: beta,
          currentPlayer: currentPlayer,
          firstMove: firstMove,
          moveIndex: i,
        );

        if (score > bestScore) {
          bestScore = score;
          bestMoveKey = _moveKey(move);
        }

        alpha = max(alpha, bestScore);
        firstMove = false;
        if (beta <= alpha) {
          _recordCutoff(move, ply, depth);
          break;
        }
      }

      _transpositionTable[cacheKey] = _TranspositionEntry(
        score: bestScore,
        depth: depth,
        bound: _boundForScore(
          bestScore,
          originalAlpha: originalAlpha,
          originalBeta: originalBeta,
        ),
        bestMoveKey: bestMoveKey,
      );
      return bestScore;
    }

    var bestScore = double.infinity;
    var firstMove = true;

    for (var i = 0; i < orderedMoves.length; i++) {
      final move = orderedMoves[i];
      _throwIfOutOfBudget();

      final nextState = state.clone();
      nextState.executeMove(move);

      final score = _searchChildScore(
        nextState,
        move: move,
        parentState: state,
        depth: depth,
        ply: ply,
        profile: profile,
        alpha: alpha,
        beta: beta,
        currentPlayer: currentPlayer,
        firstMove: firstMove,
        moveIndex: i,
      );

      if (score < bestScore) {
        bestScore = score;
        bestMoveKey = _moveKey(move);
      }

      beta = min(beta, bestScore);
      firstMove = false;
      if (beta <= alpha) {
        _recordCutoff(move, ply, depth);
        break;
      }
    }

    _transpositionTable[cacheKey] = _TranspositionEntry(
      score: bestScore,
      depth: depth,
      bound: _boundForScore(
        bestScore,
        originalAlpha: originalAlpha,
        originalBeta: originalBeta,
      ),
      bestMoveKey: bestMoveKey,
    );
    return bestScore;
  }

  double _principalVariationProbe(
    GameLogic state, {
    required int depth,
    required int ply,
    required _DexterProfile profile,
    required double alpha,
    required double beta,
  }) {
    final maximizing = state.currentPlayer == 2;

    if (maximizing) {
      var score = _searchFutureScore(
        state,
        depth: depth,
        ply: ply,
        profile: profile,
        alpha: alpha,
        beta: alpha + _searchWindowEpsilon,
      );

      if (score > alpha && score < beta) {
        score = _searchFutureScore(
          state,
          depth: depth,
          ply: ply,
          profile: profile,
          alpha: alpha,
          beta: beta,
        );
      }

      return score;
    }

    var score = _searchFutureScore(
      state,
      depth: depth,
      ply: ply,
      profile: profile,
      alpha: beta - _searchWindowEpsilon,
      beta: beta,
    );

    if (score > alpha && score < beta) {
      score = _searchFutureScore(
        state,
        depth: depth,
        ply: ply,
        profile: profile,
        alpha: alpha,
        beta: beta,
      );
    }

    return score;
  }

  double _quiescenceSearch(
    GameLogic state, {
    required int depthLeft,
    required int ply,
    required double alpha,
    required double beta,
  }) {
    _nodeCount++;
    _throwIfOutOfBudget();

    final standPat = _evaluatePositionScore(state, ply: ply);
    if (state.isGameOver || depthLeft <= 0) {
      return standPat;
    }

    final captureMoves = state
        .getLegalMovesForPlayer(state.currentPlayer)
        .where((move) => move.isCapture)
        .toList();
    if (captureMoves.isEmpty) {
      return standPat;
    }

    final orderedCaptures = _orderMovesForSearch(
      state,
      captureMoves,
      state.currentPlayer,
      ply: ply,
    );

    if (state.currentPlayer == 2) {
      if (standPat >= beta) {
        return standPat;
      }
      alpha = max(alpha, standPat);

      for (final move in orderedCaptures) {
        final nextState = state.clone();
        nextState.executeMove(move);

        final score = _quiescenceSearch(
          nextState,
          depthLeft: depthLeft - 1,
          ply: ply + 1,
          alpha: alpha,
          beta: beta,
        );

        alpha = max(alpha, score);
        if (alpha >= beta) {
          break;
        }
      }

      return alpha;
    }

    if (standPat <= alpha) {
      return standPat;
    }
    beta = min(beta, standPat);

    for (final move in orderedCaptures) {
      final nextState = state.clone();
      nextState.executeMove(move);

      final score = _quiescenceSearch(
        nextState,
        depthLeft: depthLeft - 1,
        ply: ply + 1,
        alpha: alpha,
        beta: beta,
      );

      beta = min(beta, score);
      if (beta <= alpha) {
        break;
      }
    }

    return beta;
  }

  double _searchChildScore(
    GameLogic nextState, {
    required Move move,
    required GameLogic parentState,
    required int depth,
    required int ply,
    required _DexterProfile profile,
    required double alpha,
    required double beta,
    required int currentPlayer,
    required bool firstMove,
    required int moveIndex,
  }) {
    final nextDepth = _nextDepth(
      currentDepth: depth,
      currentPlayer: currentPlayer,
      nextState: nextState,
    );

    if (firstMove) {
      return _searchFutureScore(
        nextState,
        depth: nextDepth,
        ply: ply + 1,
        profile: profile,
        alpha: alpha,
        beta: beta,
      );
    }

    final reduction = _lateMoveReduction(
      parentState,
      move,
      nextState,
      depth: depth,
      moveIndex: moveIndex,
    );
    if (reduction > 0) {
      final reducedDepth = max(0, nextDepth - reduction);
      final reducedScore = _principalVariationProbe(
        nextState,
        depth: reducedDepth,
        ply: ply + 1,
        profile: profile,
        alpha: alpha,
        beta: beta,
      );

      if (currentPlayer == 2) {
        if (reducedScore <= alpha) {
          return reducedScore;
        }
      } else if (reducedScore >= beta) {
        return reducedScore;
      }
    }

    return _principalVariationProbe(
      nextState,
      depth: nextDepth,
      ply: ply + 1,
      profile: profile,
      alpha: alpha,
      beta: beta,
    );
  }

  int _lateMoveReduction(
    GameLogic state,
    Move move,
    GameLogic nextState, {
    required int depth,
    required int moveIndex,
  }) {
    if (depth < 3 || moveIndex < 3) {
      return 0;
    }

    if (move.isCapture ||
        state.mustContinueCapturing ||
        nextState.mustContinueCapturing ||
        nextState.isGameOver) {
      return 0;
    }

    final movingChip = state.chipAt(move.fromX, move.fromY);
    if (movingChip != null &&
        !movingChip.isDama &&
        _leadsToPromotion(move, movingChip.owner)) {
      return 0;
    }

    if (_shouldExtendTactically(nextState)) {
      return 0;
    }

    var reduction = 1;
    if (depth >= 6 && moveIndex >= 5) {
      reduction++;
    }
    if (depth >= 8 && moveIndex >= 8) {
      reduction++;
    }

    final maxAllowedReduction = max(0, depth - 2);
    return min(reduction, maxAllowedReduction);
  }

  int _nextDepth({
    required int currentDepth,
    required int currentPlayer,
    required GameLogic nextState,
  }) {
    if (currentDepth <= 0 || nextState.isGameOver) {
      return 0;
    }

    final sameTurnContinues =
        nextState.currentPlayer == currentPlayer &&
        nextState.mustContinueCapturing;

    final baseDepth = sameTurnContinues ? currentDepth : currentDepth - 1;
    if (baseDepth <= 0) {
      return 0;
    }

    if (_shouldExtendTactically(nextState)) {
      return baseDepth + 1;
    }

    return baseDepth;
  }

  bool _shouldExtendTactically(GameLogic state) {
    if (state.isGameOver || state.chips.isEmpty) {
      return false;
    }

    if (state.mustContinueCapturing) {
      return true;
    }

    final sideToMove = state.currentPlayer;
    final legalMoves = state.getLegalMovesForPlayer(sideToMove);
    if (legalMoves.isEmpty) {
      return false;
    }

    if (legalMoves.length <= 2) {
      return true;
    }

    if (legalMoves.any((move) => move.isCapture)) {
      return true;
    }

    for (final chip in state.chips.where((chip) => chip.owner == sideToMove)) {
      if (chip.isDama && _isThreatened(state, chip.x, chip.y, sideToMove)) {
        return true;
      }

      for (final capture in state.getAvailableCaptures(chip)) {
        if (capture.capturedChip.isDama ||
            _chipStrategicValue(capture.capturedChip) >= 240) {
          return true;
        }
      }
    }

    for (final chip in state.chips.where((chip) => chip.owner == sideToMove)) {
      if (!chip.isDama &&
          ((chip.owner == 2 && chip.y <= 1) ||
              (chip.owner == 1 && chip.y >= 6))) {
        return true;
      }
    }

    return false;
  }

  List<Move> _orderMovesForSearch(
    GameLogic state,
    List<Move> moves,
    int currentPlayer, {
    required int ply,
    String? ttMoveKey,
  }) {
    final scoredMoves =
        moves
            .map(
              (move) => _ScoredMove(
                move: move,
                score: _moveOrderingScore(
                  state,
                  move,
                  currentPlayer,
                  ply: ply,
                  ttMoveKey: ttMoveKey,
                ),
              ),
            )
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

    return scoredMoves.map((item) => item.move).toList();
  }

  double _moveOrderingScore(
    GameLogic state,
    Move move,
    int player, {
    required int ply,
    String? ttMoveKey,
  }) {
    final moveKey = _moveKey(move);
    if (ttMoveKey != null && moveKey == ttMoveKey) {
      return 1e12;
    }

    final movingChip = state.chipAt(move.fromX, move.fromY);
    final capturedChip = _capturedChipForMove(state, move);
    var score = 0.0;

    if (move.isCapture) {
      score += 200000;
      if (capturedChip != null) {
        score += _chipStrategicValue(capturedChip) * 14;
        if (capturedChip.isDama) {
          score += 500;
        }
      }
      if (movingChip != null) {
        score -= _chipStrategicValue(movingChip) * 0.15;
      }
    } else {
      if (_isKillerMove(ply, moveKey)) {
        score += 6000;
      }
      score += (_historyTable[moveKey] ?? 0).toDouble();
    }

    if (movingChip != null &&
        !movingChip.isDama &&
        _leadsToPromotion(move, movingChip.owner)) {
      score += 1200;
    }

    score += _strategyStealingBonus(state, move) * 50;
    score += _evaluateSquare(move.toX, move.toY, player) * 12;

    final operation = state.getOperationAt(move.toX, move.toY);
    if (operation != null && operation.isNotEmpty) {
      score += 160;
    }

    return score;
  }

  ChipModel? _capturedChipForMove(GameLogic state, Move move) {
    if (!move.isCapture) {
      return null;
    }

    final movingChip = state.chipAt(move.fromX, move.fromY);
    if (movingChip == null) {
      return null;
    }

    final dx = move.toX > move.fromX ? 1 : -1;
    final dy = move.toY > move.fromY ? 1 : -1;

    var x = move.fromX + dx;
    var y = move.fromY + dy;

    while (x != move.toX && y != move.toY) {
      final chip = state.chipAt(x, y);
      if (chip != null) {
        return chip.owner == movingChip.owner ? null : chip;
      }

      x += dx;
      y += dy;
    }

    return null;
  }

  void _recordCutoff(Move move, int ply, int depth) {
    if (move.isCapture) {
      return;
    }

    final moveKey = _moveKey(move);
    final killers = _killerMoves.putIfAbsent(ply, () => <String>[]);
    killers.remove(moveKey);
    killers.insert(0, moveKey);
    if (killers.length > 2) {
      killers.removeLast();
    }

    _historyTable.update(
      moveKey,
      (value) => value + (depth * depth),
      ifAbsent: () => depth * depth,
    );
  }

  bool _isKillerMove(int ply, String moveKey) {
    return _killerMoves[ply]?.contains(moveKey) ?? false;
  }

  _SearchBound _boundForScore(
    double score, {
    required double originalAlpha,
    required double originalBeta,
  }) {
    if (score <= originalAlpha) {
      return _SearchBound.upper;
    }
    if (score >= originalBeta) {
      return _SearchBound.lower;
    }
    return _SearchBound.exact;
  }

  bool _isDecisiveScore(double score) {
    return score.abs() >= 190000;
  }

  bool _ranOutOfBudget({double threshold = 1.0}) {
    final watch = _searchStopwatch;
    if (watch == null || _timeBudget == Duration.zero) {
      return false;
    }

    final budgetMicros = (_timeBudget.inMicroseconds * threshold).round();
    if (watch.elapsedMicroseconds >= budgetMicros) {
      return true;
    }

    if (_softNodeLimit > 0 &&
        _nodeCount >= (_softNodeLimit * threshold).round()) {
      return true;
    }

    return false;
  }

  void _throwIfOutOfBudget() {
    if (_ranOutOfBudget()) {
      throw const _SearchTimeout();
    }
  }

  String _moveKey(Move move) {
    return '${move.fromX},${move.fromY}->${move.toX},${move.toY}${move.isCapture ? 'x' : '-'}';
  }

  double _chipStrategicValue(ChipModel chip) {
    final reserveValue = _endgameReserveValue(chip);
    var value = 90.0 + (reserveValue * 11.0);
    if (chip.isDama) {
      value += 140.0 + (reserveValue * 3.5);
    }
    return value;
  }

  double _quickMoveHeuristic(GameLogic state, Move move, int player) {
    final movingChip = state.chipAt(move.fromX, move.fromY);
    if (movingChip == null) {
      return 0;
    }

    final simulated = state.clone();
    final beforeScore = _scoreForPlayer(simulated, player);
    simulated.executeMove(move);
    final afterScore = _scoreForPlayer(simulated, player);
    final immediateDelta = afterScore - beforeScore;

    var score = 0.0;
    score += _evaluateSquare(move.toX, move.toY, player);
    score += immediateDelta * 0.20;
    score += _strategyStealingBonus(state, move);

    if (move.isCapture) {
      score += 180;
      if (move.capturedChipTerms != null) {
        score += _polynomialMagnitude(move.capturedChipTerms!) * 9;
      }
    }

    if (!movingChip.isDama && _leadsToPromotion(move, player)) {
      score += 95;
    }

    if (_isThreatened(state, move.fromX, move.fromY, player)) {
      score += 18;
    }

    score += _forcedReplyTrapBonus(simulated, player);
    score -= _opponentCounterplayPenalty(simulated, player);

    final operation = state.getOperationAt(move.toX, move.toY);
    if (operation != null && operation.isNotEmpty) {
      score += 14;
    }

    return score;
  }

  double _strategyStealingBonus(GameLogic state, Move move) {
    if (state.history.isEmpty) {
      return 0;
    }

    final lastMove = state.history.last;
    if (lastMove.player != 1 || lastMove.isCapture) {
      return 0;
    }

    final expectedFromX = 7 - lastMove.fromX;
    final expectedFromY = 7 - lastMove.fromY;
    final expectedToX = 7 - lastMove.toX;
    final expectedToY = 7 - lastMove.toY;

    final isMirroredMove =
        move.fromX == expectedFromX &&
        move.fromY == expectedFromY &&
        move.toX == expectedToX &&
        move.toY == expectedToY;

    return isMirroredMove ? 90 : 0;
  }

  double _forcedReplyTrapBonus(GameLogic afterMoveState, int mover) {
    if (afterMoveState.isGameOver) {
      return 240;
    }

    final opponent = mover == 1 ? 2 : 1;
    if (afterMoveState.currentPlayer != opponent) {
      return 0;
    }

    final opponentMoves = afterMoveState.getLegalMovesForPlayer(opponent);
    if (opponentMoves.isEmpty) {
      return 180;
    }

    final bestReplyDelta = opponentMoves
        .map((reply) => _scoreDeltaForMove(afterMoveState, reply, opponent))
        .reduce(max);

    if (bestReplyDelta < 0) {
      return min(260, (-bestReplyDelta) * 4.5 + 50);
    }

    if (opponentMoves.every((move) => move.isCapture) && bestReplyDelta <= 1) {
      return 24;
    }

    return 0;
  }

  double _opponentCounterplayPenalty(GameLogic afterMoveState, int mover) {
    if (afterMoveState.isGameOver) {
      return 0;
    }

    final opponent = mover == 1 ? 2 : 1;
    if (afterMoveState.currentPlayer != opponent) {
      return 0;
    }

    final opponentMoves = afterMoveState.getLegalMovesForPlayer(opponent);
    if (opponentMoves.isEmpty) {
      return 0;
    }

    final bestReplyDelta = opponentMoves
        .map((reply) => _scoreDeltaForMove(afterMoveState, reply, opponent))
        .reduce(max);

    return bestReplyDelta > 0 ? bestReplyDelta * 0.38 : 0;
  }

  double _scoreDeltaForMove(GameLogic state, Move move, int player) {
    final simulated = state.clone();
    final before = _scoreForPlayer(simulated, player);
    simulated.executeMove(move);
    final after = _scoreForPlayer(simulated, player);
    return after - before;
  }

  bool _leadsToPromotion(Move move, int player) {
    return (player == 1 && move.toY == 7) || (player == 2 && move.toY == 0);
  }

  double _scoreForPlayer(GameLogic state, int player) {
    return state.getFinalScore(player);
  }

  double _evaluateSquare(int x, int y, int player) {
    final centerDistance = (3.5 - x).abs() + (3.5 - y).abs();
    var score = (7 - centerDistance) * 2.2;

    if (player == 2) {
      score += (7 - y) * 2;
    } else {
      score += y * 2;
    }

    return score;
  }

  double _evaluatePositionScore(GameLogic state, {int ply = 0}) {
    if (state.isGameOver) {
      final winner = state.currentWinner?.playerNumber;
      final finalMargin = state.getFinalScore(2) - state.getFinalScore(1);
      final plyAdjustment = ply * 45.0;

      if (winner == 2) {
        return 200000 + (finalMargin * 16) - plyAdjustment;
      }
      if (winner == 1) {
        return -200000 + (finalMargin * 16) + plyAdjustment;
      }
      return finalMargin * 16;
    }

    final endgamePhase = _endgamePhase(state);
    final currentMargin = state.getScore(2) - state.getScore(1);
    final projectedMargin = state.getFinalScore(2) - state.getFinalScore(1);
    final reserveMargin = projectedMargin - currentMargin;

    var score = 0.0;
    score += currentMargin * (16.0 - (endgamePhase * 6.0));
    score += reserveMargin * (6.0 + (endgamePhase * 18.0));
    score += _evaluateMaterial(state) * 1.45;
    score += _evaluateDamaDominance(state) * 5.4;
    score += _evaluateBoardControl(state) * 4.0;
    score += _evaluatePieceSafety(state) * 6.0;
    score += _evaluatePromotionPotential(state) * 3.5;
    score += _evaluateOperationTileControl(state) * 2.5;
    score += _evaluateCapturePressure(state) * 4.8;
    score += _evaluateMobility(state) * 2.6;
    score += _evaluateTrappedPieces(state) * 3.2;
    score += _evaluateBackRankGuard(state) * 2.4;
    score += _evaluateTempo(state) * 3.8;
    score += _evaluateConversionBias(state, projectedMargin, endgamePhase);
    return score;
  }

  double _evaluateMaterial(GameLogic state) {
    var score = 0.0;

    for (final chip in state.chips) {
      final chipValue = _chipStrategicValue(chip);
      score += chip.owner == 2 ? chipValue : -chipValue;
    }

    return score;
  }

  double _evaluateDamaDominance(GameLogic state) {
    var score = 0.0;

    for (final chip in state.chips.where((chip) => chip.isDama)) {
      final mobility = state.getValidMoves(chip).length.toDouble();
      var chipScore = 30 + (mobility * 2.6);

      if (_isThreatened(state, chip.x, chip.y, chip.owner)) {
        chipScore -= 18;
      } else {
        chipScore += 6;
      }

      score += chip.owner == 2 ? chipScore : -chipScore;
    }

    return score;
  }

  double _evaluateBoardControl(GameLogic state) {
    var score = 0.0;

    for (final chip in state.chips) {
      final centerDistance = (3.5 - chip.x).abs() + (3.5 - chip.y).abs();
      var chipScore = (7 - centerDistance) * 1.6;

      if (!chip.isDama) {
        chipScore += chip.owner == 2 ? (7 - chip.y) * 1.5 : chip.y * 1.5;
      }

      if (_isEdgeSquare(chip.x, chip.y)) {
        chipScore += chip.isDama ? 2 : 4;
      }

      score += chip.owner == 2 ? chipScore : -chipScore;
    }

    return score;
  }

  double _evaluatePieceSafety(GameLogic state) {
    final aiThreatenedIds = _capturableChipIds(state, attackerOwner: 1);
    final playerThreatenedIds = _capturableChipIds(state, attackerOwner: 2);
    var score = 0.0;

    for (final chip in state.chips) {
      final threatened = chip.owner == 2
          ? aiThreatenedIds.contains(chip.id)
          : playerThreatenedIds.contains(chip.id);
      final defended = _isDefended(state, chip.x, chip.y, chip.owner);

      var chipScore = 0.0;
      if (defended) chipScore += 7;
      if (threatened) chipScore -= chip.isDama ? 36 : 18;
      if (!defended && !threatened) chipScore -= 2;

      score += chip.owner == 2 ? chipScore : -chipScore;
    }

    return score;
  }

  double _evaluatePromotionPotential(GameLogic state) {
    var score = 0.0;

    for (final chip in state.chips) {
      if (chip.isDama) {
        continue;
      }

      final distanceToPromotion = chip.owner == 2 ? chip.y : (7 - chip.y);
      final promotionBonus =
          (7 - distanceToPromotion) *
          (2.6 + (_endgameReserveValue(chip) * 0.08));
      score += chip.owner == 2 ? promotionBonus : -promotionBonus;
    }

    return score;
  }

  double _evaluateOperationTileControl(GameLogic state) {
    var score = 0.0;

    for (final chip in state.chips) {
      final operation = state.getOperationAt(chip.x, chip.y);
      if (operation == null || operation.isEmpty) {
        continue;
      }
      score += chip.owner == 2 ? 10 : -10;
    }

    final aiOperationMoves = state
        .getLegalMovesForPlayer(2)
        .where(
          (move) => (state.getOperationAt(move.toX, move.toY) ?? '').isNotEmpty,
        )
        .length;
    final playerOperationMoves = state
        .getLegalMovesForPlayer(1)
        .where(
          (move) => (state.getOperationAt(move.toX, move.toY) ?? '').isNotEmpty,
        )
        .length;

    score += (aiOperationMoves - playerOperationMoves) * 4;
    return score;
  }

  double _evaluateCapturePressure(GameLogic state) {
    var aiCaptures = 0.0;
    for (final chip in state.chips.where((chip) => chip.owner == 2)) {
      for (final capture in state.getAvailableCaptures(chip)) {
        aiCaptures += 18 + (_chipStrategicValue(capture.capturedChip) * 0.12);
      }
    }

    var playerCaptures = 0.0;
    for (final chip in state.chips.where((chip) => chip.owner == 1)) {
      for (final capture in state.getAvailableCaptures(chip)) {
        playerCaptures +=
            18 + (_chipStrategicValue(capture.capturedChip) * 0.12);
      }
    }

    return aiCaptures - playerCaptures;
  }

  double _evaluateMobility(GameLogic state) {
    final aiMoves = state.getLegalMovesForPlayer(2).length;
    final playerMoves = state.getLegalMovesForPlayer(1).length;
    return (aiMoves - playerMoves).toDouble();
  }

  double _evaluateTrappedPieces(GameLogic state) {
    var score = 0.0;

    for (final chip in state.chips) {
      final mobility = state.getValidMoves(chip).length;
      if (mobility > 1) {
        continue;
      }

      score += chip.owner == 2 ? -8 : 8;
    }

    return score;
  }

  double _evaluateTempo(GameLogic state) {
    var tempo = state.currentPlayer == 2 ? 7.0 : -7.0;

    if (state.mustContinueCapturing) {
      tempo += state.currentPlayer == 2 ? 28 : -28;
    }

    return tempo;
  }

  double _evaluateBackRankGuard(GameLogic state) {
    final aiBackRank = state.chips
        .where((chip) => chip.owner == 2 && !chip.isDama && chip.y == 7)
        .length;
    final playerBackRank = state.chips
        .where((chip) => chip.owner == 1 && !chip.isDama && chip.y == 0)
        .length;

    return (aiBackRank - playerBackRank) * 4.0;
  }

  double _evaluateConversionBias(
    GameLogic state,
    double projectedMargin,
    double endgamePhase,
  ) {
    if (endgamePhase < 0.35) {
      return 0;
    }

    final pieceCountDiff = state.getChipCount(2) - state.getChipCount(1);
    final reserveDiff =
        state.getFinalScore(2) -
        state.getScore(2) -
        (state.getFinalScore(1) - state.getScore(1));
    final simplificationPressure = (24 - state.chips.length).toDouble();

    if (projectedMargin > 0) {
      return pieceCountDiff * 7.5 +
          simplificationPressure * 2.2 +
          reserveDiff * 0.65;
    }

    if (projectedMargin < 0) {
      return -pieceCountDiff * 6.0 -
          simplificationPressure * 1.8 -
          reserveDiff * 0.45;
    }

    return 0;
  }

  Set<int> _capturableChipIds(GameLogic state, {required int attackerOwner}) {
    final threatenedIds = <int>{};

    for (final attacker in state.chips.where(
      (chip) => chip.owner == attackerOwner,
    )) {
      for (final capture in state.getAvailableCaptures(attacker)) {
        threatenedIds.add(capture.capturedChip.id);
      }
    }

    return threatenedIds;
  }

  bool _isThreatened(GameLogic state, int x, int y, int owner) {
    for (final opponent in state.chips.where((chip) => chip.owner != owner)) {
      for (final capture in state.getAvailableCaptures(opponent)) {
        if (capture.capturedChip.x == x && capture.capturedChip.y == y) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isDefended(GameLogic state, int x, int y, int owner) {
    for (final ally in state.chips.where((chip) => chip.owner == owner)) {
      if (ally.x == x && ally.y == y) {
        continue;
      }

      if ((ally.x - x).abs() == 1 && (ally.y - y).abs() == 1) {
        return true;
      }

      if (ally.isDama && (ally.x - x).abs() == (ally.y - y).abs()) {
        return true;
      }
    }

    return false;
  }

  bool _isEdgeSquare(int x, int y) {
    return x == 0 || x == 7 || y == 0 || y == 7;
  }

  double _endgameReserveValue(ChipModel chip) {
    final reserveValue = _polynomialMagnitude(chip.terms).toDouble();
    return chip.isDama ? reserveValue * 2.0 : reserveValue;
  }

  double _endgamePhase(GameLogic state) {
    final piecesGone = (24 - state.chips.length).clamp(0, 24).toDouble();
    final piecePhase = piecesGone / 24.0;
    final damaPhase = min(
      1.0,
      (state.getDamaCount(1) + state.getDamaCount(2)) / 6.0,
    );
    return min(1.0, (piecePhase * 0.75) + (damaPhase * 0.25));
  }

  int _polynomialMagnitude(Map<int, int> terms) {
    var total = 0;
    for (final entry in terms.entries) {
      total += entry.value.abs();
    }
    return total;
  }

  String _buildStateCacheKey(GameLogic state) {
    final buffer = StringBuffer()
      ..write('P${state.currentPlayer}')
      ..write('|C${state.mustContinueCapturing ? 1 : 0}');

    final chainChip = state.currentChainChipModel;
    if (chainChip != null) {
      buffer.write('|CHAIN:${chainChip.id}:${chainChip.x},${chainChip.y}');
    }

    buffer
      ..write('|S1:${state.player1Score.toStringAsFixed(2)}')
      ..write('|S2:${state.player2Score.toStringAsFixed(2)}');

    final sortedChips = List<ChipModel>.from(state.chips)
      ..sort((a, b) => a.id.compareTo(b.id));

    for (final chip in sortedChips) {
      buffer
        ..write('|')
        ..write(chip.id)
        ..write(':')
        ..write(chip.owner)
        ..write(':')
        ..write(chip.x)
        ..write(',')
        ..write(chip.y)
        ..write(':')
        ..write(chip.isDama ? 1 : 0)
        ..write(':')
        ..write(_termsKey(chip.terms));
    }

    return buffer.toString();
  }

  String _termsKey(Map<int, int> terms) {
    final entries = terms.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => '${entry.key}:${entry.value}').join(',');
  }
}

class _DexterProfile {
  final int maxDepth;
  final int quiescenceDepth;
  final int timeBudgetMs;
  final int softNodeLimit;

  const _DexterProfile({
    required this.maxDepth,
    required this.quiescenceDepth,
    required this.timeBudgetMs,
    required this.softNodeLimit,
  });
}

class _ScoredMove {
  final Move move;
  final double score;

  const _ScoredMove({required this.move, required this.score});
}

class _OpeningRule {
  final String name;
  final List<_BookHistoryMove> history;
  final _BookMove response;

  const _OpeningRule({
    required this.name,
    required this.history,
    required this.response,
  });

  bool matches(List<MoveHistoryEntry> actualHistory) {
    if (actualHistory.length != history.length) {
      return false;
    }

    for (var i = 0; i < history.length; i++) {
      if (!history[i].matches(actualHistory[i])) {
        return false;
      }
    }

    return true;
  }
}

class _BookHistoryMove {
  final int player;
  final int fromX;
  final int fromY;
  final int toX;
  final int toY;
  final bool? isCapture;

  const _BookHistoryMove({
    required this.player,
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    this.isCapture,
  });

  bool matches(MoveHistoryEntry entry) {
    if (entry.player != player ||
        entry.fromX != fromX ||
        entry.fromY != fromY ||
        entry.toX != toX ||
        entry.toY != toY) {
      return false;
    }

    if (isCapture != null && entry.isCapture != isCapture) {
      return false;
    }

    return true;
  }
}

class _BookMove {
  final int fromX;
  final int fromY;
  final int toX;
  final int toY;
  final bool? isCapture;

  const _BookMove({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    this.isCapture,
  });

  bool matches(Move move) {
    if (move.fromX != fromX ||
        move.fromY != fromY ||
        move.toX != toX ||
        move.toY != toY) {
      return false;
    }

    if (isCapture != null && move.isCapture != isCapture) {
      return false;
    }

    return true;
  }
}

class _RootSearchResult {
  final Move move;
  final double score;

  const _RootSearchResult({required this.move, required this.score});
}

class _TranspositionEntry {
  final double score;
  final int depth;
  final _SearchBound bound;
  final String? bestMoveKey;

  const _TranspositionEntry({
    required this.score,
    required this.depth,
    required this.bound,
    this.bestMoveKey,
  });
}

enum _SearchBound { exact, lower, upper }

class _SearchTimeout implements Exception {
  const _SearchTimeout();
}
