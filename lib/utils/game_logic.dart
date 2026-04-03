import 'package:logging/logging.dart';
import 'package:derivative_damath/models/chip_model.dart';
import 'package:derivative_damath/models/operation_model.dart';
import 'package:derivative_damath/models/game_state_model.dart';
import 'package:derivative_damath/models/player_model.dart';
import 'package:derivative_damath/models/move_history_model.dart';
import 'package:derivative_damath/utils/derivative_rules.dart';
import 'package:derivative_damath/utils/score_calculator.dart';
import 'initial_positions.dart';
import 'operations_layout.dart';

/// Represents a move in the game.
class Move {
  final int fromX;
  final int fromY;
  final int toX;
  final int toY;
  final bool isCapture;
  final Map<int, int>? capturedChipTerms;

  Move({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    this.isCapture = false,
    this.capturedChipTerms,
  });

  @override
  String toString() =>
      'Move(($fromX,$fromY) -> ($toX,$toY), capture: $isCapture)';
}

/// Represents a capture move with details.
class CaptureMove {
  final int fromX;
  final int fromY;
  final int toX;
  final int toY;
  final int midX;
  final int midY;
  final ChipModel capturedChip;

  CaptureMove({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    required this.midX,
    required this.midY,
    required this.capturedChip,
  });
}

class GameLogic {
  List<ChipModel> chips = [];
  ChipModel? selectedChip;
  int currentPlayer = 1; // 1 = blue, 2 = red

  // Score tracking (now using double for PDF-compliant scoring)
  double player1Score = 0;
  double player2Score = 0;

  // Last move result for feedback
  MoveResult? lastMoveResult;
  String? lastErrorMessage;

  // ==================== PHASE 3: GAME MECHANICS ====================

  // Double Jump / Chain Capture tracking
  bool mustContinueCapture = false;
  ChipModel? currentChainChip;
  int captureChainDepth = 0;

  // Win/Lose Detection
  GamePhase gamePhase = GamePhase.playing;
  PlayerModel? winner;

  // Position tracking for draw detection
  final List<String> positionHistory = [];
  static const int maxPositionRepeats = 3;

  // Move history tracking for the moves history feature
  final List<MoveHistoryEntry> moveHistory = [];
  int _moveCounter = 0;
  bool _endgameBonusesRecorded = false;

  // Create a logger instance
  final Logger _logger = Logger('GameLogic');

  GameLogic() {
    setupLogging();
    initializeChips();
  }

  // Setup logging configuration
  void setupLogging() {
    // For testing compatibility, use a simpler logging setup
    // that doesn't cause async issues
  }

  // Initializes the game chips
  void initializeChips() {
    chips = getInitialChips();
    _recordPosition();
  }

  // Records the current position for draw detection
  void _recordPosition() {
    final position = _getPositionSignature();
    positionHistory.add(position);

    // Keep only recent positions
    if (positionHistory.length > 20) {
      positionHistory.removeAt(0);
    }
  }

  // Gets a signature string for the current position
  String _getPositionSignature() {
    final buffer = StringBuffer();
    final sortedChips = List<ChipModel>.from(chips)
      ..sort(
        (a, b) =>
            '${a.owner},${a.x},${a.y}'.compareTo('${b.owner},${b.x},${b.y}'),
      );
    for (final chip in sortedChips) {
      buffer.write('${chip.owner}:${chip.x},${chip.y}:${chip.isDama};');
    }
    buffer.write('P$currentPlayer');
    return buffer.toString();
  }

  // Checks if position has repeated maxPositionRepeats times (for draw)
  bool _hasRepeatedPosition() {
    final current = _getPositionSignature();
    int count = 0;
    for (final pos in positionHistory) {
      if (pos == current) count++;
    }
    return count >= maxPositionRepeats;
  }

  // ==================== MOVE HISTORY TRACKING ====================

  /// Records a move in the move history
  void _recordMove({
    required int fromX,
    required int fromY,
    required int toX,
    required int toY,
    required Map<int, int> chipTerms,
    bool isCapture = false,
    String? capturedChipTerms,
    String operation = '',
    double pointsEarned = 0,
    String calculationDetails = '',
    bool isDamaPromotion = false,
    int captureCount = 0,
    CalculationBreakdown? calculationBreakdown,
  }) {
    _moveCounter++;
    final historyPlayer = currentPlayer;

    final entry = MoveHistoryEntry(
      moveNumber: _moveCounter,
      player: historyPlayer,
      fromX: _historyCoordinateX(fromX, historyPlayer),
      fromY: _historyCoordinateY(fromY, historyPlayer),
      toX: _historyCoordinateX(toX, historyPlayer),
      toY: _historyCoordinateY(toY, historyPlayer),
      isCapture: isCapture,
      isEndgameBonus: false,
      capturedChipTerms: capturedChipTerms,
      operation: operation,
      pointsEarned: pointsEarned,
      calculationDetails: calculationDetails,
      chipTerms: _formatTerms(chipTerms),
      isDamaPromotion: isDamaPromotion,
      captureCount: captureCount > 0 ? captureCount : (isCapture ? 1 : 0),
      calculationBreakdown: calculationBreakdown,
    );

    moveHistory.add(entry);
    _logger.info(
      'Recorded move #$_moveCounter: Player $historyPlayer $entry.moveString',
    );
  }

  void _recordEndgameBonusEntry({
    required int playerNumber,
    required double bonus,
    required String calculationDetails,
  }) {
    _moveCounter++;

    final entry = MoveHistoryEntry(
      moveNumber: _moveCounter,
      player: playerNumber,
      fromX: 0,
      fromY: 0,
      toX: 0,
      toY: 0,
      isEndgameBonus: true,
      pointsEarned: bonus,
      calculationDetails: calculationDetails,
    );

    moveHistory.add(entry);
    _logger.info(
      'Recorded move #$_moveCounter: Player $playerNumber endgame bonus ${bonus.toStringAsFixed(2)}',
    );
  }

  int _historyCoordinateX(int x, int playerNumber) {
    return playerNumber == 2 ? 7 - x : x;
  }

  int _historyCoordinateY(int y, int playerNumber) {
    return playerNumber == 2 ? 7 - y : y;
  }

  String _historyCoordinateLabel(int x, int y, int playerNumber) {
    final displayX = _historyCoordinateX(x, playerNumber);
    final displayY = _historyCoordinateY(y, playerNumber);
    return '($displayX, $displayY)';
  }

