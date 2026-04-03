import 'package:flutter/material.dart';
import '../models/move_history_model.dart';

/// Modal dialog that displays the move history of the game.
///
/// Shows each move with:
/// - Move number
/// - Player who made the move
/// - Movement coordinates
/// - Move type (move, capture, chain capture)
/// - Operation used (if any)
/// - Captured chip terms (if capture)
/// - Calculation details
/// - Points earned
class MoveHistoryModal extends StatelessWidget {
  /// List of all moves in the game
  final List<MoveHistoryEntry> history;
  final String player1Name;
  final String player2Name;

  const MoveHistoryModal({
    super.key,
    required this.history,
    this.player1Name = 'Player 1',
    this.player2Name = 'Player 2',
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: const TextScaler.linear(1.0)),
      child: SafeArea(
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: mediaQuery.size.width * 0.92,
              height: mediaQuery.size.height * 0.72,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  _buildHeader(context),
                  // Move list
                  Expanded(
                    child: history.isEmpty
                        ? _buildEmptyState()
                        : _buildMoveList(),
                  ),
                  // Footer with close button
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.white70, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Move History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${history.length} moves',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, color: Colors.white30, size: 64),
          SizedBox(height: 16),
          Text(
            'No moves yet',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Start playing to see the move history',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return _buildMoveCard(entry, index);
      },
    );
  }

  Widget _buildMoveCard(MoveHistoryEntry entry, int index) {
    // Alternate card colors for better readability
    final isEven = index % 2 == 0;
    final cardColor = isEven
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.1);

    // Player colors
    final playerColor = entry.player == 1
        ? const Color(0xFF42A5F5) // Blue for Player 1
        : const Color(0xFFEF5350); // Red for Player 2

