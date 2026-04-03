/// Step-by-step breakdown of the derivative calculation for educational purposes.
///
/// This class provides detailed explanations of how each capture move's
/// derivative computation works, making it easier for players to understand
/// the mathematical process behind scoring.
class CalculationBreakdown {
  /// Original moving chip terms (formatted polynomial)
  final String movingChipTerms;

  /// Target chip terms (for captures), formatted as string
  final String? targetChipTerms;

  /// Operation symbol applied (+, âˆ’, Ã—, Ã·)
  final String operation;

  /// Result after applying the operation (combined polynomial)
  final String combinedTerms;

  /// Derivative formula after differentiation
  final String derivativeFormula;

  /// Evaluation point x = |x - y| (values: 1, 3, 5, or 7)
  final int evaluationPoint;

  /// Raw evaluated score for the capture before any Dama multiplier.
  final double resultBeforeMultiplier;

  /// Dama multiplier applied to the raw result: 1x, 2x, or 4x.
  final int dameMultiplier;

  /// Extra chain-capture bonus, if the ruleset uses one.
  final int chainBonus;

  /// Final calculated score
  final double finalScore;

  /// Whether the derivative resulted in a constant (no x variable)
  final bool isConstantDerivative;

  /// Explanation of each step for display
  final List<CalculationStep> steps;

  const CalculationBreakdown({
    required this.movingChipTerms,
    this.targetChipTerms,
    required this.operation,
    required this.combinedTerms,
    required this.derivativeFormula,
    required this.evaluationPoint,
    required this.resultBeforeMultiplier,
    this.dameMultiplier = 1,
    this.chainBonus = 0,
    required this.finalScore,
    this.isConstantDerivative = false,
    required this.steps,
  });

