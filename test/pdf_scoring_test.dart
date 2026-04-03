import 'package:derivative_damath/utils/score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PDF Scoring - Derivative Calculation Tests', () {
    test('Score calculation: multiply operation at x=1', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {4: -1},
        targetChipTerms: {4: -1},
        operationSymbol: '*',
        targetX: 4,
        targetY: 5,
        isCapture: true,
      );

      expect(score, equals(8.0));
    });

    test('Score calculation: multiply operation at x=3', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {1: 6},
        targetChipTerms: {1: 6},
        operationSymbol: '*',
        targetX: 0,
        targetY: 3,
        isCapture: true,
      );

      expect(score, equals(216.0));
    });

    test('Score calculation: addition operation', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {3: -3},
        targetChipTerms: {3: 66},
        operationSymbol: '+',
        targetX: 1,
        targetY: 4,
        isCapture: true,
      );

      expect(score, equals(1701.0));
    });

    test('Score calculation: subtraction operation', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {4: -21},
        targetChipTerms: {4: -1},
        operationSymbol: '-',
        targetX: 4,
        targetY: 3,
        isCapture: true,
      );

      expect(score, equals(-80.0));
    });

    test('Division keeps the coefficient ratio for monomials', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {2: 10},
        targetChipTerms: {1: 6},
        operationSymbol: '/',
        targetX: 2,
        targetY: 3,
        isCapture: true,
      );

      expect(score, closeTo(5 / 3, 1e-9));
    });

    test('x^4 divided by 6x gives one-half at x=1', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {4: 1},
        targetChipTerms: {1: 6},
        operationSymbol: '/',
        targetX: 4,
        targetY: 5,
        isCapture: true,
      );

      expect(score, closeTo(0.5, 1e-9));
    });

    test('Negative monomial division stays correct', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {5: -12},
        targetChipTerms: {2: 3},
        operationSymbol: '/',
        targetX: 2,
        targetY: 3,
        isCapture: true,
      );

      expect(score, equals(-12.0));
    });

    test('Negative exponents are still evaluated using coordinates', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {2: 10},
        targetChipTerms: {4: 1},
        operationSymbol: '/',
        targetX: 4,
        targetY: 2,
        isCapture: true,
      );

      // 10x^2 / x^4 = 10x^-2
      // derivative = -20x^-3
      // x = |4 - 2| = 2
      // -20 / 2^3 = -2.5
      expect(score, closeTo(-2.5, 1e-9));
    });

    test('Non-capture moves return 0 score', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {1: 6},
        targetChipTerms: null,
        operationSymbol: '+',
        targetX: 2,
        targetY: 3,
        isCapture: false,
      );

      expect(score, equals(0.0));
    });
  });

  group('PDF Scoring - End of Game Remaining Chips', () {
    test('Remaining chips add absolute coefficients and double Dama chips', () {
      final chips = [
        {
          'terms': {4: 78},
          'isDama': true,
        },
        {
          'terms': {3: 66},
          'isDama': false,
        },
        {
          'terms': {2: -45},
          'isDama': true,
        },
      ];

      final score = ScoreCalculator.calculateRemainingChipsScore(chips);
      expect(score, equals(312.0));
    });

    test('Empty chips list still returns 0', () {
      final chips = <Map<String, dynamic>>[];
      final score = ScoreCalculator.calculateRemainingChipsScore(chips);
      expect(score, equals(0.0));
    });
  });

  group('PDF Scoring - Dama Multipliers', () {
    test('Capture is doubled when the taker chip is Dama', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {2: 10},
        targetChipTerms: {1: 6},
        operationSymbol: '/',
        targetX: 2,
        targetY: 3,
        isCapture: true,
        isMovingChipDama: true,
      );

      expect(score, closeTo((5 / 3) * 2, 1e-9));
    });

    test('Capture is doubled when the taken chip is Dama', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {2: 10},
        targetChipTerms: {1: 6},
        operationSymbol: '/',
        targetX: 2,
        targetY: 3,
        isCapture: true,
        isTargetChipDama: true,
      );

      expect(score, closeTo((5 / 3) * 2, 1e-9));
    });

    test('Capture is quadrupled when both chips are Dama', () {
      final score = ScoreCalculator.calculateScorePDF(
        movingChipTerms: {2: 10},
        targetChipTerms: {1: 6},
        operationSymbol: '/',
        targetX: 2,
        targetY: 3,
        isCapture: true,
        isMovingChipDama: true,
        isTargetChipDama: true,
      );

      expect(score, closeTo((5 / 3) * 4, 1e-9));
    });
  });
}
