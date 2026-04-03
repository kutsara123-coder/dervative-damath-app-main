import 'package:flutter/material.dart';
import '../models/player_model.dart';

/// A card widget that displays player information including:
/// - Player name
/// - Color indicator
/// - Chips remaining count
/// - Captured pieces count
/// - Remaining time for turn (if active)
class PlayerInfoCard extends StatelessWidget {
  /// The player model containing all player data
  final PlayerModel player;

  /// Number of chips currently on the board for this player
  final int chipsRemaining;

  /// Number of pieces captured by this player
  final int capturedCount;

  /// Whether this player is currently active (it's their turn)
  final bool isActive;

  /// Remaining time in seconds for the current turn (null if not active)
  final int? remainingTime;

  const PlayerInfoCard({
    super.key,
    required this.player,
    required this.chipsRemaining,
    required this.capturedCount,
    this.isActive = false,
    this.remainingTime,
  });

  /// Format seconds to MM:SS
  String get _formattedTime {
    if (remainingTime == null) return '--:--';
    final minutes = remainingTime! ~/ 60;
    final seconds = remainingTime! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Check if time is low (30 seconds or less)
  bool get _isLowTime => remainingTime != null && remainingTime! <= 30;

  Color get _playerColor {
    return player.color == PlayerColor.blue ? Colors.blue : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final formattedScore = player.score.toStringAsFixed(2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8C6241), Color(0xFF563222), Color(0xFFB38659)],
        ),
        border: Border.all(color: const Color(0xFF452919), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.20),
              Colors.white.withValues(alpha: 0.08),
              Colors.black.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive
                ? _playerColor.withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.10),
            width: isActive ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Name and Color indicator
            Row(
              children: [
                // Color indicator circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _playerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _playerColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                // Player name
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      player.name,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Active indicator
                if (isActive && remainingTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isLowTime
                            ? const [Color(0xFFFFC15F), Color(0xFFE07A21)]
                            : [
                                _playerColor.withValues(alpha: 0.95),
                                _playerColor.withValues(alpha: 0.70),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (_isLowTime ? Colors.orange : _playerColor)
                              .withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Stats row
            Row(
              children: [
                // Chips remaining
                Expanded(
                  child: _StatItem(
                    icon: Icons.circle,
                    iconColor: _playerColor,
                    label: 'Chips',
                    value: chipsRemaining.toString(),
                  ),
                ),
                const SizedBox(width: 4),
                // Captured pieces
                Expanded(
                  child: _StatItem(
                    icon: Icons.close,
                    iconColor: const Color(0xFFFF8A80),
                    label: 'Captured',
                    value: capturedCount.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Score display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formattedScore,
                    style: TextStyle(
                      color: _playerColor.withValues(alpha: 0.95),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 12),
        const SizedBox(width: 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: Colors.white.withValues(alpha: 0.68),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
