import 'package:flutter/material.dart';
import '../models/chip_model.dart';
import 'chip_widget.dart';

/// A draggable chip widget that allows players to drag chips
/// to destination tiles with visual feedback and drop validation.
class DraggablePiece extends StatefulWidget {
  /// The chip model to display and drag
  final ChipModel chip;

  /// Callback when drag completes successfully
  final void Function(int fromX, int fromY, int toX, int toY)? onDragComplete;

  /// Function to validate if a drop target is valid
  final bool Function(int x, int y)? isValidTarget;

  /// Size of the chip
  final double size;

  /// Whether the chip is currently draggable (based on turn)
  final bool isDraggable;

  const DraggablePiece({
    super.key,
    required this.chip,
    this.onDragComplete,
    this.isValidTarget,
    this.size = 60.0,
    this.isDraggable = true,
  });

  @override
  State<DraggablePiece> createState() => _DraggablePieceState();
}

class _DraggablePieceState extends State<DraggablePiece>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  bool _isHovering = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isDraggable) {
      // Return non-draggable chip widget
      return ChipWidget(chip: widget.chip, size: widget.size);
    }

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      child: Draggable<ChipModel>(
        data: widget.chip,
        onDragStarted: () {
          setState(() {
            _isDragging = true;
          });
          _controller.forward();
        },
        onDragEnd: (_) {
          setState(() {
            _isDragging = false;
          });
          _controller.reverse();
        },
        onDragCompleted: () {
          setState(() {
            _isDragging = false;
          });
        },
        feedback: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -widget.size * 0.08),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(opacity: 0.92, child: _buildChipWithShadow()),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.26,
          child: ChipWidget(chip: widget.chip, size: widget.size),
        ),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          tween: Tween<double>(
            begin: 0,
            end: _isDragging
                ? -widget.size * 0.10
                : _isHovering
                ? -widget.size * 0.04
                : 0,
          ),
          builder: (context, lift, child) {
            return Transform.translate(
              offset: Offset(0, lift),
              child: child,
            );
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _isDragging ? 0.55 : 1.0,
            child: ChipWidget(chip: widget.chip, size: widget.size),
          ),
        ),
      ),
    );
  }

  Widget _buildChipWithShadow() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ChipWidget(chip: widget.chip, size: widget.size),
    );
  }
}

/// A drop target for the draggable piece.
/// Validates drops and provides visual feedback.
class PieceDropTarget extends StatefulWidget {
  /// X position on the board
  final int x;

  /// Y position on the board
  final int y;

  /// Whether this tile is occupied
  final bool isOccupied;

  /// Whether this is a valid drop target
  final bool isValidTarget;

  /// Callback when a piece is dropped here
  final void Function(ChipModel chip)? onPieceDropped;

  /// Child widget to display (usually the tile)
  final Widget child;

  const PieceDropTarget({
    super.key,
    required this.x,
    required this.y,
    required this.isOccupied,
    required this.isValidTarget,
    this.onPieceDropped,
    required this.child,
  });

  @override
  State<PieceDropTarget> createState() => _PieceDropTargetState();
}

class _PieceDropTargetState extends State<PieceDropTarget> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<ChipModel>(
      onWillAcceptWithDetails: (details) {
        if (!widget.isOccupied && widget.isValidTarget) {
          setState(() {
            _isHovering = true;
          });
          return true;
        }
        return false;
      },
      onLeave: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      onAcceptWithDetails: (details) {
        setState(() {
          _isHovering = false;
        });
        widget.onPieceDropped?.call(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            border: _isHovering
                ? Border.all(color: Colors.green, width: 3)
                : null,
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        );
      },
    );
  }
}
