import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/attempt_log.dart';
import '../../../../shared/entities/soroban_question.dart';
import '../../../../shared/widgets/mascot_bubble.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/domain/entities/finger_hand_state.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/finger_math_controller.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/finger_math_board_widget.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/presentation/widgets/voice_answer_mic_button.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/domain/question_generator.dart';

class LessonPlayScreen extends StatefulWidget {
  final int level;

  const LessonPlayScreen({super.key, required this.level});

  @override
  State<LessonPlayScreen> createState() => _LessonPlayScreenState();
}

class _LessonPlayScreenState extends State<LessonPlayScreen> {
  final AudioService _audioService = sl<AudioService>();
  final StorageService _storageService = sl<StorageService>();
  late FingerMathController _fingerController;

  late SorobanQuestion _currentQuestion;
  int _questionIndex = 1;
  String _mascotSpeech = 'Bé hãy nhìn phép tính và gảy ngón tay Finger Math nhé!';
  String _formulaHint = '';
  DateTime _questionStartTime = DateTime.now();

  // Trạng thái hoàn thành & xem lại câu hỏi
  bool _hasAnswered = false;
  bool _isAnswerCorrect = false;
  int _submittedAnswer = 0;
  FingerMathGuidance? _guidance;

  @override
  void initState() {
    super.initState();
    // Cấp 1 & 2 dùng 1 bàn tay phải (hàng đơn vị) hoặc 2 bàn tay nếu kết quả > 9
    _fingerController = FingerMathController(showLeftHand: widget.level >= 2);
    _loadNextQuestion();
  }

  @override
  void dispose() {
    _fingerController.dispose();
    super.dispose();
  }

  void _loadNextQuestion() {
    setState(() {
      _currentQuestion = QuestionGenerator.generate(widget.level);
      _hasAnswered = false;
      _isAnswerCorrect = false;
      _submittedAnswer = 0;
      _guidance = null;
      _fingerController.reset();
      _questionStartTime = DateTime.now();

      // Gợi ý phương pháp tính Finger Math
      _formulaHint = _getFingerMathFormulaHint(_currentQuestion);
      _mascotSpeech = 'Phép tính: ${_currentQuestion.formulaExpression} = ?\n$_formulaHint';
    });

    // Phát âm đề bài với đầy đủ dấu phép tính ("cộng", "trừ") bằng tiếng Việt
    _audioService.speak(
      'Bé ơi, hãy tính: ${_currentQuestion.spokenExpression}. Bằng bao nhiêu bé nhỉ?',
    );
  }

  String _getFingerMathFormulaHint(SorobanQuestion q) {
    if (q.level == 1) {
      return 'Bung các ngón tay trên Tay Phải (đơn vị: 0-9) theo từng số nhé!';
    }
    for (final op in q.operands) {
      if (op == 9) return 'Anh Bạn Lớn (+9 = +10 - 1): Bung 1 ngón Tay Trái (+10), gập 1 ngón Tay Phải (-1)';
      if (op == 8) return 'Anh Bạn Lớn (+8 = +10 - 2): Bung 1 ngón Tay Trái (+10), gập 2 ngón Tay Phải (-2)';
      if (op == 7) return 'Anh Bạn Lớn (+7 = +10 - 3): Bung 1 ngón Tay Trái (+10), gập 3 ngón Tay Phải (-3)';
      if (op == 6) return 'Anh Bạn Lớn (+6 = +10 - 4): Bung 1 ngón Tay Trái (+10), gập 4 ngón Tay Phải (-4)';
      if (op == 4) return 'Anh Bạn Nhỏ (+4 = +5 - 1): Tay Phải xòe ngón cái (5), gập 1 ngón dài';
      if (op == 3) return 'Anh Bạn Nhỏ (+3 = +5 - 2): Tay Phải xòe ngón cái (5), gập 2 ngón dài';
      if (op == 2) return 'Anh Bạn Nhỏ (+2 = +5 - 3): Tay Phải xòe ngón cái (5), gập 3 ngón dài';
      if (op == 1) return 'Anh Bạn Nhỏ (+1 = +5 - 4): Tay Phải xòe ngón cái (5), gập 4 ngón dài';
      if (op == -1) return 'Anh Bạn Nhỏ (-1 = -5 + 4): Tay Phải gập ngón cái (5), bung 4 ngón dài';
      if (op == -2) return 'Anh Bạn Nhỏ (-2 = -5 + 3): Tay Phải gập ngón cái (5), bung 3 ngón dài';
      if (op == -3) return 'Anh Bạn Nhỏ (-3 = -5 + 2): Tay Phải gập ngón cái (5), bung 2 ngón dài';
      if (op == -4) return 'Anh Bạn Nhỏ (-4 = -5 + 1): Tay Phải gập ngón cái (5), bung 1 ngón dài';
      if (op == -9) return 'Anh Bạn Lớn (-9 = -10 + 1): Gập 1 ngón Tay Trái (-10), bung 1 ngón Tay Phải (+1)';
    }
    return 'Áp dụng công thức ngón tay Tay Trái và Tay Phải để tính nhanh nhé!';
  }

