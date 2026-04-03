import 'package:derivative_damath/models/move_history_model.dart';

/// Result of a move in the Derivative Damath game.
class MoveResult {
  final bool isValid;
  final bool isCapture;
  final bool isDamaPromotion;
  final int captureCount;
  final Map<int, int>? resultPolynomial;
  final double score;

  const MoveResult({
    required this.isValid,
    this.isCapture = false,
    this.isDamaPromotion = false,
    this.captureCount = 0,
    this.resultPolynomial,
    this.score = 0,
  });

  factory MoveResult.success({
    bool isCapture = false,
    bool isDamaPromotion = false,
    int captureCount = 0,
    Map<int, int>? resultPolynomial,
    double score = 0,
  }) {
    return MoveResult(
      isValid: true,
      isCapture: isCapture,
      isDamaPromotion: isDamaPromotion,
      captureCount: captureCount,
      resultPolynomial: resultPolynomial,
      score: score,
    );
  }

  factory MoveResult.failure() {
    return const MoveResult(isValid: false);
  }
}

/// Utility class for calculating scores in Derivative Damath.
class ScoreCalculator {
  static double calculateScorePDF({
    required Map<int, int> movingChipTerms,
    Map<int, int>? targetChipTerms,
    required String operationSymbol,
    required int targetX,
    required int targetY,
    bool isCapture = false,
    bool isDamaPromotion = false,
    bool isMovingChipDama = false,
    bool isTargetChipDama = false,
  }) {
    if (!isCapture || targetChipTerms == null) {
      return 0;
    }

    final combined = _applyOperation(
      movingChipTerms,
      targetChipTerms,
      operationSymbol,
    );
    if (combined.isEmpty) return 0;

    final derivative = _differentiate(combined);
    final hasXVariable = derivative.entries.any(
      (entry) => entry.key != 0 && !entry.value.isZero,
    );
    final xValue = (targetX - targetY).abs();

    if (!hasXVariable) {
      final baseScore = derivative[0]?.toDouble() ?? 0;
      return baseScore *
          calculateDamaMultiplier(
            isMovingChipDama: isMovingChipDama,
            isTargetChipDama: isTargetChipDama,
          );
    }

    final baseScore = _evaluatePolynomial(derivative, xValue);
    return baseScore *
        calculateDamaMultiplier(
          isMovingChipDama: isMovingChipDama,
          isTargetChipDama: isTargetChipDama,
        );
  }

  static CalculationBreakdown? generateCalculationBreakdown({
    required Map<int, int> movingChipTerms,
    Map<int, int>? targetChipTerms,
    required String operationSymbol,
    required int targetX,
    required int targetY,
    bool isMovingChipDama = false,
    bool isTargetChipDama = false,
  }) {
    if (targetChipTerms == null || targetChipTerms.isEmpty) {
      return null;
    }

    final movingFormatted = _formatTerms(
      _toFractionPolynomial(movingChipTerms),
    );
    final targetFormatted = _formatTerms(
      _toFractionPolynomial(targetChipTerms),
    );

    final combined = _applyOperation(
      movingChipTerms,
      targetChipTerms,
      operationSymbol,
    );
    if (combined.isEmpty) return null;

    final combinedFormatted = _formatTerms(combined);
    final derivative = _differentiate(combined);
    final derivativeFormatted = _formatDerivative(derivative);
    final hasXVariable = derivative.entries.any(
      (entry) => entry.key != 0 && !entry.value.isZero,
    );

    final xValue = (targetX - targetY).abs();
    final resultBeforeMultiplier = hasXVariable
        ? _evaluatePolynomial(derivative, xValue)
        : (derivative[0]?.toDouble() ?? 0);
    final damaMultiplier = calculateDamaMultiplier(
      isMovingChipDama: isMovingChipDama,
      isTargetChipDama: isTargetChipDama,
    );
    final finalScore = resultBeforeMultiplier * damaMultiplier;

    final operationName = _getOperationName(operationSymbol);
    final steps = <CalculationStep>[
      CalculationStep(
        stepNumber: 1,
        title: 'Combine Chips',
        description:
            'Apply $operationName operation to combine the polynomials',
        expression:
            '$movingFormatted ${_getOperationSymbol(operationSymbol)} $targetFormatted = $combinedFormatted',
        result: combinedFormatted,
        iconName: 'combine',
      ),
      CalculationStep(
        stepNumber: 2,
        title: 'Take Derivative',
        description: 'Differentiate the simplified result',
        expression: 'd/dx($combinedFormatted) = $derivativeFormatted',
        result: derivativeFormatted,
        iconName: 'derivative',
      ),
      CalculationStep(
        stepNumber: 3,
        title: hasXVariable ? 'Evaluate' : 'Constant Result',
        description: hasXVariable
            ? 'Substitute x = |$targetX - $targetY| = $xValue'
            : 'Derivative is constant, so use it directly',
        expression: derivativeFormatted,
        result: resultBeforeMultiplier.toStringAsFixed(2),
        iconName: 'calculate',
      ),
    ];

    if (damaMultiplier > 1) {
      steps.add(
        CalculationStep(
          stepNumber: 4,
          title: 'Apply Dama Multiplier',
          description: damaMultiplier == 4
              ? 'Both the taker and taken chips are Dama, so the score is quadrupled'
              : 'A Dama chip is involved, so the score is doubled',
          expression:
              '${resultBeforeMultiplier.toStringAsFixed(2)} x $damaMultiplier',
          result: finalScore.toStringAsFixed(2),
          iconName: 'multiply',
        ),
      );
    }

    return CalculationBreakdown(
      movingChipTerms: movingFormatted,
      targetChipTerms: targetFormatted,
      operation: _getOperationSymbol(operationSymbol),
      combinedTerms: combinedFormatted,
      derivativeFormula: derivativeFormatted,
      evaluationPoint: xValue,
      resultBeforeMultiplier: resultBeforeMultiplier,
      dameMultiplier: damaMultiplier,
      chainBonus: 0,
      finalScore: finalScore,
      isConstantDerivative: !hasXVariable,
      steps: steps,
    );
  }

