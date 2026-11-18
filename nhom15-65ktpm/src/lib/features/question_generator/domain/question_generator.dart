import 'dart:math';

import 'package:soroban_kids_app/shared/entities/soroban_question.dart';

/// Difficulty level currently implemented by the arithmetic generator.
enum QuestionLevel {
  basic(1);

  const QuestionLevel(this.value);

  final int value;

  static QuestionLevel fromValue(int value) {
    return QuestionLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => throw ArgumentError.value(value, 'value', 'Unknown level'),
    );
  }
}

/// Creates addition and subtraction questions for the lesson screens.
class QuestionGenerator {
  QuestionGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Generates a question for [level]. Kept compatible with screens that pass
  /// the level as an integer.
  static SorobanQuestion generate(int level) {
    return QuestionGenerator().generateForLevel(
      QuestionLevel.fromValue(level),
    );
  }

  SorobanQuestion generateForLevel(
    QuestionLevel level, {
    ArithmeticOperation? operation,
  }) {
    switch (level) {
      case QuestionLevel.basic:
        return _generateBasic(operation: operation);
    }
  }

  SorobanQuestion _generateBasic({ArithmeticOperation? operation}) {
    final selectedOperation = operation ??
        (_random.nextInt(2) == 0
            ? ArithmeticOperation.addition
            : ArithmeticOperation.subtraction);
    final firstOperand = _random.nextInt(10);
    final secondOperand = _random.nextInt(
      selectedOperation == ArithmeticOperation.addition
          ? 10 - firstOperand
          : firstOperand + 1,
    );

    final answer = selectedOperation == ArithmeticOperation.addition
        ? firstOperand + secondOperand
        : firstOperand - secondOperand;

    return SorobanQuestion(
      id: 'level1_${DateTime.now().microsecondsSinceEpoch}',
      level: QuestionLevel.basic.value,
      operands: [firstOperand, secondOperand],
      operation: selectedOperation,
      expectedAnswer: answer,
      type: QuestionType.recognition,
    );
  }

}