  Future<void> _checkAnswer(int answer, String answeredVia) async {
    final elapsed = DateTime.now().difference(_questionStartTime).inMilliseconds;
    final isCorrect = answer == _currentQuestion.expectedAnswer;
    final guidance = FingerMathFormulaHelper.generateFullGuidance(
      operands: _currentQuestion.operands,
      expectedAnswer: _currentQuestion.expectedAnswer,
    );

    final log = AttemptLog(
      questionId: _currentQuestion.id,
      userAnswer: answer,
      isCorrect: isCorrect,
      responseTimeMs: elapsed,
      answeredVia: answeredVia,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _storageService.saveAttemptLog(log);

    setState(() {
      _hasAnswered = true;
      _isAnswerCorrect = isCorrect;
      _submittedAnswer = answer;
      _guidance = guidance;
    });

    if (isCorrect) {
      final profile = await _storageService.getChildProfile();
      await _storageService.saveChildProfile(
        profile.copyWith(streakCount: profile.streakCount + 1),
      );
      setState(() {
        _mascotSpeech =
            '🎉 HOAN HÔ BÉ! BÉ QUÁ XUẤT SẮC! ⭐\nBé đã tính đúng: ${_currentQuestion.formulaExpression} = $answer!';
      });
      await _audioService.playSuccessFeedback(
        'Hoan hô bé! Bé đã làm hoàn toàn chính xác! Phép tính ${_currentQuestion.spokenExpression} bằng $answer. Bé rất thông minh!',
      );
    } else {
      setState(() {
        _mascotSpeech =
            '💡 HƯỚNG DẪN FINGER MATH CHO BÉ:\nBé ra $answer, đáp án đúng là ${_currentQuestion.expectedAnswer}.\nCùng xem các bước hướng dẫn bên dưới nhé!';
      });
      await _audioService.playEncouragementFeedback(guidance.spokenText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.level == 1
              ? 'Finger Math: Đếm Ngón Cơ Bản'
              : 'Finger Math: Anh Bạn Nhỏ & Lớn',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentYellow.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  'Câu $_questionIndex',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Mascot Bubble giao tiếp với bé
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: MascotBubbleWidget(
                speechText: _mascotSpeech,
                onMascotTap: () {
                  if (_hasAnswered) {
                    if (_isAnswerCorrect) {
                      _audioService.playSuccessFeedback();
                    } else if (_guidance != null) {
                      _audioService.speak(_guidance!.spokenText);
                    }
                  } else {
                    _audioService.speak(
                      'Bé ơi hãy tính: ${_currentQuestion.spokenExpression}. Bằng bao nhiêu bé nhỉ?',
                    );
                  }
                },
              ),
            ),

            // 2. Khung hiển thị phép tính to rõ & Trạng thái kết quả (Luôn nhìn thấy đề bài)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: _hasAnswered
                    ? (_isAnswerCorrect
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0))
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _hasAnswered
                      ? (_isAnswerCorrect ? AppColors.success : AppColors.secondary)
                      : AppColors.primary.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _hasAnswered && _isAnswerCorrect
                            ? '${_currentQuestion.formulaExpression} = $_submittedAnswer'
                            : '${_currentQuestion.formulaExpression} = ?',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: _hasAnswered && _isAnswerCorrect
                              ? AppColors.success
                              : AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded,
                            color: AppColors.primary, size: 28),
                        tooltip: 'Nghe đọc lại phép tính',
                        onPressed: () {
                          _audioService.speak(
                            'Phép tính: ${_currentQuestion.spokenExpression}',
                          );
                        },
                      ),
                    ],
                  ),
                  if (_hasAnswered) ...[
                    const SizedBox(height: 4),
                    Text(
                      _isAnswerCorrect
                          ? '✅ Bé trả lời: $_submittedAnswer (Chính xác!)'
                          : '❌ Bé trả lời: $_submittedAnswer   |   Đáp án đúng: ${_currentQuestion.expectedAnswer} ⭐',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _isAnswerCorrect
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3. Khu vực giữa: Bàn tay tương tác HOẶC Thẻ Khen ngợi / Hướng dẫn
            Expanded(
              child: _hasAnswered
                  ? _buildAnswerReviewView()
                  : Center(
                      child: FingerMathBoardWidget(
                        controller: _fingerController,
                        height: 220,
                        showLiveValue: true,
                      ),
                    ),
            ),

            // 4. Thanh nút điều khiển dưới cùng
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  /// Khung hiển thị xem lại kết quả: Khen ngợi khi đúng, Hướng dẫn từng bước khi sai
  Widget _buildAnswerReviewView() {
    if (_isAnswerCorrect) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🌟 HOAN HÔ BÉ! XUẤT SẮC! 🌟',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bé đã tính rất chuẩn xác: ${_currentQuestion.formulaExpression} = $_submittedAnswer',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: AppColors.accentYellow, size: 28),
                  SizedBox(width: 8),
                  Text(
                    '+1 Ngôi sao thông thái & Giữ chuỗi Streak!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _audioService.playSuccessFeedback(),
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Nghe lại lời khen 🔊'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Khi sai: Thực sự hiện hướng dẫn chi tiết từng bước cho bé
    final guidance = _guidance;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentOrange.withOpacity(0.6), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: AppColors.accentOrange, size: 26),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'HƯỚNG DẪN FINGER MATH TỪNG BƯỚC:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentOrange,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.accentOrange),
                tooltip: 'Nghe đọc hướng dẫn',
                onPressed: () {
                  if (guidance != null) {
                    _audioService.speak(guidance.spokenText);
                  }
                },
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (guidance != null)
                  for (final step in guidance.steps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accentOrange.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          step,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh nút điều khiển:
  /// - Khi chưa làm: Gửi ngón tay / Bấm nói Micro
  /// - Khi đã làm xong: Xem lại câu hỏi thỏa thích, có nút Thử lại và nút CÂU TIẾP THEO
  Widget _buildBottomControls() {
    if (_hasAnswered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (!_isAnswerCorrect)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasAnswered = false;
                    _fingerController.reset();
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: const Text('BÉ THỬ LẠI 🔄', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _questionIndex++);
                _loadNextQuestion();
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 24),
              label: const Text('CÂU TIẾP THEO ➡️', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAnswerCorrect ? AppColors.success : AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              _checkAnswer(
                _fingerController.totalValue,
                'finger_touch',
              );
            },
            icon: const Icon(Icons.front_hand, size: 26),
            label: const Text('GỬI NGÓN TAY ✋'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          VoiceAnswerMicButton(
            onAnswerDetected: (answer, raw) {
              _checkAnswer(answer, 'voice');
            },
          ),
        ],
      ),
    );
  }
}
