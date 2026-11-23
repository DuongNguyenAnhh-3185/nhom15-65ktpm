import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class KidCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const KidCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.color = AppColors.cardBg,
    this.padding = const EdgeInsets.all(AppDimensions.paddingMedium),
    this.borderRadius = AppDimensions.radiusLarge,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final card = Material(
      color: color,
      elevation: 2,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppDimensions.minTouchSize,
            minHeight: AppDimensions.minTouchSize,
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );

    if (semanticLabel == null) return card;

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: card,
    );
  }
}
