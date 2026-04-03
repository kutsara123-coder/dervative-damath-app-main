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

  factory ChipModel.fromJson(Map<String, dynamic> json) {
    final rawTerms = (json['terms'] as Map?) ?? const <dynamic, dynamic>{};

    return ChipModel(
      owner: json['owner'] as int? ?? 1,
      id: json['id'] as int? ?? 0,
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      isDama: json['isDama'] as bool? ?? false,
      terms: rawTerms.map(
        (key, value) => MapEntry(
          int.parse(key.toString()),
          (value as num?)?.toInt() ?? 0,
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner': owner,
      'id': id,
      'x': x,
      'y': y,
      'isDama': isDama,
      'terms': {for (final entry in terms.entries) '${entry.key}': entry.value},
    };
  }

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
