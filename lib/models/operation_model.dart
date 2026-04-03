/// Represents a mathematical operation in the Derivative Damath game.
class OperationModel {
  /// Type of mathematical operation
  final OperationType type;

  /// Left operand as polynomial terms {exponent: coefficient}
  final Map<int, int> leftOperand;

  /// Right operand as polynomial terms {exponent: coefficient}
  final Map<int, int> rightOperand;

  /// Result of the operation as polynomial terms {exponent: coefficient}
  final Map<int, int> result;

  /// Whether this operation involves derivative application
  final bool isDerivative;

  OperationModel({
    required this.type,
    required this.leftOperand,
    required this.rightOperand,
    Map<int, int>? result,
    this.isDerivative = false,
  }) : result = result ?? {};

  /// Creates a copy of this operation with optional parameter overrides
  OperationModel copyWith({
    OperationType? type,
    Map<int, int>? leftOperand,
    Map<int, int>? rightOperand,
    Map<int, int>? result,
    bool? isDerivative,
  }) {
    return OperationModel(
      type: type ?? this.type,
      leftOperand: leftOperand ?? Map.from(this.leftOperand),
      rightOperand: rightOperand ?? Map.from(this.rightOperand),
      result: result ?? Map.from(this.result),
      isDerivative: isDerivative ?? this.isDerivative,
    );
  }

  /// Returns the string representation of the operation symbol
  String get symbol {
    switch (type) {
      case OperationType.add:
        return '+';
      case OperationType.subtract:
        return '−';
      case OperationType.multiply:
        return '×';
      case OperationType.divide:
        return '÷';
    }
  }

  /// Returns a human-readable description of the operation
  String get description {
    final leftStr = _polynomialToString(leftOperand);
    final rightStr = _polynomialToString(rightOperand);
    final derivStr = isDerivative ? ' (derivative)' : '';
    return '$leftStr $symbol $rightStr = $resultString$derivStr';
  }

  /// Returns the result as a formatted string
  String get resultString => _polynomialToString(result);

  /// Converts polynomial map to string representation
  String _polynomialToString(Map<int, int> poly) {
    if (poly.isEmpty) return '0';
    
    final buffer = StringBuffer();
    final sortedKeys = poly.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (int i = 0; i < sortedKeys.length; i++) {
      final exp = sortedKeys[i];
      final coeff = poly[exp]!;
      
      if (coeff == 0) continue;
      
      if (buffer.isNotEmpty) {
        buffer.write(coeff > 0 ? ' + ' : ' - ');
      } else if (coeff < 0) {
        buffer.write('-');
      }
      
      final absCoeff = coeff.abs();
      final expStr = exp > 0 ? _superscript(exp) : '';
      
      if (exp == 0 || absCoeff != 1) {
        buffer.write(absCoeff);
      }
      
      if (exp > 0) {
        buffer.write('x$expStr');
      }
    }
    
    return buffer.isEmpty ? '0' : buffer.toString();
  }

  /// Converts a number to superscript format
  String _superscript(int exp) {
    const supers = {
      '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵',
      '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹'
    };
    return exp.toString().split('').map((d) => supers[d] ?? '^$d').join();
  }
}

/// Enum representing mathematical operation types
enum OperationType {
  add,
  subtract,
  multiply,
  divide,
}
