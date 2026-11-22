import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';

class KidDecoration extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double rotation;

  const KidDecoration({
    super.key,
    required this.icon,
    required this.color,
    this.size = AppDimensions.iconSizeLarge,
    this.rotation = 0,
  }) : assert(size > 0);

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Icon(
              icon,
              size: size * 0.58,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
