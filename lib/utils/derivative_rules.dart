import 'package:derivative_damath/models/operation_model.dart';

/// Utility class for computing derivatives of polynomials.
///
/// Polynomials are represented as `Map<int, int>` where:
/// - key: exponent (power of x)
/// - value: coefficient
///
/// Example: 3x² + 2x + 1 is represented as {2: 3, 1: 2, 0: 1}
class DerivativeRules {
  /// Computes the derivative of a polynomial using the power rule.
  ///
  /// Power rule: d/dx(axⁿ) = anxⁿ⁻¹
  ///
  /// Examples:
  /// - {2: 3} (3x²) → {1: 6} (6x¹)
  /// - {1: 5} (5x¹) → {0: 5} (5)
  /// - {0: 7} (7) → {} (0)
  ///
  /// [polynomial] - The polynomial to differentiate (exponent → coefficient)
  /// Returns the derivative polynomial
  static Map<int, int> powerRule(Map<int, int> polynomial) {
    final derivative = <int, int>{};

    for (final entry in polynomial.entries) {
      final exponent = entry.key;
      final coefficient = entry.value;

      // Skip zero terms
      if (coefficient == 0) continue;

      // Derivative of a constant (exponent = 0) is 0
      if (exponent == 0) continue;

      // Apply power rule: d/dx(axⁿ) = a*n*x^(n-1)
      final newExponent = exponent - 1;
      final newCoefficient = coefficient * exponent;

      // Only add non-zero coefficients
      if (newCoefficient != 0) {
        derivative[newExponent] = newCoefficient;
      }
    }

    return derivative;
  }

  /// Computes the derivative of a sum of polynomials.
  ///
  /// Sum rule: d/dx(f + g) = f' + g'
  ///
  /// [polynomials] - List of polynomials to sum and differentiate
  /// Returns the derivative of the sum
  static Map<int, int> sumRule(List<Map<int, int>> polynomials) {
    // Combine all polynomials into one
    final combined = <int, int>{};

    for (final poly in polynomials) {
      for (final entry in poly.entries) {
        final exponent = entry.key;
        final coefficient = entry.value;
        combined[exponent] = (combined[exponent] ?? 0) + coefficient;
      }
    }

    return powerRule(combined);
  }

  /// Computes the derivative of the difference of two polynomials.
  ///
  /// Difference rule: d/dx(f - g) = f' - g'
  ///
  /// [left] - The left polynomial (f)
  /// [right] - The right polynomial (g)
  /// Returns the derivative of (f - g)
  static Map<int, int> differenceRule(
      Map<int, int> left, Map<int, int> right) {
    // Subtract right from left
    final difference = <int, int>{};

    // Add all terms from left
    for (final entry in left.entries) {
      difference[entry.key] = entry.value;
    }

    // Subtract all terms from right
    for (final entry in right.entries) {
      difference[entry.key] = (difference[entry.key] ?? 0) - entry.value;
    }

    return powerRule(difference);
  }

  /// Applies the constant multiple rule.
  ///
  /// Constant multiple rule: d/dx(cf) = c * f'
  ///
  /// [polynomial] - The polynomial to differentiate
  /// [constant] - The constant multiplier
  /// Returns the derivative multiplied by the constant
  static Map<int, int> constantMultiple(
      Map<int, int> polynomial, int constant) {
    // First compute the derivative
    final derivative = powerRule(polynomial);

    // Then multiply by the constant
    final result = <int, int>{};
    for (final entry in derivative.entries) {
      final newCoefficient = entry.value * constant;
      if (newCoefficient != 0) {
        result[entry.key] = newCoefficient;
      }
    }

    return result;
  }

  /// Applies the chain rule for composite operations.
  ///
  /// When a polynomial goes through an operation (+, -, ×, ÷),
  /// we compute the derivative accordingly.
  ///
  /// For multiplication: d/dx(f × g) = f' × g + f × g'
  /// For division: d/dx(f ÷ g) = (f' × g - f × g') / g²
  ///
  /// [left] - Left operand polynomial
  /// [right] - Right operand polynomial
  /// [operation] - The operation type
  /// Returns the derivative of the composite operation
  static Map<int, int> chainRule(
    Map<int, int> left,
    Map<int, int> right,
    OperationType operation,
  ) {
    switch (operation) {
      case OperationType.add:
        // d/dx(f + g) = f' + g'
        return _combinePolynomials(
          powerRule(left),
          powerRule(right),
          1, // addition
        );

      case OperationType.subtract:
        // d/dx(f - g) = f' - g'
        return _combinePolynomials(
          powerRule(left),
          powerRule(right),
          -1, // subtraction
        );

      case OperationType.multiply:
        // Product rule: d/dx(f × g) = f' × g + f × g'
        // Since we're working with polynomials, we need to multiply them
        final leftDerivative = powerRule(left);
        final rightDerivative = powerRule(right);

        // f' × g
        final term1 = _multiplyPolynomials(leftDerivative, right);
        // f × g'
        final term2 = _multiplyPolynomials(left, rightDerivative);

        // f' × g + f × g'
        return _combinePolynomials(term1, term2, 1);

      case OperationType.divide:
        // Quotient rule: d/dx(f ÷ g) = (f' × g - f × g') / g²
        return _quotientRule(left, right);
    }
  }