    // Move type icon and color
    IconData moveIcon;
    Color moveTypeColor;
    if (entry.isEndgameBonus) {
      moveIcon = Icons.emoji_events;
      moveTypeColor = Colors.amber;
    } else if (entry.isCapture) {
      if (entry.captureCount > 1) {
        moveIcon = Icons.bolt; // Chain capture
        moveTypeColor = Colors.orange;
      } else {
        moveIcon = Icons.gps_fixed; // Regular capture
        moveTypeColor = Colors.red;
      }
    } else if (entry.isDamaPromotion) {
      moveIcon = Icons.star;
      moveTypeColor = Colors.amber;
    } else {
      moveIcon = Icons.arrow_forward;
      moveTypeColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: playerColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Move number and player
            Row(
              children: [
                // Move number badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: playerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${entry.moveNumber}',
                    style: TextStyle(
                      color: playerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Player name
                Text(
                  entry.player == 1 ? player1Name : player2Name,
                  style: TextStyle(
                    color: playerColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // Move type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: moveTypeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(moveIcon, size: 14, color: moveTypeColor),
                      const SizedBox(width: 4),
                      Text(
                        entry.moveTypeDescription,
                        style: TextStyle(
                          color: moveTypeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Movement coordinates or summary label
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Icon(
                  entry.isEndgameBonus
                      ? Icons.calculate_rounded
                      : Icons.swap_horiz,
                  size: 18,
                  color: Colors.white54,
                ),
                _buildMathText(
                  entry.moveString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
                if (entry.algebraicNotation.isNotEmpty)
                  Text(
                    _normalizeMathText(entry.algebraicNotation),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),

            // Chip terms (if any)
            if (entry.chipTerms.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.circle, size: 10, color: Colors.white38),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMathText(
                          'Chip: ${entry.chipTerms}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        if (entry.isDamaPromotion) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DAMA',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Operation and capture info
            if (entry.isCapture && entry.capturedChipTerms != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.gps_fixed, size: 14, color: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMathText(
                      'Captured: ${entry.capturedChipTerms!}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Operation tile used
            if (entry.operation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: _buildMathText(
                        entry.operation,
                        style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Operation tile',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
            // Calculation details
            if (entry.calculationDetails.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _buildMathText(
                  entry.calculationDetails,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],

            // Enhanced calculation breakdown (step-by-step)
            if (entry.calculationBreakdown != null) ...[
              const SizedBox(height: 8),
              _buildCalculationBreakdown(entry.calculationBreakdown!),
            ],

            // Points earned
            if (entry.pointsEarned != 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (entry.pointsEarned > 0 ? Colors.green : Colors.red)
                              .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.pointsString,
                      style: TextStyle(
                        color: entry.pointsEarned > 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.withValues(alpha: 0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the step-by-step calculation breakdown display
  Widget _buildCalculationBreakdown(CalculationBreakdown breakdown) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.calculate, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Calculation Breakdown',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Score: ${breakdown.finalScore.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    softWrap: true,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Steps
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: breakdown.steps
                  .map((step) => _buildStepWidget(step, breakdown))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single step in the calculation breakdown
  Widget _buildStepWidget(
    CalculationStep step,
    CalculationBreakdown breakdown,
  ) {
    // Get color based on step icon/type
    Color stepColor;
    switch (step.iconName) {
      case 'combine':
        stepColor = Colors.blue;
        break;
      case 'derivative':
        stepColor = Colors.purple;
        break;
      case 'calculate':
        stepColor = Colors.green;
        break;
      case 'star':
        stepColor = Colors.amber;
        break;
      case 'bolt':
        stepColor = Colors.orange;
        break;
      default:
        stepColor = Colors.white70;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: stepColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: stepColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: stepColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${step.stepNumber}',
                    style: TextStyle(
                      color: stepColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMathText(
                  step.title,
                  style: TextStyle(
                    color: stepColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Description
          _buildMathText(
            step.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 4),
          // Expression
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _buildMathText(
              step.expression,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Result if available
          if (step.result != null) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              alignment: Alignment.centerRight,
              child: _buildMathText(
                '= ${step.result!}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: stepColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMathText(
    String value, {
    required TextStyle style,
    TextAlign textAlign = TextAlign.start,
  }) {
    final normalized = _prepareMathText(value);
    return RichText(
      textAlign: textAlign,
      text: TextSpan(
        style: style,
        children: _buildMathSpans(normalized, style),
      ),
    );
  }

  List<InlineSpan> _buildMathSpans(String value, TextStyle style) {
    final spans = <InlineSpan>[];
    final plainText = StringBuffer();

    void flushPlainText() {
      if (plainText.length == 0) {
        return;
      }
      spans.add(TextSpan(text: plainText.toString()));
      plainText.clear();
    }

    var index = 0;
    while (index < value.length) {
      if (value[index] == '^') {
        var exponentStart = index + 1;
        if (exponentStart < value.length && value[exponentStart] == '-') {
          exponentStart++;
        }

        var exponentEnd = exponentStart;
        while (exponentEnd < value.length &&
            _isAsciiDigit(value[exponentEnd])) {
          exponentEnd++;
        }

        if (exponentEnd > exponentStart) {
          flushPlainText();
          final exponent = value.substring(index + 1, exponentEnd);
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.aboveBaseline,
              baseline: TextBaseline.alphabetic,
              child: Text(
                exponent,
                textScaler: const TextScaler.linear(1.0),
                style: style.copyWith(
                  fontSize: (style.fontSize ?? 12) * 0.72,
                  height: 1.0,
                ),
              ),
            ),
          );
          index = exponentEnd;
          continue;
        }
      }

      plainText.write(value[index]);
      index++;
    }

    flushPlainText();
    return spans;
  }

  String _prepareMathText(String value) {
    var normalized = value.replaceAll('\u00A0', ' ');

    const replacements = <String, String>{
      '\u00E2\u0086\u0092': '->',
      '\u00E2\u0088\u0092': '-',
      '\u00C3\u0097': '*',
      '\u00C3\u00B7': '/',
      '\u00E2\u0081\u00BB': '\u207B',
      '\u00E2\u0081\u00B0': '\u2070',
      '\u00E2\u0081\u00B4': '\u2074',
      '\u00E2\u0081\u00B5': '\u2075',
      '\u00E2\u0081\u00B6': '\u2076',
      '\u00E2\u0081\u00B7': '\u2077',
      '\u00E2\u0081\u00B8': '\u2078',
      '\u00E2\u0081\u00B9': '\u2079',
      '\u00C2\u00B9': '\u00B9',
      '\u00C2\u00B2': '\u00B2',
      '\u00C2\u00B3': '\u00B3',
    };

    for (final entry in replacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }

    normalized = normalized
        .replaceAll('\u2192', '->')
        .replaceAll('\u2212', '-')
        .replaceAll('\u00D7', '*')
        .replaceAll('\u00F7', '/');

    final buffer = StringBuffer();
    var index = 0;
    while (index < normalized.length) {
      final digit = _parseSuperscriptDigit(normalized[index]);
      if (digit == null) {
        buffer.write(normalized[index]);
        index++;
        continue;
      }

      final exponent = StringBuffer();
      while (index < normalized.length) {
        final nextDigit = _parseSuperscriptDigit(normalized[index]);
        if (nextDigit == null) {
          break;
        }
        exponent.write(nextDigit);
        index++;
      }
      buffer.write('^${exponent.toString()}');
    }

    return buffer.toString();
  }

  String? _parseSuperscriptDigit(String character) {
    switch (character) {
      case '\u207B':
        return '-';
      case '\u2070':
        return '0';
      case '\u00B9':
        return '1';
      case '\u00B2':
        return '2';
      case '\u00B3':
        return '3';
      case '\u2074':
        return '4';
      case '\u2075':
        return '5';
      case '\u2076':
        return '6';
      case '\u2077':
        return '7';
      case '\u2078':
        return '8';
      case '\u2079':
        return '9';
      default:
        return null;
    }
  }

  bool _isAsciiDigit(String character) {
    final codeUnit = character.codeUnitAt(0);
    return codeUnit >= 48 && codeUnit <= 57;
  }

  String _normalizeMathText(String value) {
    var normalized = value;

    const mojibakeReplacements = <String, String>{
      'â†’': '->',
      'âˆ’': '-',
      'Ã—': '*',
      'Ã·': '/',
      'â»': '⁻',
      'â°': '⁰',
      'â´': '⁴',
      'âµ': '⁵',
      'â¶': '⁶',
      'â·': '⁷',
      'â¸': '⁸',
      'â¹': '⁹',
      'Â¹': '¹',
      'Â²': '²',
      'Â³': '³',
    };

    for (final entry in mojibakeReplacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }

    normalized = normalized
        .replaceAll('→', '->')
        .replaceAll('−', '-')
        .replaceAll('×', '*')
        .replaceAll('÷', '/');

    final buffer = StringBuffer();
    var index = 0;
    while (index < normalized.length) {
      final digit = _superscriptDigit(normalized[index]);
      if (digit == null) {
        buffer.write(normalized[index]);
        index++;
        continue;
      }

      final exponent = StringBuffer();
      while (index < normalized.length) {
        final nextDigit = _superscriptDigit(normalized[index]);
        if (nextDigit == null) {
          break;
        }
        exponent.write(nextDigit);
        index++;
      }
      buffer.write('^${exponent.toString()}');
    }

    return buffer.toString();
  }

  String? _superscriptDigit(String character) {
    switch (character) {
      case '⁻':
        return '-';
      case '⁰':
        return '0';
      case '¹':
        return '1';
      case '²':
        return '2';
      case '³':
        return '3';
      case '⁴':
        return '4';
      case '⁵':
        return '5';
      case '⁶':
        return '6';
      case '⁷':
        return '7';
      case '⁸':
        return '8';
      case '⁹':
        return '9';
      default:
        return null;
    }
  }
}

/// Shows the move history modal dialog.
///
/// [context] - The build context
/// [history] - The list of move history entries to display
void showMoveHistoryModal(
  BuildContext context,
  List<MoveHistoryEntry> history,
) {
  showDialog(
    context: context,
    builder: (context) => MoveHistoryModal(history: history),
  );
}
