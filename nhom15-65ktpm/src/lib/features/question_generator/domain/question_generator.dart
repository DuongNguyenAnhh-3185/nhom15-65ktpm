import 'dart:math';

import 'package:soroban_kids_app/shared/entities/soroban_question.dart';

/// Difficulty levels implemented by the arithmetic generator.
enum QuestionLevel {
  basic(1),
  friendRules(2);

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
    QuestionType? questionType,
  }) {
    switch (level) {
      case QuestionLevel.basic:
        return _generateBasic(operation: operation);
      case QuestionLevel.friendRules:
        return _generateFriendRules(
          operation: operation,
          questionType: questionType,
        );
    }
  }

  SorobanQuestion _generateFriendRules({
    ArithmeticOperation? operation,
    QuestionType? questionType,
  }) {
    final selectedOperation = operation ?? _randomOperation();
    final selectedType = questionType ??
        (_random.nextBool()
            ? QuestionType.smallFriend
            : QuestionType.bigFriend);

    if (selectedType != QuestionType.smallFriend &&
        selectedType != QuestionType.bigFriend) {
      throw ArgumentError.value(
        selectedType,
        'questionType',
        'Level 2 supports only smallFriend and bigFriend questions.',
      );
    }

    // Reservoir-sample valid operands instead of storing a fixed question list.
    List<int>? selectedOperands;
    var validPairCount = 0;
    for (var first = 0; first <= 99; first++) {
      for (var second = 1; second <= 9; second++) {
        if (!_usesFriendRule(
          type: selectedType,
          operation: selectedOperation,
          first: first,
          second: second,
        )) {
          continue;
        }

        validPairCount++;
        if (_random.nextInt(validPairCount) == 0) {
          selectedOperands = [first, second];
        }
      }
    }

    final operands = selectedOperands;
    if (operands == null) {
      throw StateError(
        'No valid operands for ${selectedType.name} ${selectedOperation.name}.',
      );
    }

    final first = operands[0];
    final second = operands[1];
    final answer = selectedOperation == ArithmeticOperation.addition
        ? first + second
        : first - second;

    return SorobanQuestion(
      id: 'level2_${selectedType.name}_${DateTime.now().microsecondsSinceEpoch}',
      level: QuestionLevel.friendRules.value,
      operands: operands,
      operation: selectedOperation,
      expectedAnswer: answer,
      type: selectedType,
    );
  }

  bool _usesFriendRule({
    required QuestionType type,
    required ArithmeticOperation operation,
    required int first,
    required int second,
  }) {
    final units = first % 10;

    switch (type) {
      case QuestionType.smallFriend:
        if (second >= 5) return false;
        if (operation == ArithmeticOperation.addition) {
          // Cross the 5 boundary without carrying to the next decade.
          return units < 5 && units + second >= 5 && first + second <= 99;
        }
        // Cross down from 5-9 to 0-4 without borrowing from the next decade.
        return units >= 5 && units - second < 5;
      case QuestionType.bigFriend:
        if (operation == ArithmeticOperation.addition) {
          // Use the complement to 10 and keep the answer in the 0-99 range.
          return units + second >= 10 && first + second <= 99;
        }
        // Borrow across a decade while keeping the result non-negative.
        return units < second && first >= second;
      case QuestionType.recognition:
      case QuestionType.flashAnzan:
        return false;
    }
  }

  ArithmeticOperation _randomOperation() => _random.nextBool()
      ? ArithmeticOperation.addition
      : ArithmeticOperation.subtraction;

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