  /// Combines two polynomials with a given operator (+1 for add, -1 for subtract)
  static Map<int, int> _combinePolynomials(
    Map<int, int> poly1,
    Map<int, int> poly2,
    int operator,
  ) {
    final result = <int, int>{};

    // Add all terms from poly1
    for (final entry in poly1.entries) {
      result[entry.key] = entry.value;
    }

    // Add/subtract all terms from poly2
    for (final entry in poly2.entries) {
      final newCoefficient = result[entry.key]! + (entry.value * operator);
      if (newCoefficient != 0) {
        result[entry.key] = newCoefficient;
      } else {
        result.remove(entry.key);
      }
    }

    return result;
  }

  /// Multiplies two polynomials together.
  ///
  /// This is used in the product rule for chain operations.
  static Map<int, int> _multiplyPolynomials(
    Map<int, int> poly1,
    Map<int, int> poly2,
  ) {
    final result = <int, int>{};

    for (final entry1 in poly1.entries) {
      for (final entry2 in poly2.entries) {
        final newExponent = entry1.key + entry2.key;
        final newCoefficient = entry1.value * entry2.value;

        result[newExponent] = (result[newExponent] ?? 0) + newCoefficient;
      }
    }

    // Remove zero coefficients
    result.removeWhere((key, value) => value == 0);

    return result;
  }

  /// Applies the quotient rule for division.
  ///
  /// Quotient rule: d/dx(f ÷ g) = (f' × g - f × g') / g²
  ///
  /// [left] - The numerator polynomial (f)
  /// [right] - The denominator polynomial (g)
  /// Returns the derivative of (f ÷ g)
  static Map<int, int> _quotientRule(
    Map<int, int> left,
    Map<int, int> right,
  ) {
    // Compute f' (derivative of left)
    final leftDerivative = powerRule(left);
    
    // Compute g' (derivative of right)
    final rightDerivative = powerRule(right);
    
    // Compute g² (right squared)
    final rightSquared = _multiplyPolynomials(right, right);
    
    // Compute f' × g
    final term1 = _multiplyPolynomials(leftDerivative, right);
    
    // Compute f × g'
    final term2 = _multiplyPolynomials(left, rightDerivative);
    
    // Compute (f' × g - f × g')
    final numerator = _combinePolynomials(term1, term2, -1);
    
    // Compute (f' × g - f × g') / g²
    // Since we're working with polynomial representations,
    // we divide the exponents by subtracting the right's max exponent
    final result = <int, int>{};
    
    // Find the max exponent in g²
    int divisorExp = 0;
    for (final entry in rightSquared.entries) {
      if (entry.key > divisorExp) {
        divisorExp = entry.key;
      }
    }
    
    // Each term in numerator gets divided by subtracting divisorExp from exponent
    for (final entry in numerator.entries) {
      final newExp = entry.key - divisorExp;
      if (newExp >= 0) {
        result[newExp] = entry.value;
      }
    }
    
    return result;
  }

  /// Validates if a derivative computation is correct by comparing
  /// the computed derivative with an expected result.
  ///
  /// [polynomial] - Original polynomial
  /// [expectedDerivative] - Expected derivative result
  /// Returns true if the derivative is correct
  static bool validateDerivative(
    Map<int, int> polynomial,
    Map<int, int> expectedDerivative,
  ) {
    final computed = powerRule(polynomial);
    return _mapsEqual(computed, expectedDerivative);
  }

  /// Compares two polynomial maps for equality.
  static bool _mapsEqual(Map<int, int> map1, Map<int, int> map2) {
    if (map1.length != map2.length) return false;

    for (final entry in map1.entries) {
      if (map2[entry.key] != entry.value) return false;
    }

    return true;
  }

  /// Computes the derivative based on the operation type.
  ///
  /// This is the main entry point for computing derivatives
  /// in the game context.
  ///
  /// [polynomial] - The polynomial to differentiate
  /// [operation] - Optional operation type for chain rule
  /// [operand] - Optional second operand for chain rule
  /// Returns the derivative polynomial
  static Map<int, int> computeDerivative(
    Map<int, int> polynomial, {
    OperationType? operation,
    Map<int, int>? operand,
  }) {
    if (operation == null || operand == null) {
      // Simple power rule derivative
      return powerRule(polynomial);
    }

    // Chain rule for operations
    return chainRule(polynomial, operand, operation);
  }

  /// Evaluates a polynomial at a given x value.
  ///
  /// Used for testing and validation.
  ///
  /// [polynomial] - The polynomial to evaluate
  /// [x] - The value of x
  /// Returns the polynomial value at x
  static int evaluatePolynomial(Map<int, int> polynomial, int x) {
    int result = 0;

    for (final entry in polynomial.entries) {
      result += entry.value * _pow(x, entry.key);
    }

    return result;
  }

  /// Helper function to compute power (x^n)
  static int _pow(int base, int exponent) {
    if (exponent == 0) return 1;
    if (exponent < 0) return 0; // We don't handle negative exponents

    int result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