  factory CalculationBreakdown.fromJson(Map<String, dynamic> json) {
    return CalculationBreakdown(
      movingChipTerms: json['movingChipTerms'] as String? ?? '',
      targetChipTerms: json['targetChipTerms'] as String?,
      operation: json['operation'] as String? ?? '',
      combinedTerms: json['combinedTerms'] as String? ?? '',
      derivativeFormula: json['derivativeFormula'] as String? ?? '',
      evaluationPoint: json['evaluationPoint'] as int? ?? 0,
      resultBeforeMultiplier:
          (json['resultBeforeMultiplier'] as num?)?.toDouble() ?? 0,
      dameMultiplier: json['dameMultiplier'] as int? ?? 1,
      chainBonus: json['chainBonus'] as int? ?? 0,
      finalScore: (json['finalScore'] as num?)?.toDouble() ?? 0,
      isConstantDerivative: json['isConstantDerivative'] as bool? ?? false,
      steps: ((json['steps'] as List?) ?? const [])
          .map(
            (step) => CalculationStep.fromJson(
              Map<String, dynamic>.from(step as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movingChipTerms': movingChipTerms,
      'targetChipTerms': targetChipTerms,
      'operation': operation,
      'combinedTerms': combinedTerms,
      'derivativeFormula': derivativeFormula,
      'evaluationPoint': evaluationPoint,
      'resultBeforeMultiplier': resultBeforeMultiplier,
      'dameMultiplier': dameMultiplier,
      'chainBonus': chainBonus,
      'finalScore': finalScore,
      'isConstantDerivative': isConstantDerivative,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }

  /// Returns a formatted string showing the complete calculation
  String get fullCalculation {
    final buffer = StringBuffer();
    buffer.writeln('Step 1: Combine chips using $operation');
    buffer.writeln(
      '  $movingChipTerms $operation ${targetChipTerms ?? ""} = $combinedTerms',
    );
    buffer.writeln('Step 2: Take derivative');
    buffer.writeln('  d/dx($combinedTerms) = $derivativeFormula');
    buffer.writeln('Step 3: Evaluate at x = $evaluationPoint');
    if (isConstantDerivative) {
      buffer.writeln('  (constant - no x variable)');
    }
    buffer.writeln('  = ${resultBeforeMultiplier.toStringAsFixed(2)}');
    if (dameMultiplier > 1) {
      buffer.writeln('Step 4: Apply ${dameMultiplier}x Dama multiplier');
      buffer.writeln(
        '  ${resultBeforeMultiplier.toStringAsFixed(2)} Ã— $dameMultiplier = ${finalScore.toStringAsFixed(2)}',
      );
    }
    if (chainBonus > 0) {
      buffer.writeln('Step 5: Add chain bonus (+$chainBonus)');
    }
    return buffer.toString();
  }
}

/// Represents a single step in the calculation breakdown.
class CalculationStep {
  /// Step number (1-based)
  final int stepNumber;

  /// Title of the step
  final String title;

  /// Description of what happens in this step
  final String description;

  /// The mathematical expression for this step
  final String expression;

  /// Result of this step
  final String? result;

  /// Icon identifier for the step
  final String iconName;

  const CalculationStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.expression,
    this.result,
    required this.iconName,
  });

  factory CalculationStep.fromJson(Map<String, dynamic> json) {
    return CalculationStep(
      stepNumber: json['stepNumber'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      expression: json['expression'] as String? ?? '',
      result: json['result'] as String?,
      iconName: json['iconName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'description': description,
      'expression': expression,
      'result': result,
      'iconName': iconName,
    };
  }
}

/// Represents a single move in the game's move history.
///
/// This model stores all information about a move including:
/// - The player who made the move
/// - The movement coordinates (from â†’ to)
/// - Whether it was a capture
/// - The operation tile used (if any)
/// - The derivative calculation details
/// - Points earned from the move
/// - Step-by-step calculation breakdown for educational purposes
///
/// The [CalculationBreakdown] provides detailed step-by-step explanations
/// of how the derivative computation works for capture moves.
class MoveHistoryEntry {
  /// Unique move number in the game (starts from 1)
  final int moveNumber;

  /// Player who made this move (1 = blue/Player 1, 2 = red/Player 2)
  final int player;

  /// Starting X coordinate
  final int fromX;

  /// Starting Y coordinate
  final int fromY;

  /// Target X coordinate
  final int toX;

  /// Target Y coordinate
  final int toY;

  /// Whether this was a capture move
  final bool isCapture;

  /// Whether this entry is an endgame bonus summary instead of a board move.
  final bool isEndgameBonus;

  /// Terms of the captured chip (if capture), formatted as string
  final String? capturedChipTerms;

  /// The operation symbol on the target tile (+, âˆ’, Ã—, Ã·)
  final String operation;

  /// Points earned from this move
  final double pointsEarned;

  /// Detailed calculation breakdown
  final String calculationDetails;

  /// Chip terms before the move (for display)
  final String chipTerms;

  /// Whether the chip was promoted to Dama after this move
  final bool isDamaPromotion;

  /// Number of chips captured in this move (chain captures)
  final int captureCount;

  /// Detailed step-by-step breakdown of the calculation
  /// Provides educational explanation of derivative computation
  final CalculationBreakdown? calculationBreakdown;

  const MoveHistoryEntry({
    required this.moveNumber,
    required this.player,
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    this.isCapture = false,
    this.isEndgameBonus = false,
    this.capturedChipTerms,
    this.operation = '',
    this.pointsEarned = 0,
    this.calculationDetails = '',
    this.chipTerms = '',
    this.isDamaPromotion = false,
    this.captureCount = 0,
    this.calculationBreakdown,
  });

  factory MoveHistoryEntry.fromJson(Map<String, dynamic> json) {
    return MoveHistoryEntry(
      moveNumber: json['moveNumber'] as int? ?? 0,
      player: json['player'] as int? ?? 0,
      fromX: json['fromX'] as int? ?? 0,
      fromY: json['fromY'] as int? ?? 0,
      toX: json['toX'] as int? ?? 0,
      toY: json['toY'] as int? ?? 0,
      isCapture: json['isCapture'] as bool? ?? false,
      isEndgameBonus: json['isEndgameBonus'] as bool? ?? false,
      capturedChipTerms: json['capturedChipTerms'] as String?,
      operation: json['operation'] as String? ?? '',
      pointsEarned: (json['pointsEarned'] as num?)?.toDouble() ?? 0,
      calculationDetails: json['calculationDetails'] as String? ?? '',
      chipTerms: json['chipTerms'] as String? ?? '',
      isDamaPromotion: json['isDamaPromotion'] as bool? ?? false,
      captureCount: json['captureCount'] as int? ?? 0,
      calculationBreakdown: json['calculationBreakdown'] == null
          ? null
          : CalculationBreakdown.fromJson(
              Map<String, dynamic>.from(json['calculationBreakdown'] as Map),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moveNumber': moveNumber,
      'player': player,
      'fromX': fromX,
      'fromY': fromY,
      'toX': toX,
      'toY': toY,
      'isCapture': isCapture,
      'isEndgameBonus': isEndgameBonus,
      'capturedChipTerms': capturedChipTerms,
      'operation': operation,
      'pointsEarned': pointsEarned,
      'calculationDetails': calculationDetails,
      'chipTerms': chipTerms,
      'isDamaPromotion': isDamaPromotion,
      'captureCount': captureCount,
      'calculationBreakdown': calculationBreakdown?.toJson(),
    };
  }

  /// Returns the player color name
  String get playerName =>
      player == 1 ? 'Player 1' : (player == 2 ? 'Player 2' : 'Unknown');

  /// Returns formatted move string (e.g., "2,5 -> 3,4")
  String get moveString =>
      isEndgameBonus ? 'Endgame Bonus' : '($fromX,$fromY) -> ($toX,$toY)';

  /// Returns formatted move notation (e.g., "e4e5")
  String get algebraicNotation {
    if (isEndgameBonus) {
      return '';
    }
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final fromFile = files[fromX];
    final toFile = files[toX];
    return '$fromFile${7 - fromY}$toFile${7 - toY}';
  }

  /// Returns a short description of the move type
  String get moveTypeDescription {
    if (isEndgameBonus) {
      return 'Endgame Bonus';
    }
    if (isCapture) {
      if (captureCount > 1) {
        return 'Chain Capture ($captureCount pieces)';
      }
      return 'Capture';
    }
    if (isDamaPromotion) {
      return 'Move (Dama Promotion)';
    }
    return 'Move';
  }

  /// Returns formatted points string
  String get pointsString {
    if (pointsEarned == 0) return '';
    final sign = pointsEarned > 0 ? '+' : '';
    return '$sign${pointsEarned.toStringAsFixed(2)} pts';
  }

  /// Creates a copy with optional parameter overrides
  MoveHistoryEntry copyWith({
    int? moveNumber,
    int? player,
    int? fromX,
    int? fromY,
    int? toX,
    int? toY,
    bool? isCapture,
    bool? isEndgameBonus,
    String? capturedChipTerms,
    String? operation,
    double? pointsEarned,
    String? calculationDetails,
    String? chipTerms,
    bool? isDamaPromotion,
    int? captureCount,
    CalculationBreakdown? calculationBreakdown,
  }) {
    return MoveHistoryEntry(
      moveNumber: moveNumber ?? this.moveNumber,
      player: player ?? this.player,
      fromX: fromX ?? this.fromX,
      fromY: fromY ?? this.fromY,
      toX: toX ?? this.toX,
      toY: toY ?? this.toY,
      isCapture: isCapture ?? this.isCapture,
      isEndgameBonus: isEndgameBonus ?? this.isEndgameBonus,
      capturedChipTerms: capturedChipTerms ?? this.capturedChipTerms,
      operation: operation ?? this.operation,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      calculationDetails: calculationDetails ?? this.calculationDetails,
      chipTerms: chipTerms ?? this.chipTerms,
      isDamaPromotion: isDamaPromotion ?? this.isDamaPromotion,
      captureCount: captureCount ?? this.captureCount,
      calculationBreakdown: calculationBreakdown ?? this.calculationBreakdown,
    );
  }

  @override
  String toString() {
    return 'MoveHistoryEntry(#$moveNumber: $playerName $moveString, '
        'type=$moveTypeDescription, pts=$pointsString)';
  }
}
