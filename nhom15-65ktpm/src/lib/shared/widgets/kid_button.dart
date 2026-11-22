import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class KidButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String? label;
  final String? semanticLabel;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final double? width;
  final double height;

  const KidButton({
    super.key,
    required this.onPressed,
    this.label,
    this.semanticLabel,
    this.icon,
    this.backgroundColor = AppColors.primary,
    this.textColor = AppColors.onPrimary,
    this.width,
    this.height = AppDimensions.buttonHeight,
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
    final horizontalPadding = widget.label == null ? 0.0 : 20.0;

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      button: true,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          child: Material(
            color: widget.backgroundColor,
            elevation: 3,
            borderRadius: borderRadius,
            child: InkWell(
              onTap: widget.onPressed,
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
                  width: widget.width,
                  height: height,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null)
                            Icon(
                              widget.icon,
                              color: widget.textColor,
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
                                      color: widget.textColor,
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
    );
  }
}
