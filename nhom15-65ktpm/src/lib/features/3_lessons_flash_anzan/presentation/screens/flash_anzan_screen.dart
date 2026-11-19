import 'package:flutter/material.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';

/// Static placeholder until Flash Anzan is implemented in a later commit.
class FlashAnzanScreen extends StatelessWidget {
  const FlashAnzanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flash Anzan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              const Text(
                'Flash Anzan',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Giao diện minh họa · Sẽ triển khai ở commit sau',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
