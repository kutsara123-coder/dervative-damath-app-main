// test/derivative_rules_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:derivative_damath/utils/derivative_rules.dart';

void main() {
  group('DerivativeRules - Power Rule Tests', () {
    test('Power rule: d/dx(3x²) = 6x¹', () {
      final polynomial = {2: 3};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({1: 6}));
    });

    test('Power rule: d/dx(5x³) = 15x²', () {
      final polynomial = {3: 5};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({2: 15}));
    });

    test('Power rule: d/dx(x⁴) = 4x³', () {
      final polynomial = {4: 1};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({3: 4}));
    });

    test('Power rule: Constant d/dx(5) = 0', () {
      final polynomial = {0: 5};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({}));
    });
  });

  group('DerivativeRules - Sum/Difference Rule Tests', () {
    test('Sum rule: d/dx(3x² + 2x) = 6x + 2', () {
      final polynomial = {2: 3, 1: 2};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({1: 6, 0: 2}));
    });

    test('Difference rule: d/dx(5x³ - 2x²) = 15x² - 4x', () {
      final polynomial = {3: 5, 2: -2};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({2: 15, 1: -4}));
    });
  });

  group('DerivativeRules - Constant Multiple Tests', () {
    test('Constant multiple: d/dx(4x²) = 8x', () {
      final polynomial = {2: 4};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({1: 8}));
    });

    test('Constant multiple with combined polynomial', () {
      final polynomial = {2: 6, 1: 8};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({1: 12, 0: 8}));
    });
  });

  group('DerivativeRules - Edge Cases', () {
    test('Zero coefficient → removed from result', () {
      // When coefficient is 0, the term should not appear in result
      final polynomial = {2: 0, 1: 5};
      final result = DerivativeRules.powerRule(polynomial);
      // Only 5x should remain, derivative is 5
      expect(result, equals({0: 5}));
    });

    test('Exponent of 1 → constant', () {
      final polynomial = {1: 5};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({0: 5}));
    });

    test('Negative coefficients', () {
      final polynomial = {2: -3};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({1: -6}));
    });

    test('Empty polynomial → empty', () {
      final polynomial = <int, int>{};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({}));
    });

    test('Complex polynomial: 2x³ + 3x² + x + 5', () {
      final polynomial = {3: 2, 2: 3, 1: 1, 0: 5};
      final result = DerivativeRules.powerRule(polynomial);
      expect(result, equals({2: 6, 1: 6, 0: 1}));
    });

    test('Coefficient of 1 with exponent', () {
      final polynomial = {3: 1, 2: 1};
      final result = DerivativeRules.powerRule(polynomial);
      // 1*x³ -> 3x², 1*x² -> 2x
      expect(result, equals({2: 3, 1: 2}));
    });
  });

  group('DerivativeRules - Validate Derivative', () {
    test('Validate correct derivative', () {
      final polynomial = {2: 3};
      final expected = {1: 6};
      final isValid = DerivativeRules.validateDerivative(polynomial, expected);
      expect(isValid, isTrue);
    });

    test('Validate incorrect derivative', () {
      final polynomial = {2: 3};
      final expected = {1: 5};
      final isValid = DerivativeRules.validateDerivative(polynomial, expected);
      expect(isValid, isFalse);
    });
  });

  group('DerivativeRules - Evaluate Polynomial', () {
    test('Evaluate polynomial at x=2', () {
      final polynomial = {2: 3, 1: 2, 0: 1};
      final result = DerivativeRules.evaluatePolynomial(polynomial, 2);
      expect(result, equals(17));
    });

    test('Evaluate constant at x=5', () {
      final polynomial = {0: 5};
      final result = DerivativeRules.evaluatePolynomial(polynomial, 5);
      expect(result, equals(5));
    });

    test('Evaluate x at x=3', () {
      final polynomial = {1: 1};
      final result = DerivativeRules.evaluatePolynomial(polynomial, 3);
      expect(result, equals(3));
    });
  });

  group('DerivativeRules - Sum Rule', () {
    test('Sum rule combines polynomials then differentiates', () {
      final poly1 = {2: 1};
      final poly2 = {1: 2};
      final result = DerivativeRules.sumRule([poly1, poly2]);
      expect(result, equals({1: 2, 0: 2}));
    });
  });

  group('DerivativeRules - Difference Rule', () {
    test('Difference rule: d/dx(3x² - x) = 6x - 1', () {
      final left = {2: 3};
      final right = {1: 1};
      final result = DerivativeRules.differenceRule(left, right);
      expect(result, equals({1: 6, 0: -1}));
    });
  });

  group('DerivativeRules - Constant Multiple Rule', () {
    test('Constant multiple: d/dx(3 * x²) = 6x', () {
      final polynomial = {2: 1};
      final constant = 3;
      final result = DerivativeRules.constantMultiple(polynomial, constant);
      expect(result, equals({1: 6}));
    });
  });
}
