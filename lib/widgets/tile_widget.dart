// lib/widgets/tile_widget.dart
import 'package:flutter/material.dart';

class TileWidget extends StatelessWidget {
  final double size;
  final bool isDark;
  final String operation;
  final Widget? chip;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final bool showOperationBold;

  const TileWidget({
    super.key,
    required this.size,
    required this.isDark,
    required this.operation,
    this.chip,
    this.onTap,
    this.isHighlighted = false,
    this.showOperationBold = true,
  });

  Color get lightTile => const Color(0xFFF2F2F2); // B2 light
  Color get darkTile => const Color(0xFF555555); // B2 dark

  @override
  Widget build(BuildContext context) {
    final tileColor = isHighlighted
    ? Colors.lightBlue.withValues(alpha: 0.45)
    : (isDark ? darkTile : lightTile);


    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tileColor,
          border: Border.all(color: Colors.grey.shade400, width: 0.5),
        ),
        child: Stack(
          children: [
            if (operation.isNotEmpty)
              Center(
                child: Text(
                operation,
                 style: TextStyle(
                 fontSize: size * 0.34,
                 fontWeight: showOperationBold ? FontWeight.w700 : FontWeight.w500,
                 color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black87,
                 ),
                ),

              ),
            if (chip != null) Center(child: chip),
          ],
        ),
      ),
    );
  }
}
