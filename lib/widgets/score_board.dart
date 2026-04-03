import 'package:flutter/material.dart';

/// A widget that displays the current scores for both players
/// with animated updates and turn indicator.
class ScoreBoard extends StatelessWidget {
  /// Player 1 (blue) score
  final double player1Score;

  /// Player 2 (red) score
  final double player2Score;

  /// Current player turn (1 = blue, 2 = red)
  final int currentPlayer;

  /// Player 1 name (optional, defaults to "Player 1")
  final String player1Name;

  /// Player 2 name (optional, defaults to "Player 2")
  final String player2Name;

  const ScoreBoard({
    super.key,
    required this.player1Score,
    required this.player2Score,
    required this.currentPlayer,
    this.player1Name = 'Player 1',
    this.player2Name = 'Player 2',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF986C46), Color(0xFF5E3724), Color(0xFFB88C60)],
        ),
        border: Border.all(color: const Color(0xFF482B1B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.08),
              Colors.black.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _PlayerScore(
                name: player1Name,
                score: player1Score,
                color: const Color(0xFF6DC8FF),
                isActive: currentPlayer == 1,
              ),
            ),
            _buildDivider(),
            const _VsIndicator(),
            _buildDivider(),
            Expanded(
              child: _PlayerScore(
                name: player2Name,
                score: player2Score,
                color: const Color(0xFFFF8A80),
                isActive: currentPlayer == 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.16),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final String name;
  final double score;
  final Color color;
  final bool isActive;

  const _PlayerScore({
    required this.name,
    required this.score,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final formattedScore = score.toStringAsFixed(2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.08),
          width: isActive ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              formattedScore,
              key: ValueKey<String>(formattedScore),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isActive ? color : Colors.white,
              ),
            ),
          ),
          if (isActive)
            Text(
              'Turn',
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xFFFFD977),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _VsIndicator extends StatelessWidget {
  const _VsIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: const Text(
        'VS',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFD977),
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
