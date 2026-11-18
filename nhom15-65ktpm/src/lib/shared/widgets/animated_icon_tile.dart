import 'package:flutter/material.dart';

class AnimatedIconTile extends StatefulWidget {
  final IconData icon;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;
  final double height;

  const AnimatedIconTile({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
    this.height = 132,
  });

  @override
  State<AnimatedIconTile> createState() => _AnimatedIconTileState();
}

class _AnimatedIconTileState extends State<AnimatedIconTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: Tooltip(
        message: widget.semanticLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(28),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final progress = _animationController.value;
                return Transform.translate(
                  offset: Offset(0, -4 * progress),
                  child: Transform.rotate(
                    angle: (progress - 0.5) * 0.08,
                    child: Transform.scale(
                      key: const ValueKey('animated-icon-motion'),
                      scale: 0.96 + (progress * 0.08),
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 52,
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
