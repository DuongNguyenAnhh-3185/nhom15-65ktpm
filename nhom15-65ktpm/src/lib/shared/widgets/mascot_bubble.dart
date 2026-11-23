import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'panda_mascot.dart';

class MascotBubbleWidget extends StatelessWidget {
  final String speechText;
  final VoidCallback? onMascotTap;
  final PandaExpression expression;
  final Map<PandaExpression, ImageProvider> expressionImages;

  const MascotBubbleWidget({
    super.key,
    required this.speechText,
    this.onMascotTap,
    this.expression = PandaExpression.happy,
    this.expressionImages = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Semantics(
          label: 'Linh vật Panda',
          button: true,
          child: GestureDetector(
            onTap: onMascotTap,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.accentYellow,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentYellow.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: PandaMascot(
                  expression: expression,
                  image: expressionImages[expression],
                  size: 72,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchSize,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentPurple,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(
              speechText,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.start,
            ),
          ),
        ),
      ],
    );
  }
}