  static int calculateDamaMultiplier({
    required bool isMovingChipDama,
    required bool isTargetChipDama,
  }) {
    if (isMovingChipDama && isTargetChipDama) {
      return 4;
    }
    if (isMovingChipDama || isTargetChipDama) {
      return 2;
    }
    return 1;
  }

  static String _formatTerms(Map<int, _Fraction> terms) {
    if (terms.isEmpty) return '0';

    final sortedKeys = terms.keys.toList()..sort((a, b) => b.compareTo(a));
    final parts = <String>[];

    for (final exp in sortedKeys) {
      final coeff = terms[exp]!;
      if (coeff.isZero) continue;

      final absoluteCoeff = coeff.abs();
      late final String termStr;
      if (exp == 0) {
        termStr = absoluteCoeff.toDisplayString();
      } else if (exp == 1) {
        termStr = absoluteCoeff.isOne
            ? 'x'
            : '${absoluteCoeff.toDisplayString()}x';
      } else {
        termStr = absoluteCoeff.isOne
            ? 'x${_toSuperscript(exp)}'
            : '${absoluteCoeff.toDisplayString()}x${_toSuperscript(exp)}';
      }

      if (parts.isEmpty) {
        parts.add(coeff.isNegative ? '-$termStr' : termStr);
      } else {
        parts.add(coeff.isNegative ? '- $termStr' : '+ $termStr');
      }
    }

    return parts.isEmpty ? '0' : parts.join(' ');
  }

  static String _formatDerivative(Map<int, _Fraction> derivative) {
    if (derivative.isEmpty) return '0';
    return _formatTerms(derivative);
  }

  static String _toSuperscript(int number) {
    return '^$number';
  }

  static String _getOperationName(String symbol) {
    switch (symbol) {
      case '+':
        return 'Addition';
      case '-':
      case '\u2212':
        return 'Subtraction';
      case 'x':
      case '*':
      case '\u00d7':
        return 'Multiplication';
      case '/':
      case '\u00f7':
        return 'Division';
      default:
        return 'Unknown';
    }
  }

  static String _getOperationSymbol(String symbol) {
    switch (symbol) {
      case '-':
      case '\u2212':
        return '\u2212';
      case 'x':
      case '*':
      case '\u00d7':
        return '\u00d7';
      case '/':
      case '\u00f7':
        return '\u00f7';
      default:
        return symbol;
    }
  }

