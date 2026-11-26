import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class KidButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String? label;
  final String? semanticLabel;
  final IconData? icon;
  final Color backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isSelected;

  const KidButton({
    super.key,
    required this.onPressed,
    this.label,
    this.semanticLabel,
    this.icon,
    this.backgroundColor = AppColors.primary,
    this.textColor,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.isSelected = false,
  })  : assert(label != null || icon != null),
        assert(label != null || semanticLabel != null);

  @override
  State<KidButton> createState() => _KidButtonState();
}

class _KidButtonState extends State<KidButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppDimensions.radiusMedium);
    final height = widget.height < AppDimensions.minTouchSize
        ? AppDimensions.minTouchSize
        : widget.height;
    final width = widget.width == null
        ? null
        : widget.width! < AppDimensions.minTouchSize
            ? AppDimensions.minTouchSize
            : widget.width;
    final isSecondaryButton = widget.backgroundColor == AppColors.secondary;
    final foregroundColor = widget.textColor ??
        (isSecondaryButton
            ? AppColors.onSecondary
            : widget.backgroundColor.computeLuminance() > 0.179
                ? Colors.black
                : Colors.white);
    final borderColor =
        isSecondaryButton ? AppColors.secondaryOutline : foregroundColor;
    final borderWidth = widget.isSelected
        ? 2.5
        : isSecondaryButton
            ? 1.5
            : 2.0;
    final shadowColor =
        isSecondaryButton ? AppColors.secondaryOutline : foregroundColor;
    final horizontalPadding = widget.label == null ? 0.0 : 20.0;

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      button: true,
      selected: widget.isSelected,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: Material(
          color: widget.backgroundColor,
          elevation: widget.isSelected
              ? 7
              : isSecondaryButton
                  ? 3
                  : 5,
          borderRadius: borderRadius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: widget.isSelected && !isSecondaryButton
                    ? Colors.white
                    : borderColor,
                width: borderWidth,
              ),
              boxShadow: widget.isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: shadowColor.withValues(
                          alpha: isSecondaryButton ? 0.12 : 0.3,
                        ),
                        blurRadius: isSecondaryButton ? 2 : 0,
                        offset: Offset(0, isSecondaryButton ? 2 : 3),
                      ),
                    ],
            ),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onPressed();
              },
              onTapDown: (_) => setState(() => _scale = 0.94),
              onTapUp: (_) => setState(() => _scale = 1.0),
              onTapCancel: () => setState(() => _scale = 1.0),
              borderRadius: borderRadius,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppDimensions.minTouchSize,
                  minHeight: AppDimensions.minTouchSize,
                ),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Center(
                      child: AnimatedScale(
                        scale: _scale,
                        duration: const Duration(milliseconds: 100),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null)
                              Icon(
                                widget.icon,
                                color: foregroundColor,
                                size: 28,
                              ),
                            if (widget.icon != null && widget.label != null)
                              const SizedBox(width: 8),
                            if (widget.label != null)
                              Flexible(
                                child: Text(
                                  widget.label!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: foregroundColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
