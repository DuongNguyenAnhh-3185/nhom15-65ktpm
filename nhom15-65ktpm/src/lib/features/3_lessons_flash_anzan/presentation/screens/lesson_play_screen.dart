import 'package:flutter/material.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/finger_math_controller.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/finger_math_board_widget.dart';
import 'package:soroban_kids_app/features/question_generator/domain/question_generator.dart';
import 'package:soroban_kids_app/shared/entities/soroban_question.dart';

/// Arithmetic practice for basic and friend-rule levels.
class LessonPlayScreen extends StatefulWidget {
  const LessonPlayScreen({super.key, this.level = 1});

  final int level;

  @override
  State<LessonPlayScreen> createState() => _LessonPlayScreenState();
}

class _LessonPlayScreenState extends State<LessonPlayScreen> {
  final QuestionGenerator _generator = QuestionGenerator();
  late final FingerMathController _fingerController;
  late SorobanQuestion _question;

  bool get _isLevel2 => widget.level == 2;

  bool _hasCheckedAnswer = false;
  bool _answeredCorrectly = false;
  int _questionNumber = 1;

  @override
  void initState() {
    super.initState();
    _fingerController = FingerMathController(showLeftHand: _isLevel2);
    _loadQuestion(isFirstQuestion: true);
  }

  @override
  void dispose() {
    _fingerController.dispose();
    super.dispose();
  }

  void _loadQuestion({bool isFirstQuestion = false}) {
    _question = _generator.generateForLevel(
      _isLevel2 ? QuestionLevel.friendRules : QuestionLevel.basic,
    );
    _fingerController.setValue(_question.operands.first);
    _hasCheckedAnswer = false;
    _answeredCorrectly = false;
    if (!isFirstQuestion) _questionNumber++;
  }

  void _checkAnswer() {
    final isCorrect = _fingerController.totalValue == _question.expectedAnswer;
    setState(() {
      _hasCheckedAnswer = true;
      _answeredCorrectly = isCorrect;
    });
  }

  void _tryAgain() {
    setState(() {
      _fingerController.setValue(_question.operands.first);
      _hasCheckedAnswer = false;
    });
  }

  void _nextQuestion() {
    setState(_loadQuestion);
  }

  @override
  Widget build(BuildContext context) {
    final firstOperand = _question.operands[0];
    final secondOperand = _question.operands[1];
    final isAddition = _question.operation == ArithmeticOperation.addition;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLevel2
              ? 'Cấp độ 2 · Anh bạn nhỏ & Anh bạn lớn'
              : 'Cấp độ 1 · Bé cùng tính nhé!',
        ),
        backgroundColor: AppColors.cardBg,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final handBoardHeight =
                (constraints.maxHeight * 0.38).clamp(170.0, 260.0).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                        child: Text(
                          'Câu $_questionNumber',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Text(
                          'Bé hãy dùng bàn tay để tìm đáp án nhé!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border:
                              Border.all(color: AppColors.secondary, width: 2),
                        ),
                        child: Text(
                          '${_question.formulaExpression} = ?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (_isLevel2)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildFriendRuleCard(secondOperand),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _isLevel2
                              ? _question.type == QuestionType.smallFriend
                                  ? 'Dùng quy tắc bù 5 để tính nhé!'
                                  : 'Dùng quy tắc bù 10 bằng hai bàn tay nhé!'
                              : isAddition
                                  ? 'Bắt đầu từ $firstOperand rồi xòe thêm $secondOperand nhé.'
                                  : 'Bắt đầu từ $firstOperand rồi gập bớt $secondOperand nhé.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textLight),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FingerMathBoardWidget(
                          controller: _fingerController,
                          height: handBoardHeight,
                          showLiveValue: true,
                        ),
                      ),
                      if (_hasCheckedAnswer)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: _buildAnswerFeedback(
                            firstOperand: firstOperand,
                            secondOperand: secondOperand,
                            isAddition: isAddition,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _answeredCorrectly
                                ? _nextQuestion
                                : !_hasCheckedAnswer
                                    ? _checkAnswer
                                    : _tryAgain,
                            icon: Icon(
                              _answeredCorrectly
                                  ? Icons.arrow_forward_rounded
                                  : !_hasCheckedAnswer
                                      ? Icons.check_rounded
                                      : Icons.refresh_rounded,
                            ),
                            label: Text(
                              _answeredCorrectly
                                  ? 'CÂU TIẾP THEO'
                                  : !_hasCheckedAnswer
                                      ? 'KIỂM TRA'
                                      : 'THỬ LẠI',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFriendRuleCard(int secondOperand) {
    final isSmallFriend = _question.type == QuestionType.smallFriend;
    final base = isSmallFriend ? 5 : 10;
    final complement = base - secondOperand;
    final isAddition = _question.operation == ArithmeticOperation.addition;
    final rule = isAddition
        ? '+$secondOperand = +$base - $complement'
        : '-$secondOperand = -$base + $complement';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSmallFriend ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSmallFriend ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Column(
        children: [
          Text(
            isSmallFriend ? 'ANH BẠN NHỎ · BÙ 5' : 'ANH BẠN LỚN · BÙ 10',
            style: TextStyle(
              color: isSmallFriend
                  ? Colors.green.shade800
                  : Colors.orange.shade900,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            rule,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerFeedback({
    required int firstOperand,
    required int secondOperand,
    required bool isAddition,
  }) {
    final backgroundColor =
        _answeredCorrectly ? const Color(0xFFE8F7EE) : const Color(0xFFFFF1E8);
    final accentColor =
        _answeredCorrectly ? AppColors.success : AppColors.error;
    final title =
        _answeredCorrectly ? 'CHÍNH XÁC!' : 'CHƯA ĐÚNG, BÉ THỬ LẠI NHÉ!';
    final message = _answeredCorrectly
        ? 'Bé đã tìm được đáp án ${_question.expectedAnswer}. Giỏi quá!'
        : 'Bàn tay đang chỉ số ${_fingerController.totalValue}. '
            '${isAddition ? 'Bắt đầu từ $firstOperand rồi xòe thêm $secondOperand ngón.' : 'Bắt đầu từ $firstOperand rồi gập bớt $secondOperand ngón.'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            _answeredCorrectly
                ? Icons.celebration_rounded
                : Icons.lightbulb_outline_rounded,
            color: accentColor,
            size: 32,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
