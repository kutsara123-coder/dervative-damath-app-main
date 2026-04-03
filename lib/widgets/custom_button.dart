import 'package:flutter/material.dart';

/// A reusable styled button component for Derivative Damath.
/// Supports icon + text, various color themes, press animation,
/// loading state, and flexible sizing.
class CustomButton extends StatefulWidget {
  /// Button label text
  final String label;

  /// Optional icon displayed on the left of the label
  final IconData? icon;

  /// Button color theme (primary, secondary, danger)
  final CustomButtonColor color;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Whether to show loading indicator
  final bool isLoading;

  /// Whether button should fill available width
  final bool fullWidth;

  /// Custom button height
  final double? height;

  /// Custom button padding
  final EdgeInsets? padding;

  const CustomButton({
    super.key,
    required this.label,
    this.icon,
    this.color = CustomButtonColor.primary,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = false,
    this.height,
    this.padding,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    if (widget.onPressed == null) {
      return widget.color.baseColor.withValues(alpha: 0.5);
    }
    return widget.color.baseColor;
  }

  Color get _textColor {
    return widget.color.textColor;
  }

  IconData? get _effectiveIcon {
    if (widget.isLoading) {
      return null;
    }
    return widget.icon;
  }

  String get _effectiveLabel {
    if (widget.isLoading) {
      return 'Loading...';
    }
    return widget.label;
  }

  @override
  Widget build(BuildContext context) {
    final buttonContent = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Container(
        height: widget.height ?? 48,
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: widget.onPressed != null
              ? [
                  BoxShadow(
                    color: widget.color.baseColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize:
              widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                ),
              )
            else if (_effectiveIcon != null)
              Icon(
                _effectiveIcon,
                color: _textColor,
                size: 20,
              ),
            if ((_effectiveIcon != null || widget.isLoading) &&
                _effectiveLabel.isNotEmpty)
              const SizedBox(width: 8),
            Text(
              _effectiveLabel,
              style: TextStyle(
                color: _textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    final button = GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? (_) => _controller.forward()
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading
          ? (_) => _controller.reverse()
          : null,
      onTapCancel: widget.onPressed != null && !widget.isLoading
          ? () => _controller.reverse()
          : null,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: buttonContent,
    );

    return widget.fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Enum for button color variants
enum CustomButtonColor {
  primary,
  secondary,
  danger,
  success,
}

extension CustomButtonColorExtension on CustomButtonColor {
  Color get baseColor {
    switch (this) {
      case CustomButtonColor.primary:
        return const Color(0xFF3F51B5); // Indigo
      case CustomButtonColor.secondary:
        return const Color(0xFFFF9800); // Orange
      case CustomButtonColor.danger:
        return const Color(0xFFF44336); // Red
      case CustomButtonColor.success:
        return const Color(0xFF4CAF50); // Green
    }
  }

  Color get textColor {
    switch (this) {
      case CustomButtonColor.primary:
      case CustomButtonColor.danger:
      case CustomButtonColor.success:
        return Colors.white;
      case CustomButtonColor.secondary:
        return Colors.white;
    }
  }
}
