class ChipModel {
  final int owner; // 1 = blue, 2 = red
  final int id; // Unique identifier for animation tracking
  int x;
  int y;
  final Map<int, int> terms;
  bool isDama;

  ChipModel({
    required this.owner,
    required this.id,
    required this.x,
    required this.y,
    required this.terms,
    this.isDama = false,
  });

  String get label {
    final buffer = StringBuffer();

    for (final entry in terms.entries) {
      final exp = entry.key;
      final coeff = entry.value;

      if (coeff == 0) continue;

      if (exp == 0) {
        buffer.write(coeff.toString());
      } else if (coeff == 1) {
        buffer.write('x');
      } else if (coeff == -1) {
        buffer.write('-x');
      } else {
        buffer.write('${coeff}x');
      }

      if (exp > 1) buffer.write(_superscript(exp));
    }

    return buffer.toString();
  }

  String _superscript(int exp) {
    const supers = {
      '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵',
      '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹'
    };
    return exp.toString().split('').map((d) => supers[d] ?? '^$d').join();
  }
}