  static Map<int, _Fraction> _applyOperation(
    Map<int, int> left,
    Map<int, int> right,
    String operation,
  ) {
    final leftPolynomial = _toFractionPolynomial(left);
    final rightPolynomial = _toFractionPolynomial(right);
    final result = <int, _Fraction>{};

    switch (operation) {
      case '+':
        for (final entry in leftPolynomial.entries) {
          result[entry.key] = entry.value;
        }
        for (final entry in rightPolynomial.entries) {
          result[entry.key] =
              (result[entry.key] ?? _Fraction.zero()) + entry.value;
        }
        break;

      case '-':
      case '\u2212':
        for (final entry in leftPolynomial.entries) {
          result[entry.key] = entry.value;
        }
        for (final entry in rightPolynomial.entries) {
          result[entry.key] =
              (result[entry.key] ?? _Fraction.zero()) - entry.value;
        }
        break;

      case 'x':
      case '*':
      case '\u00d7':
        for (final leftEntry in leftPolynomial.entries) {
          for (final rightEntry in rightPolynomial.entries) {
            final exp = leftEntry.key + rightEntry.key;
            final coeff = leftEntry.value * rightEntry.value;
            result[exp] = (result[exp] ?? _Fraction.zero()) + coeff;
          }
        }
        break;

      case '/':
      case '\u00f7':
        result.addAll(_divideMonomials(leftPolynomial, rightPolynomial));
        break;
    }

    result.removeWhere((key, value) => value.isZero);
    return result;
  }

  static Map<int, _Fraction> _divideMonomials(
    Map<int, _Fraction> left,
    Map<int, _Fraction> right,
  ) {
    final leftTerms =
        left.entries.where((entry) => !entry.value.isZero).toList()
          ..sort((a, b) => b.key.compareTo(a.key));
    final rightTerms =
        right.entries.where((entry) => !entry.value.isZero).toList()
          ..sort((a, b) => b.key.compareTo(a.key));

    if (leftTerms.length != 1 || rightTerms.length != 1) {
      return {};
    }

    final numerator = leftTerms.first;
    final denominator = rightTerms.first;
    if (denominator.value.isZero) {
      return {};
    }

    return {
      numerator.key - denominator.key: numerator.value / denominator.value,
    };
  }

  static Map<int, _Fraction> _toFractionPolynomial(Map<int, int> polynomial) {
    final result = <int, _Fraction>{};
    for (final entry in polynomial.entries) {
      if (entry.value != 0) {
        result[entry.key] = _Fraction(entry.value, 1);
      }
    }
    return result;
  }

  static Map<int, _Fraction> _differentiate(Map<int, _Fraction> polynomial) {
    final derivative = <int, _Fraction>{};

    for (final entry in polynomial.entries) {
      if (entry.key == 0 || entry.value.isZero) continue;
      derivative[entry.key - 1] = entry.value * _Fraction(entry.key, 1);
    }

    derivative.removeWhere((key, value) => value.isZero);
    return derivative;
  }

  static double _evaluatePolynomial(Map<int, _Fraction> polynomial, int x) {
    var result = _Fraction.zero();
    for (final entry in polynomial.entries) {
      result += entry.value * _powerAsFraction(x, entry.key);
    }
    return result.toDouble();
  }

  static _Fraction _powerAsFraction(int base, int exponent) {
    if (exponent == 0) {
      return _Fraction(1, 1);
    }

    final absolutePower = _pow(base, exponent.abs());
    if (exponent > 0) {
      return _Fraction(absolutePower, 1);
    }

    if (absolutePower == 0) {
      return _Fraction.zero();
    }

    return _Fraction(1, absolutePower);
  }

