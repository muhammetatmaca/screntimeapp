import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Button Variants
enum ButtonVariant {
  glass,      // Gri/Beyaz - "Giriş Yap" style
  blue,       // Açık Mavi
  green,      // Açık Yeşil
}

/// Liquid Glass Button - All Variants (Figma Design)
class LiquidGlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final bool showArrow;
  final bool isLoading;
  final double? width;

  const LiquidGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.glass,
    this.showArrow = false,
    this.isLoading = false,
    this.width,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _isPressed = false;

  // Figma'dan: Color(0xFFE6E6E6) - Glass variant için
  Color get _backgroundColor {
    switch (widget.variant) {
      case ButtonVariant.glass:
        return _isPressed 
            ? const Color(0xFFD9D9D9)
            : const Color(0xFFE6E6E6); // Figma exact color
      case ButtonVariant.blue:
        return _isPressed 
            ? const Color(0xFFB8DCFF)
            : const Color(0xFFD0E8FF); // Açık mavi
      case ButtonVariant.green:
        return _isPressed 
            ? const Color(0xFFB8F5D0)
            : const Color(0xFFD0FFE0); // Açık yeşil
    }
  }

  Color get _textColor {
    switch (widget.variant) {
      case ButtonVariant.glass:
        return AppColors.textPrimary;
      case ButtonVariant.blue:
        return const Color(0xFF0066CC);
      case ButtonVariant.green:
        return const Color(0xFF0D6B32);
    }
  }

  Color get _shadowColor {
    switch (widget.variant) {
      case ButtonVariant.glass:
        return Colors.black.withOpacity(0.06);
      case ButtonVariant.blue:
        return const Color(0xFF007AFF).withOpacity(0.2);
      case ButtonVariant.green:
        return const Color(0xFF13EC5B).withOpacity(0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonWidth = widget.width ?? double.infinity;
    const buttonHeight = 56.0;
    final isGlass = widget.variant == ButtonVariant.glass;

    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isLoading ? null : (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: widget.isLoading ? null : () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: buttonWidth,
          height: buttonHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            // Ana arka plan rengi - Figma'dan E6E6E6
            color: isGlass 
                ? (_isPressed ? const Color(0xFFD8D8D8) : const Color(0xFFE6E6E6))
                : _backgroundColor,
            borderRadius: BorderRadius.circular(buttonHeight),
            // Dış border - beyaz %10 opacity
            border: Border.all(
              width: 2,
              color: Colors.white.withOpacity(0.10),
            ),
            boxShadow: [
              // Dış gölge
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.04 : 0.08),
                blurRadius: _isPressed ? 4 : 16,
                offset: Offset(0, _isPressed ? 2 : 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Glass Layer'lar - Figma'daki gibi iç içe katmanlar
              if (isGlass) ...[
                // Layer 1 - En dış, tam boyut
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(buttonHeight),
                      color: Colors.white.withOpacity(0.01),
                    ),
                  ),
                ),
                // Layer 2
                Positioned(
                  left: 2, right: 2, top: 1, bottom: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(buttonHeight),
                      color: Colors.white.withOpacity(0.02),
                    ),
                  ),
                ),
                // Layer 3
                Positioned(
                  left: 5, right: 5, top: 3, bottom: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(buttonHeight),
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                ),
                // Layer 4
                Positioned(
                  left: 10, right: 10, top: 5, bottom: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(buttonHeight),
                      color: Colors.white.withOpacity(0.04),
                    ),
                  ),
                ),
                // Layer 5
                Positioned(
                  left: 18, right: 18, top: 8, bottom: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(buttonHeight),
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                // Üst highlight - parlama efekti
                Positioned(
                  top: 2,
                  left: 8,
                  right: 8,
                  height: buttonHeight * 0.4,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(buttonHeight),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.35),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              // Diğer variantlar için basit glass overlay
              if (!isGlass)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(buttonHeight),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                ),
              
              // Text Content - Tam ortada
              Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.text,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.buttonLarge.copyWith(
                              color: _textColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (widget.showArrow) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _textColor,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Convenience widgets for each variant

/// Primary Button - Glass style (Ana buton - glass efektli)
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool showArrow;
  final bool isLoading;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.showArrow = true,
    this.isLoading = false,
    this.width,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Glass variant for primary button
    return LiquidGlassButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.glass,
      showArrow: showArrow,
      isLoading: isLoading,
      width: width,
    );
  }
}

/// Secondary Button - Glass style (Gri/Beyaz)
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.glass,
      showArrow: false,
      width: width,
    );
  }
}

/// Green Button variant
class GreenButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool showArrow;
  final bool isLoading;
  final double? width;

  const GreenButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.showArrow = true,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.green,
      showArrow: showArrow,
      isLoading: isLoading,
      width: width,
    );
  }
}

/// Blue Button variant
class BlueButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool showArrow;
  final bool isLoading;
  final double? width;

  const BlueButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.showArrow = true,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassButton(
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.blue,
      showArrow: showArrow,
      isLoading: isLoading,
      width: width,
    );
  }
}

/// Circle Icon Button with glass effect
class CircleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 60,
  });

  @override
  State<CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<CircleIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Light blue for circle button
    final bgColor = widget.backgroundColor ?? const Color(0xFF7CC4FF);
    final icnColor = widget.iconColor ?? const Color(0xFF003366);
    final size = widget.size;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: _isPressed 
                ? const Color(0xFF5EAEFF)
                : bgColor,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1.5,
                color: Colors.white.withOpacity(_isPressed ? 0.3 : 0.5),
              ),
              borderRadius: BorderRadius.circular(size / 2),
            ),
            shadows: [
              BoxShadow(
                color: const Color(0xFF007AFF).withOpacity(_isPressed ? 0.2 : 0.35),
                blurRadius: _isPressed ? 6 : 16,
                offset: Offset(0, _isPressed ? 2 : 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glass layers
              _buildCircleGlassLayer(size, 0, 0.02),
              _buildCircleGlassLayer(size - 8, 4, 0.04),
              _buildCircleGlassLayer(size - 16, 8, 0.06),
              _buildCircleGlassLayer(size - 24, 12, 0.08),
              
              // Icon
              Center(
                child: Icon(
                  widget.icon,
                  color: icnColor,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleGlassLayer(double diameter, double offset, double opacity) {
    return Positioned(
      left: offset,
      top: offset,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: ShapeDecoration(
          color: Colors.white.withOpacity(opacity),
          shape: const OvalBorder(),
        ),
      ),
    );
  }
}
