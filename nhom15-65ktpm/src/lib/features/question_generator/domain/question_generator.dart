import 'dart:math';

import 'package:soroban_kids_app/shared/entities/soroban_question.dart';

/// Difficulty levels supported by the arithmetic question generator.
enum QuestionLevel {
  basic(1),
  smallFriend(2),
  mixed(3);

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
  static SorobanQuestion generate(int level, {int flashSpeedMs = 1200}) {
    return QuestionGenerator().generateForLevel(
      QuestionLevel.fromValue(level),
      flashSpeedMs: flashSpeedMs,
    );
  }

  SorobanQuestion generateForLevel(
    QuestionLevel level, {
    int flashSpeedMs = 1200,
  }) {
    switch (level) {
      case QuestionLevel.basic:
        return _generateBasic();
      case QuestionLevel.smallFriend:
        return _generateSmallFriend();
      case QuestionLevel.mixed:
        return _generateMixed(flashSpeedMs: flashSpeedMs);
    }
  }

  SorobanQuestion _generateBasic() {
    const templates = <List<int>>[
      [1, 2],
      [2, 2],
      [5, 3],
      [6, 2],
      [4, -2],
      [7, -5],
      [3, 5],
      [8, -3],
      [5, 4],
      [9, -4],
    ];
    return _questionFromTemplate(
      templates[_random.nextInt(templates.length)],
      level: QuestionLevel.basic,
      type: QuestionType.recognition,
    );
  }

  SorobanQuestion _generateSmallFriend() {
    const templates = <List<int>>[
      [4, 1],
      [3, 2],
      [2, 3],
      [1, 4],
      [5, -1],
      [5, -2],
      [6, -2],
      [7, -3],
      [2, 4],
      [3, 3],
    ];
    return _questionFromTemplate(
      templates[_random.nextInt(templates.length)],
      level: QuestionLevel.smallFriend,
      type: QuestionType.smallFriend,
    );
  }

  SorobanQuestion _generateMixed({required int flashSpeedMs}) {
    const templates = <List<int>>[
      [2, 5, 1],
      [3, 1, 5],
      [7, -2, 3],
      [5, 4, -3],
      [1, 3, 5, -2],
      [4, 5, -3, 2],
      [6, 3, -5, 4],
    ];
    return _questionFromTemplate(
      templates[_random.nextInt(templates.length)],
      level: QuestionLevel.mixed,
      type: QuestionType.flashAnzan,
      flashSpeedMs: flashSpeedMs,
    );
  }

  SorobanQuestion _questionFromTemplate(
    List<int> operands, {
    required QuestionLevel level,
    required QuestionType type,
    int flashSpeedMs = 1200,
  }) {
    final answer = operands.reduce((a, b) => a + b);
    return SorobanQuestion(
      id: 'level${level.value}_${DateTime.now().microsecondsSinceEpoch}',
      level: level.value,
      operands: operands,
      expectedAnswer: answer,
      type: type,
      flashSpeedMs: flashSpeedMs,
    );
  }
}