  /// Formats polynomial terms as a readable string
  String _formatTerms(Map<int, int> terms) {
    if (terms.isEmpty) return '0';

    final buffer = StringBuffer();
    final sortedEntries = terms.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final exp = entry.key;
      final coeff = entry.value;

      if (coeff == 0) continue;

      if (i > 0) {
        buffer.write(coeff > 0 ? ' + ' : ' - ');
      } else if (coeff < 0) {
        buffer.write('-');
      }

      final absCoeff = coeff.abs();
      if (exp == 0) {
        buffer.write(absCoeff);
      } else if (absCoeff == 1) {
        buffer.write('x');
      } else {
        buffer.write('${absCoeff}x');
      }

      if (exp > 1) buffer.write('^$exp');
    }

    return buffer.toString();
  }

  /// Gets the move history (public getter)
  List<MoveHistoryEntry> get history => List.unmodifiable(moveHistory);

  /// Clears the move history
  void clearHistory() {
    moveHistory.clear();
    _moveCounter = 0;
    _endgameBonusesRecorded = false;
  }

  // ==================== TILE TAP HANDLING ====================

  /// Simulate tile tap (a player making a move or capturing)
  void onTileTap(int x, int y) {
    // If game is over, ignore taps
    if (gamePhase != GamePhase.playing) {
      lastErrorMessage = 'Game is over';
      return;
    }

    // If must continue capture, handle specially
    if (mustContinueCapture) {
      _handleChainCaptureTap(x, y);
      return;
    }

    // Check if any capture is available for current player (must capture rule)
    final bool captureAvailable = hasAnyCaptureAvailable(currentPlayer);

    // Normal selection/move handling
    if (selectedChip == null) {
      // Try to select a chip
      final chip = chipAt(x, y);
      if (chip != null && chip.owner == currentPlayer) {
        // Must capture rule: if capture is available, can only select chips that can capture
        if (captureAvailable) {
          if (chipCanCapture(chip)) {
            selectedChip = chip;
            _logger.info('Selected capturing chip at ($x, $y)');
          } else {
            lastErrorMessage = 'Capture is available - must capture!';
            _logger.warning(
              'Cannot select non-capturing chip when capture is available',
            );
          }
        } else {
          // No capture available - can select any chip
          selectedChip = chip;
          _logger.info('Selected chip at ($x, $y)');
        }
      }
      return;
    }

    // If tapping on own chip, change selection (respecting must capture rule)
    final tappedChip = chipAt(x, y);
    if (tappedChip != null && tappedChip.owner == currentPlayer) {
      // Must capture rule: if capture is available, can only select chips that can capture
      if (captureAvailable) {
        if (chipCanCapture(tappedChip)) {
          selectedChip = tappedChip;
          _logger.info('Changed selection to capturing chip at ($x, $y)');
        } else {
          lastErrorMessage = 'Capture is available - must capture!';
          _logger.warning(
            'Cannot select non-capturing chip when capture is available',
          );
        }
      } else {
        // No capture available - can select any chip
        selectedChip = tappedChip;
        _logger.info('Changed selection to chip at ($x, $y)');
      }
      return;
    }

    // Try to make a move or capture
    final direction = currentPlayer == 1 ? 1 : -1;

    // Check for capture first
    if (_canCapture(x, y, direction)) {
      _executeCapture(x, y);
    } else if (_canMove(x, y, direction)) {
      // Must capture rule: if capture is available, cannot make regular move
      if (captureAvailable) {
        lastErrorMessage = 'Capture is available - must capture!';
        _logger.warning('Cannot make regular move when capture is available');
        return;
      }
      _executeMove(x, y);
    } else {
      lastErrorMessage = 'Invalid move';
      _logger.warning(
        'Invalid move attempt from (${selectedChip!.x},${selectedChip!.y}) to ($x, $y)',
      );
    }
  }

  /// Handle taps during chain capture
  void _handleChainCaptureTap(int x, int y) {
    // Only allow the chaining chip to be selected/used
    if (selectedChip != currentChainChip) {
      selectedChip = currentChainChip;
    }

    final direction = currentPlayer == 1 ? 1 : -1;

    // Try to make another capture
    if (_canCapture(x, y, direction)) {
      _executeCapture(x, y);
    } else {
      lastErrorMessage = 'Must continue capturing!';
      _logger.warning(
        'Player must continue capturing, but invalid tap at ($x, $y)',
      );
    }
  }

  // ==================== MOVEMENT LOGIC ====================

  /// Check if a move to (x, y) is valid
  bool _canMove(int x, int y, int direction) {
    if (selectedChip == null || isOccupied(x, y)) return false;

    final dx = x - selectedChip!.x;
    final dy = y - selectedChip!.y;

    // Dama can move in both diagonal directions (forward and backward)
    if (selectedChip!.isDama) {
      // Multi-square slide for Dama - diagonal only
      if (dx.abs() == dy.abs()) {
        // Check if path is clear for multi-square move
        return _isPathClear(selectedChip!.x, selectedChip!.y, x, y);
      }
      return false;
    }

    // Regular chip: diagonal only, 1 square
    // Damath rules: chips move diagonally to capture/interact
    return dx.abs() == 1 && dy == direction;
  }

  /// Check if path is clear for multi-square Dama movement
  bool _isPathClear(int fromX, int fromY, int toX, int toY) {
    final dx = (toX - fromX).sign;
    final dy = (toY - fromY).sign;

    int x = fromX + dx;
    int y = fromY + dy;

    while (x != toX || y != toY) {
      if (isOccupied(x, y)) return false;
      x += dx;
      y += dy;
    }

    return true;
  }

  /// Check if capture is possible
  bool _canCapture(int x, int y, int direction) {
    if (selectedChip == null) return false;

    // Check bounds first
    if (x < 0 || x > 7 || y < 0 || y > 7) return false;

    final dx = x - selectedChip!.x;
    final dy = y - selectedChip!.y;

    // Dama can capture in any direction (forward and backward)
    if (selectedChip!.isDama) {
      return _canCaptureDama(x, y, dx, dy);
    }

    // Regular chip: can capture forward AND backward
    // Allow both forward (direction) and backward (-direction) captures
    if (dx.abs() != 2) return false;
    if (dy != 2 * direction && dy != 2 * -direction) return false;

    final midX = (x + selectedChip!.x) ~/ 2;
    final midY = (y + selectedChip!.y) ~/ 2;
    final midChip = chipAt(midX, midY);

    return midChip != null &&
        isOpponent(selectedChip!, midChip) &&
        !isOccupied(x, y);
  }

  /// Check if Dama can capture exactly one opponent chip along a diagonal.
  /// The landing square may be any empty square after that one captured chip.
  bool _canCaptureDama(int x, int y, int dx, int dy) {
    // Check bounds
    if (x < 0 || x > 7 || y < 0 || y > 7) return false;

    // Dama can capture at distances 2-7 (long-distance capture)
    // Must be at least 2 squares away
    if (dx.abs() < 2 || dy.abs() < 2) return false;
    // Must be diagonal (square of movement)
    if (dx.abs() != dy.abs()) return false;
    if (isOccupied(x, y)) return false;

    // Find an opponent chip along the diagonal path before the landing spot.
    // The path validator below ensures it is the only chip crossed.
    final dist = dx.abs();
    final dxSign = dx.sign;
    final dySign = dy.sign;

    // Scan backward from landing position to find an opponent chip
    int? foundMidX;
    int? foundMidY;

    for (int d = 1; d < dist; d++) {
      final checkX = selectedChip!.x + dxSign * d;
      final checkY = selectedChip!.y + dySign * d;
      final checkChip = chipAt(checkX, checkY);

      if (checkChip != null && isOpponent(selectedChip!, checkChip)) {
        // Found an opponent chip - this will be the captured chip
        foundMidX = checkX;
        foundMidY = checkY;
        break;
      }
    }

    // Must find an opponent chip to capture
    if (foundMidX == null || foundMidY == null) return false;

    // Check if path is clear (excluding the captured chip position)
    // Pass selectedChip to check if blocking chips are opponents or team chips
    return _isPathClearForCaptureFlexible(
      selectedChip!.x,
      selectedChip!.y,
      x,
      y,
      selectedChip!,
      foundMidX,
      foundMidY,
    );
  }

  /// Check if a Dama capture path crosses exactly one opponent chip.
  /// Every other intermediate square must be empty.
  bool _isPathClearForCaptureFlexible(
    int fromX,
    int fromY,
    int toX,
    int toY,
    ChipModel capturingChip,
    int capturedX,
    int capturedY,
  ) {
    final dx = (toX - fromX).sign;
    final dy = (toY - fromY).sign;

    int x = fromX + dx;
    int y = fromY + dy;
    var crossedCapturedChip = false;

    while (x != toX || y != toY) {
      final chip = chipAt(x, y);

      final isCapturedPosition = x == capturedX && y == capturedY;

      if (isCapturedPosition) {
        if (chip == null || !isOpponent(capturingChip, chip)) {
          return false;
        }
        crossedCapturedChip = true;
      } else if (chip != null) {
        return false;
      }

      x += dx;
      y += dy;
    }

    return crossedCapturedChip;
  }

  // ==================== EXECUTE MOVE/CAPTURE ====================

  /// Execute a regular move
  void _executeMove(int x, int y) {
    _logger.info(
      'Executing move from (${selectedChip!.x},${selectedChip!.y}) to ($x, $y)',
    );

    // Store previous position for history
    final fromX = selectedChip!.x;
    final fromY = selectedChip!.y;
    final chipTerms = Map<int, int>.from(selectedChip!.terms);

    // Check for operation tile
    final moveResult = processOperationMove(x, y);

    if (!moveResult.isValid) {
      lastErrorMessage = lastErrorMessage ?? 'Invalid move';
      return;
    }

    // Move the chip
    selectedChip!.x = x;
    selectedChip!.y = y;

    // Check for Dama promotion after move
    final isDamaPromotion = _checkAndPromoteDama(x, y);

    // Get the operation at target position
    final operation = getOperationAt(x, y) ?? '';

    // Record this move in history
    _recordMove(
      fromX: fromX,
      fromY: fromY,
      toX: x,
      toY: y,
      chipTerms: chipTerms,
      isCapture: false,
      operation: operation,
      pointsEarned: 0, // Regular moves don't earn points per PDF spec
      calculationDetails: isDamaPromotion
          ? 'Chip promoted to Dama at row ${y + 1}'
          : 'Moved to position ${_historyCoordinateLabel(x, y, currentPlayer)}',
      isDamaPromotion: isDamaPromotion,
    );

    // Record position for draw detection
    _recordPosition();

    // Check for win condition
    _evaluateGameState();

    // End turn if game not over
    if (gamePhase == GamePhase.playing) {
      _endTurn();
    }
  }

  /// Execute a capture
  void _executeCapture(int x, int y) {
    // Store previous position for history
    final fromX = selectedChip!.x;
    final fromY = selectedChip!.y;
    final chipTerms = Map<int, int>.from(selectedChip!.terms);

    // Check for Dama promotion before capture (Dama can capture from promotion row)
    final willPromote = _checkAndPromoteDama(x, y);

    int captureMidX, captureMidY;

    // Calculate distance for long-distance capture support
    final dx = x - selectedChip!.x;
    final dy = y - selectedChip!.y;
    final dist = dx.abs(); // Distance in squares

    if (selectedChip!.isDama) {
      // For Dama: find the opponent chip by scanning backward from landing position
      final dxSign = dx.sign;
      final dySign = dy.sign;

      // Scan backward from landing position to find the first opponent chip
      captureMidX = -1;
      captureMidY = -1;

      for (int d = 1; d < dist; d++) {
        final checkX = selectedChip!.x + dxSign * d;
        final checkY = selectedChip!.y + dySign * d;
        final checkChip = chipAt(checkX, checkY);

        if (checkChip != null && isOpponent(selectedChip!, checkChip)) {
          captureMidX = checkX;
          captureMidY = checkY;
          break;
        }
      }

      // Fallback to old behavior if no chip found (shouldn't happen with valid capture)
      if (captureMidX == -1) {
        captureMidX = selectedChip!.x + dx.sign * (dist - 1);
        captureMidY = selectedChip!.y + dy.sign * (dist - 1);
      }
    } else {
      // Regular chip: always distance 2
      captureMidX = (x + selectedChip!.x) ~/ 2;
      captureMidY = (y + selectedChip!.y) ~/ 2;
    }

    final capturedChip = chipAt(captureMidX, captureMidY);

    if (capturedChip == null || !isOpponent(selectedChip!, capturedChip)) {
      lastErrorMessage = 'No opponent to capture';
      return;
    }

    _logger.info(
      'Executing capture from (${selectedChip!.x},${selectedChip!.y}) to ($x, $y), capturing at ($captureMidX, $captureMidY)',
    );

    // Store captured chip terms before removing
    final capturedChipTerms = Map<int, int>.from(capturedChip.terms);
    final capturedChipTermsStr = _formatTerms(capturedChipTerms);
    final takerWasDama = selectedChip!.isDama;

    // Remove captured chip
    chips.remove(capturedChip);

    // Move the capturing chip
    selectedChip!.x = x;
    selectedChip!.y = y;

    // Increment chain depth
    captureChainDepth++;

    // Check for Dama promotion after capture (if not already promoted)
    final promoted = willPromote || _checkAndPromoteDama(x, y);

    // Check if another capture is available
    final canContinue = _hasAnotherCapture();

    if (canContinue) {
      // Must continue capturing
      mustContinueCapture = true;
      currentChainChip = selectedChip;
      _logger.info(
        'Chain capture available, must continue. Depth: $captureChainDepth',
      );
    } else {
      // End of capture chain
      mustContinueCapture = false;
      currentChainChip = null;
    }

    // Calculate score for this capture using the landing tile operation.
    double moveScore = 0;
    String calcDetails = '';

    final operationSymbol = getOperationAt(x, y);
    if (operationSymbol != null) {
      moveScore = ScoreCalculator.calculateScorePDF(
        movingChipTerms: chipTerms,
        targetChipTerms: capturedChip.terms,
        operationSymbol: operationSymbol,
        targetX: x,
        targetY: y,
        isCapture: true,
        isDamaPromotion: promoted,
        isMovingChipDama: takerWasDama,
        isTargetChipDama: capturedChip.isDama,
      );

      final xValue = (x - y).abs();
      final damaMultiplier = ScoreCalculator.calculateDamaMultiplier(
        isMovingChipDama: takerWasDama,
        isTargetChipDama: capturedChip.isDama,
      );
      calcDetails =
          '${_formatTerms(chipTerms)} $operationSymbol ${_formatTerms(capturedChipTerms)} -> score at x=$xValue = ${moveScore.toStringAsFixed(2)}';
      if (damaMultiplier > 1) {
        calcDetails += ' (${damaMultiplier}x Dama multiplier)';
      }
    }

    // Get the operation symbol for history
    final operation = operationSymbol ?? '';

    // Generate detailed calculation breakdown for capture moves
    CalculationBreakdown? calcBreakdown;
    if (operationSymbol != null) {
      calcBreakdown = ScoreCalculator.generateCalculationBreakdown(
        movingChipTerms: chipTerms,
        targetChipTerms: capturedChipTerms,
        operationSymbol: operationSymbol,
        targetX: x,
        targetY: y,
        isMovingChipDama: takerWasDama,
        isTargetChipDama: capturedChip.isDama,
      );
    }

    // Record this capture in history
    _recordMove(
      fromX: fromX,
      fromY: fromY,
      toX: x,
      toY: y,
      chipTerms: chipTerms,
      isCapture: true,
      capturedChipTerms: capturedChipTermsStr,
      operation: operation,
      pointsEarned: moveScore,
      calculationDetails: calcDetails.isNotEmpty
          ? calcDetails
          : 'Captured chip at ${_historyCoordinateLabel(captureMidX, captureMidY, currentPlayer)}',
      isDamaPromotion: promoted,
      captureCount: captureChainDepth,
      calculationBreakdown: calcBreakdown,
    );

    _updateScore(moveScore);

    // Record position for draw detection
    _recordPosition();

    // Check for win condition
    _evaluateGameState();

    // End turn if no more captures or game over
    if (!mustContinueCapture && gamePhase == GamePhase.playing) {
      _endTurn();
    }
  }

  /// Check if chip can capture again from current position
  bool _hasAnotherCapture() {
    if (selectedChip == null) return false;

    // Dama can capture in all diagonal directions at distances 2-7
    // With flexible landing: check all possible captures using getAvailableCaptures
    if (selectedChip!.isDama) {
      final captures = getAvailableCaptures(selectedChip!);
      return captures.isNotEmpty;
    }

    // Regular chip: can capture forward AND backward
    // Player 1 at top moves DOWN (+1), Player 2 at bottom moves UP (-1)
    final forwardDir = currentPlayer == 1 ? 1 : -1;
    final backwardDir = -forwardDir;

    // Check forward captures
    final forwardCaptureX = selectedChip!.x + 2;
    final forwardCaptureY = selectedChip!.y + 2 * forwardDir;
    if (_canCapture(forwardCaptureX, forwardCaptureY, forwardDir)) return true;

    final forwardCaptureX2 = selectedChip!.x - 2;
    if (_canCapture(forwardCaptureX2, forwardCaptureY, forwardDir)) return true;

    // Check backward captures
    final backwardCaptureX = selectedChip!.x + 2;
    final backwardCaptureY = selectedChip!.y + 2 * backwardDir;
    if (_canCapture(backwardCaptureX, backwardCaptureY, backwardDir)) {
      return true;
    }

    final backwardCaptureX2 = selectedChip!.x - 2;
    if (_canCapture(backwardCaptureX2, backwardCaptureY, backwardDir)) {
      return true;
    }

    return false;
  }

  /// Check if the player must continue capturing (public getter)
  bool get mustContinueCapturing => mustContinueCapture;

  /// Get the current chain chip (the chip that must continue capturing)
  ChipModel? get currentChainChipModel => currentChainChip;

  /// Check if any capture is available for the current player (public getter for must capture rule)
  bool get isCaptureAvailable => hasAnyCaptureAvailable(currentPlayer);

  /// Get chips that can capture for the current player
  List<ChipModel> get capturingChips => getChipsThatCanCapture(currentPlayer);

  /// End the current player's turn
  void _endTurn() {
    currentPlayer = currentPlayer == 1 ? 2 : 1;
    selectedChip = null;
    captureChainDepth = 0;
    // Reset chain capture state
    mustContinueCapture = false;
    currentChainChip = null;
    _logger.info('Turn ended. Current player: $currentPlayer');
  }

  /// Update player score (now uses double for PDF-compliant scoring)
  void _updateScore(double score) {
    if (currentPlayer == 1) {
      player1Score += score;
    } else {
      player2Score += score;
    }
    _logger.info(
      'Score updated. Player 1: $player1Score, Player 2: $player2Score',
    );
  }

  // ==================== DAMA PROMOTION ====================

  /// Check and promote chip to Dama if applicable
  bool _checkAndPromoteDama(int x, int y) {
    if (selectedChip == null || selectedChip!.isDama) return false;

    // Player 1 (blue) promotes at row 7 (bottom) - moved to bottom
    if (currentPlayer == 1 && y == 7) {
      selectedChip!.isDama = true;
      _logger.info('Player 1 chip promoted to Dama at ($x, $y)');
      return true;
    }

    // Player 2 (red) promotes at row 0 (top) - moved to top
    if (currentPlayer == 2 && y == 0) {
      selectedChip!.isDama = true;
      _logger.info('Player 2 chip promoted to Dama at ($x, $y)');
      return true;
    }

    return false;
  }

  /// Check if a position is a promotion row for a player
  bool isPromotionRow(int y, int player) {
    // Player 1 promotes at row 7 (bottom), Player 2 at row 0 (top)
    return (player == 1 && y == 7) || (player == 2 && y == 0);
  }

  // ==================== VALID MOVE GETTERS ====================

  /// Get all valid moves for a chip
  /// This validates both geometric validity AND derivative requirements
  List<Move> getValidMoves(ChipModel chip) {
    final moves = <Move>[];

    // Determine allowed directions
    final directions = <List<int>>[];

    if (chip.isDama) {
      // Dama can move in all 4 diagonal directions (forward and backward)
      directions.addAll([
        [-1, -1], [1, -1], [-1, 1], [1, 1], // Diagonals only
      ]);
    } else {
      // Regular chip: diagonal only (forward only, but only diagonal directions)
      // Damath rules: chips move diagonally to capture/interact with operation tiles
      // Player 1 at top moves DOWN (+1), Player 2 at bottom moves UP (-1)
      final forwardDir = chip.owner == 1 ? 1 : -1;
      directions.addAll([
        [-1, forwardDir], [1, forwardDir], // Diagonals only - no straight moves
      ]);
    }

    for (final dir in directions) {
      // For multi-slide (Dama), check all squares in direction
      final maxSteps = chip.isDama ? 7 : 1;

      for (int step = 1; step <= maxSteps; step++) {
        final targetX = chip.x + dir[0] * step;
        final targetY = chip.y + dir[1] * step;

        // Check bounds
        if (targetX < 0 || targetX > 7 || targetY < 0 || targetY > 7) {
          break;
        }

        // Check if occupied
        if (isOccupied(targetX, targetY)) {
          // For Dama, can capture ANY opponent chip along diagonal and land at any empty tile after it
          if (chip.isDama && step > 1) {
            // Check for ANY opponent chip along the path before this position
            for (int capturedStep = 1; capturedStep < step; capturedStep++) {
              final midChip = chipAt(
                chip.x + dir[0] * capturedStep,
                chip.y + dir[1] * capturedStep,
              );
              if (midChip != null && isOpponent(chip, midChip)) {
                // Landing spot is at 'step' position (which is currently occupied, so check if path is clear beyond)
                // Actually, the target is already occupied (that's why we broke), so we need to check further
                // This logic is handled by getAvailableCaptures which is called separately
              }
            }
          }
          break;
        }

        // Valid move position - add to moves
        moves.add(
          Move(fromX: chip.x, fromY: chip.y, toX: targetX, toY: targetY),
        );

        // For regular chips, only 1 step
        if (!chip.isDama) break;
      }
    }

    // Also add captures as moves
    for (final capture in getAvailableCaptures(chip)) {
      moves.add(
        Move(
          fromX: capture.fromX,
          fromY: capture.fromY,
          toX: capture.toX,
          toY: capture.toY,
          isCapture: true,
          capturedChipTerms: capture.capturedChip.terms,
        ),
      );
    }

    // Filter moves to ensure derivative validation would pass
    // This prevents AI from selecting moves that would fail during execution
    final validatedMoves = _filterMovesByDerivativeValidation(chip, moves);

    return validatedMoves;
  }

  /// Filter moves based on derivative validation
  /// Removes moves that fail derivative validation during execution
  /// Also enforces that regular chips can only move DIAGONALLY (not forward/straight)
  List<Move> _filterMovesByDerivativeValidation(
    ChipModel chip,
    List<Move> moves,
  ) {
    final validatedMoves = <Move>[];

    for (final move in moves) {
      // For non-Dama chips, only allow diagonal moves (not straight forward)
      // This matches Damath rules: chips move diagonally to capture/interact
      if (!chip.isDama) {
        final dx = (move.toX - move.fromX).abs();

        // Only allow diagonal moves (dx == 1), NOT straight moves (dx == 0)
        // Regular chips can only move diagonally in Damath
        if (dx == 0) {
          // Skip straight moves for regular chips
          continue;
        }
      }

      // Get the operation at target position and check if there's an opponent chip there
      final targetChip = chipAt(move.toX, move.toY);

      // Derivative validation is ONLY required when moving to a tile WITH an opponent chip
      // (i.e., trying to interact with/capture that chip)
      if (targetChip != null && isOpponent(chip, targetChip)) {
        // There's an opponent chip at target - validate derivative
        final computedDerivative = computeDerivative(chip);
        final expectedResult = targetChip.terms;

        // Only include move if derivative matches
        if (!_mapsEqual(computedDerivative, expectedResult)) {
          // Derivative doesn't match - skip this move
          continue;
        }
      }

      // For all other cases (empty tile or own chip), allow the move
      // The chip can move forward even without an immediate derivative match
      validatedMoves.add(move);
    }

    return validatedMoves;
  }

  /// Get all available capture moves for a chip
  /// For Dama: allows capturing any opponent chip along diagonal and landing at any empty tile after it
  List<CaptureMove> getAvailableCaptures(ChipModel chip) {
    final captures = <CaptureMove>[];

    // Dama captures in all diagonal directions, at distances 2-7 (long-distance)
    // With flexible landing: can capture any opponent chip and land at any subsequent empty tile
    if (chip.isDama) {
      final directions = [
        [-1, -1],
        [1, -1],
        [-1, 1],
        [1, 1],
      ];

      for (final dir in directions) {
        // For each direction, scan all possible landing positions
        for (int landingDist = 2; landingDist <= 7; landingDist++) {
          final targetX = chip.x + dir[0] * landingDist;
          final targetY = chip.y + dir[1] * landingDist;

          if (targetX < 0 || targetX > 7 || targetY < 0 || targetY > 7) {
            continue;
          }
          if (isOccupied(targetX, targetY)) {
            continue; // Landing spot must be empty
          }

          // Scan backward from landing position to find opponent chips
          for (
            int capturedDist = 1;
            capturedDist < landingDist;
            capturedDist++
          ) {
            final midX = chip.x + dir[0] * capturedDist;
            final midY = chip.y + dir[1] * capturedDist;

            final midChip = chipAt(midX, midY);

            // Check: there's an opponent at mid position
            if (midChip != null && isOpponent(chip, midChip)) {
              // Check if path is clear (excluding the captured chip position)
              if (_isPathClearForCaptureFlexible(
                chip.x,
                chip.y,
                targetX,
                targetY,
                chip,
                midX,
                midY,
              )) {
                captures.add(
                  CaptureMove(
                    fromX: chip.x,
                    fromY: chip.y,
                    toX: targetX,
                    toY: targetY,
                    midX: midX,
                    midY: midY,
                    capturedChip: midChip,
                  ),
                );
              }
            }
          }
        }
      }
      return captures;
    }

    // Regular chip: captures forward AND backward
    // Player 1 at top moves DOWN (+1), Player 2 at bottom moves UP (-1)
    final forwardDir = chip.owner == 1 ? 1 : -1;
    final backwardDir = -forwardDir;

    // Forward diagonal captures
    final forwardDirections = [
      [2, 2 * forwardDir],
      [-2, 2 * forwardDir],
    ];

    // Backward diagonal captures
    final backwardDirections = [
      [2, 2 * backwardDir],
      [-2, 2 * backwardDir],
    ];

    final allDirections = [...forwardDirections, ...backwardDirections];

    for (final dir in allDirections) {
      final targetX = chip.x + dir[0];
      final targetY = chip.y + dir[1];

      if (targetX < 0 || targetX > 7 || targetY < 0 || targetY > 7) continue;

      final midX = (chip.x + targetX) ~/ 2;
      final midY = (chip.y + targetY) ~/ 2;

      final midChip = chipAt(midX, midY);
      if (midChip != null &&
          isOpponent(chip, midChip) &&
          !isOccupied(targetX, targetY)) {
        captures.add(
          CaptureMove(
            fromX: chip.x,
            fromY: chip.y,
            toX: targetX,
            toY: targetY,
            midX: midX,
            midY: midY,
            capturedChip: midChip,
          ),
        );
      }
    }

    return captures;
  }

  // ==================== MUST CAPTURE RULE ====================

  /// Check if any capture is available for a player
  /// This implements the "must capture" rule: if a capture is available,
  /// the player must capture with a chip that can capture
  bool hasAnyCaptureAvailable(int player) {
    for (final chip in chips.where((c) => c.owner == player)) {
      if (getAvailableCaptures(chip).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _hasAnyDamaCaptureAvailable(int player) {
    return chips
        .where((c) => c.owner == player && c.isDama)
        .any((chip) => getAvailableCaptures(chip).isNotEmpty);
  }

  /// Get all chips that can capture for a player
  List<ChipModel> getChipsThatCanCapture(int player) {
    final capturingChips = <ChipModel>[];
    final damaCaptureAvailable = _hasAnyDamaCaptureAvailable(player);

    for (final chip in chips.where((c) => c.owner == player)) {
      if (damaCaptureAvailable && !chip.isDama) {
        continue;
      }

      if (getAvailableCaptures(chip).isNotEmpty) {
        capturingChips.add(chip);
      }
    }
    return capturingChips;
  }

  /// Check if a specific chip can capture
  bool chipCanCapture(ChipModel chip) {
    return getChipsThatCanCapture(
      chip.owner,
    ).any((capturingChip) => capturingChip.id == chip.id);
  }

  /// Get all legal moves for a player, respecting must-capture and chain rules.
  List<Move> getLegalMovesForPlayer(int player) {
    if (player == currentPlayer &&
        mustContinueCapture &&
        currentChainChip != null) {
      return getAvailableCaptures(currentChainChip!)
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
    }

    final capturingChips = getChipsThatCanCapture(player);
    if (capturingChips.isNotEmpty) {
      return capturingChips
          .expand(
            (chip) => getAvailableCaptures(chip).map(
              (capture) => Move(
                fromX: capture.fromX,
                fromY: capture.fromY,
                toX: capture.toX,
                toY: capture.toY,
                isCapture: true,
                capturedChipTerms: capture.capturedChip.terms,
              ),
            ),
          )
          .toList();
    }

    final regularMoves = <Move>[];
    for (final chip in chips.where((c) => c.owner == player)) {
      regularMoves.addAll(getValidMoves(chip).where((move) => !move.isCapture));
    }

    return regularMoves;
  }

  /// Get all valid moves for a player
  List<Move> getAllValidMovesForPlayer(int player) {
    return getLegalMovesForPlayer(player);
  }

  // ==================== WIN/LOSE DETECTION ====================

  /// Gets the current score for a player.
  double getScore(int playerNumber) {
    return playerNumber == 1 ? player1Score : player2Score;
  }

  /// Gets the current accumulated score for a player.
  double getFinalScore(int playerNumber) {
    return getScore(playerNumber) + _remainingChipsScoreFor(playerNumber);
  }

  double _remainingChipsScoreFor(int playerNumber) {
    final remainingChips = chips
        .where((chip) => chip.owner == playerNumber)
        .map(
          (chip) => {
            'terms': Map<int, int>.from(chip.terms),
            'isDama': chip.isDama,
          },
        )
        .toList();

    return ScoreCalculator.calculateRemainingChipsScore(remainingChips);
  }

  String _buildEndgameBonusDetails(int playerNumber) {
    final remainingChips = chips.where((chip) => chip.owner == playerNumber);
    final lines = <String>[];
    var totalBonus = 0.0;

    for (final chip in remainingChips) {
      final baseBonus = chip.terms.values.fold<double>(
        0,
        (sum, coefficient) => sum + coefficient.abs(),
      );
      final finalBonus = chip.isDama ? baseBonus * 2 : baseBonus;
      totalBonus += finalBonus;
      lines.add(
        '${_formatTerms(chip.terms)}${chip.isDama ? ' (Dama)' : ''}: '
        '${baseBonus.toStringAsFixed(2)}'
        '${chip.isDama ? ' x 2' : ''} = ${finalBonus.toStringAsFixed(2)}',
      );
    }

    if (lines.isEmpty) {
      lines.add('No remaining chips: 0.00');
    }

    lines.add('Total endgame bonus = ${totalBonus.toStringAsFixed(2)}');
    return lines.join('\n');
  }

  void _recordEndgameBonusesIfNeeded() {
    if (_endgameBonusesRecorded) {
      return;
    }

    for (final playerNumber in const [1, 2]) {
      _recordEndgameBonusEntry(
        playerNumber: playerNumber,
        bonus: _remainingChipsScoreFor(playerNumber),
        calculationDetails: _buildEndgameBonusDetails(playerNumber),
      );
    }

    _endgameBonusesRecorded = true;
  }

  /// Legacy method for int score (kept for compatibility)
  int getScoreInt(int playerNumber) {
    return (playerNumber == 1 ? player1Score : player2Score).round();
  }

  /// Evaluates the game state for win/draw conditions.
  /// The player with the greater accumulated score wins.
  void _evaluateGameState() {
    // Check game end conditions per PDF rules:
    // - 20-minute game period lapses (handled by the timed UI layer)
    // - Moves are repetitive (threefold repetition)
    // - A player has no more chips to move
    // - An opponent's chip is 'cornered'

    final opponent = currentPlayer == 1 ? 2 : 1;

    // Check win by elimination
    final opponentChips = chips.where((c) => c.owner == opponent).toList();
    if (opponentChips.isEmpty) {
      _declareWinnerByScore();
      return;
    }

    // Check win by blocking (opponent has no valid moves)
    final opponentMoves = getAllValidMovesForPlayer(opponent);
    if (opponentMoves.isEmpty) {
      _declareWinnerByScore();
      return;
    }

    // Check draw by repeated position
    if (_hasRepeatedPosition()) {
      _declareDrawByScore();
      return;
    }
  }

  /// Declare winner based on accumulated score (per PDF)
  void _declareWinnerByScore() {
    _recordEndgameBonusesIfNeeded();
    final p1Final = getFinalScore(1);
    final p2Final = getFinalScore(2);

    // Determine winner by final score
    if (p1Final > p2Final) {
      gamePhase = GamePhase.won;
      winner = PlayerModel(name: 'Player 1', color: PlayerColor.blue);
    } else if (p2Final > p1Final) {
      gamePhase = GamePhase.won;
      winner = PlayerModel(name: 'Player 2', color: PlayerColor.red);
    } else {
      gamePhase = GamePhase.draw;
      winner = null;
    }

    _logger.info(
      'Game over! Final scores - Player 1: $p1Final, Player 2: $p2Final. Winner: ${winner?.name ?? "Draw"}',
    );
  }

  /// Declare draw when scores are equal
  void _declareDrawByScore() {
    _recordEndgameBonusesIfNeeded();
    final p1Final = getFinalScore(1);
    final p2Final = getFinalScore(2);

    if (p1Final == p2Final) {
      gamePhase = GamePhase.draw;
      winner = null;
      _logger.info('Game over! Draw by equal scores: $p1Final');
    } else {
      // One player has higher score
      _declareWinnerByScore();
    }
  }

  /// Check if game is over
  bool get isGameOver => gamePhase != GamePhase.playing;

  /// Check if game is a draw
  bool get isDraw => gamePhase == GamePhase.draw;

  /// Get current winner
  PlayerModel? get currentWinner => winner;

  /// Public method to check game state (for external calls)
  void evaluateGameState() {
    _evaluateGameState();
  }

  /// End the game immediately and resolve the winner using final scores.
  void endGameByScore() {
    if (gamePhase != GamePhase.playing) {
      return;
    }

    _declareWinnerByScore();
  }

  /// Check if a player has any valid moves
  bool hasValidMoves(int player) {
    return getAllValidMovesForPlayer(player).isNotEmpty;
  }

  // ==================== HELPER METHODS ====================

  /// Check if a tile is occupied by another chip
  bool isOccupied(int x, int y) {
    return chips.any((chip) => chip.x == x && chip.y == y);
  }

  /// Check if the given chips are opponents
  bool isOpponent(ChipModel a, ChipModel b) {
    return a.owner != b.owner;
  }

  /// Get the chip at a specific position
  ChipModel? chipAt(int x, int y) {
    try {
      return chips.firstWhere((chip) => chip.x == x && chip.y == y);
    } catch (e) {
      return null;
    }
  }

  // ==================== DERIVATIVE INTEGRATION ====================

  /// Gets the operation symbol at a given board position.
  String? getOperationAt(int x, int y) {
    final operationsBoard = getOperationsBoard();
    if (x >= 0 && x < 8 && y >= 0 && y < 8) {
      return operationsBoard[y][x];
    }
    return null;
  }

  /// Checks if a position contains an operation tile (+, âˆ’, Ã—, Ã·)
  bool isOperationTile(int x, int y) {
    final operation = getOperationAt(x, y);
    return operation != null && operation.isNotEmpty;
  }

  /// Gets the operation type from the symbol
  OperationType? getOperationType(String symbol) {
    switch (symbol) {
      case '+':
        return OperationType.add;
      case 'âˆ’':
        return OperationType.subtract;
      case 'Ã—':
        return OperationType.multiply;
      case 'Ã·':
        return OperationType.divide;
      default:
        return null;
    }
  }

  /// Computes the derivative of a chip's polynomial.
  Map<int, int> computeDerivative(ChipModel chip) {
    return DerivativeRules.powerRule(chip.terms);
  }

  /// Validates if the moving chip's derivative matches the expected result
  bool validateDerivativeMove(ChipModel movingChip, int targetX, int targetY) {
    final operationSymbol = getOperationAt(targetX, targetY);
    if (operationSymbol == null || operationSymbol.isEmpty) {
      return true;
    }

    final opponentChip = chipAt(targetX, targetY);
    if (opponentChip == null) {
      return true;
    }

    final computedDerivative = computeDerivative(movingChip);
    final expectedResult = opponentChip.terms;

    return _mapsEqual(computedDerivative, expectedResult);
  }

  /// Compares two polynomial maps for equality.
  bool _mapsEqual(Map<int, int> map1, Map<int, int> map2) {
    if (map1.length != map2.length) return false;
    for (final entry in map1.entries) {
      if (map2[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Processes a move to an operation tile with derivative validation.
  MoveResult processOperationMove(int x, int y) {
    if (selectedChip == null) {
      lastErrorMessage = 'No chip selected';
      return MoveResult.failure();
    }

    final operationSymbol = getOperationAt(x, y);
    if (operationSymbol == null || operationSymbol.isEmpty) {
      return MoveResult.success();
    }

    final opponentChip = chipAt(x, y);

    final computedDerivative = computeDerivative(selectedChip!);

    bool isCorrect = true;
    if (opponentChip != null) {
      final expectedResult = opponentChip.terms;
      isCorrect = _mapsEqual(computedDerivative, expectedResult);

      if (!isCorrect) {
        lastErrorMessage = 'Incorrect derivative!';
        _logger.warning('Derivative validation failed: $lastErrorMessage');
        return MoveResult.failure();
      }
    }

    Map<int, int>? resultPolynomial;
    if (opponentChip != null) {
      resultPolynomial = _applyOperation(
        selectedChip!.terms,
        opponentChip.terms,
        operationSymbol,
      );
    }

    // Transform the chip with the result polynomial
    if (resultPolynomial != null) {
      selectedChip!.terms.clear();
      selectedChip!.terms.addAll(resultPolynomial);
    }

    lastMoveResult = MoveResult.success(
      isCapture: opponentChip != null,
      isDamaPromotion: false,
      captureCount: 0,
      resultPolynomial: resultPolynomial,
    );

    _logger.info('Operation move successful. Operation: $operationSymbol');
    return lastMoveResult!;
  }

  /// Applies a mathematical operation between two polynomials.
  Map<int, int> _applyOperation(
    Map<int, int> left,
    Map<int, int> right,
    String operation,
  ) {
    final result = <int, int>{};

    switch (operation) {
      case '+':
        for (final entry in left.entries) {
          result[entry.key] = entry.value;
        }
        for (final entry in right.entries) {
          result[entry.key] = (result[entry.key] ?? 0) + entry.value;
        }
        break;

      case 'âˆ’':
        for (final entry in left.entries) {
          result[entry.key] = entry.value;
        }
        for (final entry in right.entries) {
          result[entry.key] = (result[entry.key] ?? 0) - entry.value;
        }
        break;

      case 'Ã—':
        for (final entry1 in left.entries) {
          for (final entry2 in right.entries) {
            final newExp = entry1.key + entry2.key;
            final newCoeff = entry1.value * entry2.value;
            result[newExp] = (result[newExp] ?? 0) + newCoeff;
          }
        }
        break;

      case 'Ã·':
        // Division: perform polynomial division left Ã· right
        final quotientExp = _dividePolynomials(left, right);
        result[quotientExp] = 1;
        break;
    }

    result.removeWhere((key, value) => value == 0);
    return result;
  }

  /// Divides two polynomials (left Ã· right).
  ///
  /// Uses polynomial long division to compute the quotient.
  /// Returns the exponent of the result polynomial (since division
  /// produces a single term in this game context).
  ///
  /// [left] - The dividend (numerator)
  /// [right] - The divisor (denominator)
  /// Returns the exponent of the quotient term
  int _dividePolynomials(Map<int, int> left, Map<int, int> right) {
    if (right.isEmpty) return 0;

    // Find the highest exponent in left (dividend)
    int leftMaxExp = 0;
    for (final entry in left.entries) {
      if (entry.key > leftMaxExp && entry.value != 0) {
        leftMaxExp = entry.key;
      }
    }

    // Find the highest exponent in right (divisor)
    int rightMaxExp = 0;
    for (final entry in right.entries) {
      if (entry.key > rightMaxExp && entry.value != 0) {
        rightMaxExp = entry.key;
      }
    }

    // Cannot divide by zero polynomial
    if (rightMaxExp == 0 && (right[0] == null || right[0] == 0)) return 0;

    // Compute quotient exponent: leftMaxExp - rightMaxExp
    return leftMaxExp - rightMaxExp;
  }

  /// Resets the game to initial state.
  void reset() {
    chips = getInitialChips();
    selectedChip = null;
    currentPlayer = 1;
    player1Score = 0;
    player2Score = 0;
    lastMoveResult = null;
    lastErrorMessage = null;

    // Reset Phase 3 state
    mustContinueCapture = false;
    currentChainChip = null;
    captureChainDepth = 0;
    gamePhase = GamePhase.playing;
    winner = null;
    positionHistory.clear();
    _endgameBonusesRecorded = false;

    // Clear move history
    clearHistory();
  }

  /// Get chips for a player
  List<ChipModel> getChipsForPlayer(int player) {
    return chips.where((chip) => chip.owner == player).toList();
  }

  /// Get chip count for a player
  int getChipCount(int player) {
    return chips.where((chip) => chip.owner == player).length;
  }

  /// Get Dama count for a player
  int getDamaCount(int player) {
    return chips.where((chip) => chip.owner == player && chip.isDama).length;
  }

  /// Setup custom board with specific chip positions for testing capture rules
  /// [chipSetup] - List of chip configurations (x, y, isDama, owner, terms)
  void setupCustomBoard(List<Map<String, dynamic>> chipSetup) {
    chips.clear();
    int idCounter = 0;

    for (final setup in chipSetup) {
      final chip = ChipModel(
        id: idCounter++,
        x: setup['x'] as int,
        y: setup['y'] as int,
        owner: setup['owner'] as int,
        isDama: setup['isDama'] as bool? ?? false,
        terms: Map<int, int>.from(setup['terms'] as Map<int, int>? ?? {0: 1}),
      );
      chips.add(chip);
    }

    // Reset game state
    selectedChip = null;
    currentPlayer = 1;
    player1Score = 0;
    player2Score = 0;
    lastMoveResult = null;
    lastErrorMessage = null;
    mustContinueCapture = false;
    currentChainChip = null;
    captureChainDepth = 0;
    gamePhase = GamePhase.playing;
    winner = null;
    positionHistory.clear();
    _endgameBonusesRecorded = false;
    clearHistory();

    _recordPosition();
  }

  /// Creates a deep copy of the game state for engine search.
  GameLogic clone() {
    final clone = GameLogic();

    clone.chips = chips
        .map(
          (chip) => ChipModel(
            id: chip.id,
            x: chip.x,
            y: chip.y,
            owner: chip.owner,
            isDama: chip.isDama,
            terms: Map<int, int>.from(chip.terms),
          ),
        )
        .toList();

    final chipById = {for (final chip in clone.chips) chip.id: chip};

    clone.selectedChip = selectedChip == null
        ? null
        : chipById[selectedChip!.id];
    clone.currentPlayer = currentPlayer;
    clone.player1Score = player1Score;
    clone.player2Score = player2Score;
    clone.lastMoveResult = lastMoveResult == null
        ? null
        : MoveResult(
            isValid: lastMoveResult!.isValid,
            isCapture: lastMoveResult!.isCapture,
            isDamaPromotion: lastMoveResult!.isDamaPromotion,
            captureCount: lastMoveResult!.captureCount,
            resultPolynomial: lastMoveResult!.resultPolynomial == null
                ? null
                : Map<int, int>.from(lastMoveResult!.resultPolynomial!),
            score: lastMoveResult!.score,
          );
    clone.lastErrorMessage = lastErrorMessage;
    clone.mustContinueCapture = mustContinueCapture;
    clone.currentChainChip = currentChainChip == null
        ? null
        : chipById[currentChainChip!.id];
    clone.captureChainDepth = captureChainDepth;
    clone.gamePhase = gamePhase;
    clone.winner = winner?.copyWith();
    clone.positionHistory
      ..clear()
      ..addAll(positionHistory);
    clone.moveHistory.clear();
    clone.moveHistory.addAll(moveHistory.map((entry) => entry.copyWith()));
    clone._endgameBonusesRecorded = _endgameBonusesRecorded;
    clone._moveCounter = _moveCounter;

    return clone;
  }

  /// Execute a move from the AI opponent.
  /// This method handles selecting the chip and moving it to the destination.
  void executeMove(Move move) {
    // If game is over, ignore
    if (gamePhase != GamePhase.playing) return;

    // First, clear any existing selection to ensure clean state
    selectedChip = null;

    // Find and select the chip at the from position
    final chip = chipAt(move.fromX, move.fromY);
    if (chip == null) {
      _logger.warning(
        'Cannot execute move: no chip at (${move.fromX}, ${move.fromY})',
      );
      return;
    }

    if (chip.owner != currentPlayer) {
      _logger.warning(
        'Cannot execute move: chip at (${move.fromX}, ${move.fromY}) belongs to player ${chip.owner}, but current player is $currentPlayer',
      );
      return;
    }

    // Verify this exact move is still legal in the current position.
    final validMoves = getLegalMovesForPlayer(currentPlayer);
    final isValidMove = validMoves.any(
      (m) =>
          m.fromX == move.fromX &&
          m.fromY == move.fromY &&
          m.toX == move.toX &&
          m.toY == move.toY,
    );

    if (!isValidMove) {
      _logger.warning(
        'Move from (${move.fromX}, ${move.fromY}) to (${move.toX}, ${move.toY}) failed legal move validation',
      );
      return;
    }

    // Select the chip
    selectedChip = chip;
    _logger.info(
      'AI selected chip at (${move.fromX}, ${move.fromY}), attempting to move to (${move.toX}, ${move.toY})',
    );

    // Execute the move via tile tap
    onTileTap(move.toX, move.toY);

    _logger.info(
      'AI move completed. New position: (${chip.x}, ${chip.y}), currentPlayer is now $currentPlayer',
    );
  }
}