  static int _pow(int base, int exponent) {
    if (exponent == 0) return 1;

    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  static double calculateRemainingChipsScore(List<Map<String, dynamic>> chips) {
    var total = 0.0;

    for (final chip in chips) {
      final rawTerms = chip['terms'];
      if (rawTerms is! Map) continue;

      final terms = rawTerms.map(
        (key, value) => MapEntry(key as int, value as int),
      );
      final isDama = chip['isDama'] as bool? ?? false;

      final chipScore = terms.values.fold<double>(
        0,
        (sum, coefficient) => sum + coefficient.abs(),
      );

      total += isDama ? chipScore * 2 : chipScore;
    }

    return total;
  }

  static const int baseScore = 1;
  static const int captureBonus = 2;
  static const int promotionBonus = 1000;
  static const int chainCaptureBonus = 0;

  static int calculateScore({
    required MoveResult moveResult,
    int capturesCount = 0,
    required bool isCorrectDerivative,
    bool isDamaPromotion = false,
  }) {
    if (!isCorrectDerivative) return 0;

    var score = baseScore;
    if (moveResult.isCapture) {
      score += captureBonus;
      if (capturesCount > 1) {
        score += (capturesCount - 1) * chainCaptureBonus;
      }
    }

    if (isDamaPromotion) {
      score += promotionBonus;
    }

    return score;
  }

  static int calculate({
    required bool isCorrectDerivative,
    bool isCapture = false,
    int captureCount = 0,
    bool isDamaPromotion = false,
  }) {
    if (!isCorrectDerivative) return 0;

    var score = baseScore;
    if (isCapture) {
      score += captureBonus;
      if (captureCount > 1) {
        score += (captureCount - 1) * chainCaptureBonus;
      }
    }

    if (isDamaPromotion) {
      score += promotionBonus;
    }

    return score;
  }

  static ScoreBreakdown getScoreBreakdown({
    required bool isCorrectDerivative,
    bool isCapture = false,
    int captureCount = 0,
    bool isDamaPromotion = false,
  }) {
    if (!isCorrectDerivative) {
      return const ScoreBreakdown(
        totalScore: 0,
        basePoints: 0,
        capturePoints: 0,
        chainBonusPoints: 0,
        promotionPoints: 0,
        isCorrectDerivative: false,
      );
    }

    final basePoints = baseScore;
    final capturePoints = isCapture ? captureBonus : 0;
    final chainBonusPoints = captureCount > 1
        ? (captureCount - 1) * chainCaptureBonus
        : 0;
    final promotionPoints = isDamaPromotion ? promotionBonus : 0;

    return ScoreBreakdown(
      totalScore:
          basePoints + capturePoints + chainBonusPoints + promotionPoints,
      basePoints: basePoints,
      capturePoints: capturePoints,
      chainBonusPoints: chainBonusPoints,
      promotionPoints: promotionPoints,
      isCorrectDerivative: true,
    );
  }
}

class ScoreBreakdown {
  final int totalScore;
  final int basePoints;
  final int capturePoints;
  final int chainBonusPoints;
  final int promotionPoints;
  final bool isCorrectDerivative;

  const ScoreBreakdown({
    required this.totalScore,
    required this.basePoints,
    required this.capturePoints,
    required this.chainBonusPoints,
    required this.promotionPoints,
    required this.isCorrectDerivative,
  });

  String get description {
    if (!isCorrectDerivative) {
      return 'Incorrect derivative - 0 points';
    }

    final parts = <String>[
      'Base: +$basePoints',
      if (capturePoints > 0) 'Capture: +$capturePoints',
      if (chainBonusPoints > 0) 'Chain: +$chainBonusPoints',
      if (promotionPoints > 0) 'Dama: +$promotionPoints',
      'Total: $totalScore',
    ];

    return parts.join(', ');
  }
}

class _Fraction {
  final int numerator;
  final int denominator;

  const _Fraction._(this.numerator, this.denominator);

  factory _Fraction(int numerator, int denominator) {
    if (denominator == 0) {
      throw ArgumentError('Denominator cannot be zero');
    }

    if (numerator == 0) {
      return const _Fraction._(0, 1);
    }

    var normalizedNumerator = numerator;
    var normalizedDenominator = denominator;
    if (normalizedDenominator < 0) {
      normalizedNumerator = -normalizedNumerator;
      normalizedDenominator = -normalizedDenominator;
    }

    final gcd = _gcd(normalizedNumerator.abs(), normalizedDenominator.abs());

    return _Fraction._(
      normalizedNumerator ~/ gcd,
      normalizedDenominator ~/ gcd,
    );
  }

  factory _Fraction.zero() => const _Fraction._(0, 1);

  bool get isZero => numerator == 0;
  bool get isNegative => numerator < 0;
  bool get isOne => numerator == denominator;

  _Fraction abs() => _Fraction(numerator.abs(), denominator);

  double toDouble() => numerator / denominator;

  String toDisplayString() {
    if (denominator == 1) return numerator.toString();
    return '($numerator/$denominator)';
  }

  _Fraction operator +(_Fraction other) => _Fraction(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  _Fraction operator -(_Fraction other) => _Fraction(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );

  _Fraction operator *(_Fraction other) =>
      _Fraction(numerator * other.numerator, denominator * other.denominator);

  _Fraction operator /(_Fraction other) =>
      _Fraction(numerator * other.denominator, denominator * other.numerator);

  static int _gcd(int a, int b) {
    while (b != 0) {
      final temp = a % b;
      a = b;
      b = temp;
    }
    return a == 0 ? 1 : a;
  }
}
