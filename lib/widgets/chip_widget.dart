import 'package:flutter/material.dart';

import '../models/chip_model.dart';

class ChipWidget extends StatelessWidget {
  final ChipModel chip;
  final double size;

  const ChipWidget({super.key, required this.chip, this.size = 60});

  @override
  Widget build(BuildContext context) {
    final chipSize = size;
    final isDama = chip.isDama;
    final ownerAccent = chip.owner == 1
        ? const Color(0xFF2B72FF)
        : const Color(0xFFE24C6A);
    final ownerShadow = chip.owner == 1
        ? const Color(0xFF143D96)
        : const Color(0xFF8D2037);
    final ringHighlight = chip.owner == 1
        ? const Color(0xFFBFE4FF)
        : const Color(0xFFFFD3DC);
    final badgeSize = chipSize * 0.28;
    final badgeIconSize = chipSize * 0.18;
    final labelStyle = TextStyle(
      color: const Color(0xFF273145),
      fontWeight: FontWeight.w900,
      fontSize: chipSize * 0.28,
      height: 1.0,
      shadows: [
        Shadow(color: Colors.white.withValues(alpha: 0.65), blurRadius: 3),
      ],
    );

    return SizedBox(
      width: chipSize,
      height: chipSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: chipSize * 0.16,
                  offset: Offset(0, chipSize * 0.11),
                ),
                BoxShadow(
                  color: ownerShadow.withValues(alpha: 0.22),
                  blurRadius: chipSize * 0.10,
                  spreadRadius: chipSize * 0.01,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: chipSize,
                  height: chipSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [ringHighlight, ownerAccent],
                    ),
                    border: Border.all(
                      color: isDama
                          ? const Color(0xFFFFD661)
                          : Colors.white.withValues(alpha: 0.85),
                      width: isDama ? chipSize * 0.05 : chipSize * 0.03,
                    ),
                  ),
                ),
                Container(
                  width: chipSize * 0.80,
                  height: chipSize * 0.80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.2, -0.25),
                      radius: 0.95,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFF6F3EA),
                        Color(0xFFE3DDCF),
                      ],
                    ),
                    border: Border.all(
                      color: ownerAccent.withValues(alpha: 0.20),
                      width: chipSize * 0.018,
                    ),
                  ),
                ),
                Positioned(
                  top: chipSize * 0.18,
                  left: chipSize * 0.20,
                  right: chipSize * 0.20,
                  child: Container(
                    height: chipSize * 0.10,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(chipSize),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: chipSize * 0.09),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: labelStyle,
                        children: _formatPolynomial(chip.terms, labelStyle),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isDama)
            Positioned(
              top: -chipSize * 0.05,
              right: -chipSize * 0.03,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF2A8), Color(0xFFFFB329)],
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: chipSize * 0.03,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB329).withValues(alpha: 0.35),
                      blurRadius: chipSize * 0.08,
                      offset: Offset(0, chipSize * 0.03),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: const Color(0xFF8A5800),
                  size: badgeIconSize,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<TextSpan> _formatPolynomial(Map<int, int> terms, TextStyle labelStyle) {
    final sortedKeys = terms.keys.toList()..sort((a, b) => b.compareTo(a));
    final spans = <TextSpan>[];

    for (final exp in sortedKeys) {
      final coeff = terms[exp]!;
      if (coeff == 0) continue;

      final sign = spans.isEmpty
          ? (coeff < 0 ? '-' : '')
          : (coeff < 0 ? '-' : '+');

      final absCoeff = coeff.abs();
      var coeffStr = '';
      if (absCoeff != 1 || exp == 0) {
        coeffStr = absCoeff.toString();
      }

      var variableStr = '';
      if (exp != 0) {
        variableStr = 'x';
        if (exp != 1) {
          variableStr += _superscript(exp);
        }
      }

      spans.add(
        TextSpan(text: '$sign$coeffStr$variableStr', style: labelStyle),
      );
    }

    return spans;
  }

  String _superscript(int number) {
    const superscriptMap = {
      '-': '⁻',
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
    };

    return number
        .toString()
        .split('')
        .map((digit) => superscriptMap[digit] ?? digit)
        .join();
  }
}
