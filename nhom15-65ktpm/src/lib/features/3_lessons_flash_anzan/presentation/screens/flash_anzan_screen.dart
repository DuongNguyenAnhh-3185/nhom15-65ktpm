import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/attempt_log.dart';
import '../../../../shared/entities/soroban_question.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/domain/entities/finger_hand_state.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/finger_math_controller.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/finger_math_board_widget.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/engine/adaptive_tutor_engine.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/presentation/widgets/voice_answer_mic_button.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/domain/question_generator.dart';

class FlashAnzanScreen extends StatefulWidget {
  final int initialSpeedMs;

  const FlashAnzanScreen({super.key, this.initialSpeedMs = 1200});

  @override
  State<FlashAnzanScreen> createState() => _FlashAnzanScreenState();
}

class _FlashAnzanScreenState extends State<FlashAnzanScreen> {
  final AudioService _audioService = sl<AudioService>();
  final StorageService _storageService = sl<StorageService>();
  late FingerMathController _fingerController;

  late SorobanQuestion _currentQuestion;
  int _flashSpeedMs = 1200;

  bool _isFlashing = false;
  String _displayNumber = 'SẴN SÀNG?';
  Color _displayColor = AppColors.secondary;
  bool _waitingForAnswer = false;
  String _feedbackMessage = 'Bé nhìn kỹ các số xuất hiện nhé!';

  @override
  void initState() {
    super.initState();
    _flashSpeedMs = widget.initialSpeedMs;
    _fingerController = FingerMathController(showLeftHand: true);
    _nextQuestion();
  }

  @override
  void dispose() {
    _fingerController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion = QuestionGenerator.generate(3, flashSpeedMs: _flashSpeedMs);
      _fingerController.reset();
      _waitingForAnswer = false;
      _displayNumber = 'SẴN SÀNG?';
      _displayColor = AppColors.secondary;
      _feedbackMessage = 'Nhấn nút để bắt đầu tính nhẩm Finger Math!';
    });
  }

  Future<void> _startFlashSequence() async {
    setState(() {
      _isFlashing = true;
      _waitingForAnswer = false;
      _displayNumber = '3';
      _displayColor = AppColors.accentOrange;
    });
    await _audioService.speak('Ba');
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _displayNumber = '2');
    await _audioService.speak('Hai');
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _displayNumber = '1');
    await _audioService.speak('Một');
    await Future.delayed(const Duration(milliseconds: 600));

    // Bắt đầu chớp số
    for (int i = 0; i < _currentQuestion.operands.length; i++) {
      if (!mounted) return;
      final val = _currentQuestion.operands[i];
      final valText = val >= 0 ? '+$val' : '$val';

      setState(() {
        _displayNumber = valText;
        _displayColor = val >= 0 ? AppColors.primary : AppColors.secondary;
      });

      _audioService.speak(val >= 0 ? 'Cộng $val' : 'Trừ ${val.abs()}');
      await Future.delayed(Duration(milliseconds: _flashSpeedMs));

      // Khoảng nghỉ trắng mắt giữa 2 số để kích thích não bộ hình dung
      if (!mounted) return;
      setState(() {
        _displayNumber = '';
      });
      await Future.delayed(const Duration(milliseconds: 180));
    }

    if (!mounted) return;
    setState(() {
      _isFlashing = false;
      _waitingForAnswer = true;
      _displayNumber = '?';
      _displayColor = AppColors.accentYellow;
      _feedbackMessage = 'Bé bung ngón tay Finger Math hoặc đọc to đáp án nhé!';
    });
    await _audioService.speak('Bằng bao nhiêu bé ơi?');
  }

  Future<void> _checkAnswer(int answer, String answeredVia) async {
    if (!_waitingForAnswer) return;

    final isCorrect = answer == _currentQuestion.expectedAnswer;
    final guidance = FingerMathFormulaHelper.generateFullGuidance(
      operands: _currentQuestion.operands,
      expectedAnswer: _currentQuestion.expectedAnswer,
    );

    final log = AttemptLog(
      questionId: _currentQuestion.id,
      userAnswer: answer,
      isCorrect: isCorrect,
      responseTimeMs: 2000,
      answeredVia: answeredVia,
      timestamp: DateTime.now().toIso8601String(),
    );
    await _storageService.saveAttemptLog(log);

    // AI Thích ứng: Đánh giá và tự động căn chỉnh tốc độ
    final recentLogs = await _storageService.getRecentLogs();
    final decision = AdaptiveTutorEngine.evaluatePerformance(
      recentAttempts: recentLogs,
      currentFlashSpeedMs: _flashSpeedMs,
    );

    setState(() {
      _flashSpeedMs = decision.recommendedSpeedMs;
      _waitingForAnswer = false;
    });

    if (isCorrect) {
      await _audioService.playSuccessFeedback(
        'Hoan hô bé! Bé đã tính nhẩm siêu tốc rất chính xác! Phép tính ${_currentQuestion.spokenExpression} bằng $answer!',
      );
      _showResultDialog(
        title: 'XUẤT SẮC! 🎉',
        formula: '${_currentQuestion.formulaExpression} = $answer ✅',
        message: 'Hoan hô bé! Bé đã tính nhẩm rất chuẩn xác!\n${decision.message}',
        guidance: null,
        isSuccess: true,
      );
    } else {
      await _audioService.playEncouragementFeedback(guidance.spokenText);
      _showResultDialog(
        title: 'BÉ CÙNG XEM HƯỚNG DẪN 💡',
        formula: '${_currentQuestion.formulaExpression} = ?',
        message: 'Bé trả lời: $answer ❌  |  Đáp án đúng: ${_currentQuestion.expectedAnswer} ⭐\n${decision.message}',
        guidance: guidance,
        isSuccess: false,
      );
    }
  }

  void _showResultDialog({
    required String title,
    required String formula,
    required String message,
    required FingerMathGuidance? guidance,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isSuccess ? const Color(0xFFF0FFF4) : const Color(0xFFFFF8E1),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isSuccess ? AppColors.success : AppColors.accentOrange,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hiển thị lại câu hỏi rõ ràng
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSuccess ? AppColors.success : AppColors.accentOrange,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formula,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isSuccess ? AppColors.success : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
                        tooltip: 'Nghe lại phép tính',
                        onPressed: () {
                          _audioService.speak('Phép tính vừa rồi: ${_currentQuestion.spokenExpression}');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (guidance != null) ...[
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '💡 Các bước thực hiện Finger Math:',
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accentOrange, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final step in guidance.steps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          step,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () => _audioService.speak(guidance.spokenText),
                    icon: const Icon(Icons.volume_up_rounded, size: 20),
                    label: const Text('Nghe lại hướng dẫn 🔊'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _nextQuestion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSuccess ? AppColors.success : AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Câu tiếp theo ➡️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚡ Flash Anzan - Finger Math Siêu Tốc',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentYellow.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.speed, size: 18, color: AppColors.accentOrange),
                const SizedBox(width: 4),
                Text(
                  '${(_flashSpeedMs / 1000).toStringAsFixed(1)}s',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Khung hiển thị số chớp nhoáng
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: _displayColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _displayColor.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _displayNumber,
                    style: const TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Lời hướng dẫn hoặc nút bắt đầu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _feedbackMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),

            if (!_isFlashing && !_waitingForAnswer)
              Padding(
                padding: const EdgeInsets.all(10),
                child: ElevatedButton.icon(
                  onPressed: _startFlashSequence,
                  icon: const Icon(Icons.play_arrow, size: 30),
                  label: const Text('BẮT ĐẦU CHỚP SỐ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                ),
              ),

            // Bàn tay Finger Math để bé bung ngón tay
            Expanded(
              flex: 5,
              child: FingerMathBoardWidget(
                controller: _fingerController,
                height: 200,
                showLiveValue: true,
              ),
            ),

            // Nút trả lời bằng ngón tay & Micro AI giọng nói
            if (_waitingForAnswer)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _checkAnswer(_fingerController.totalValue, 'finger_touch');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      ),
                      child: const Text('GỬI NGÓN TAY ✋', style: TextStyle(fontSize: 15)),
                    ),
                    VoiceAnswerMicButton(
                      onAnswerDetected: (answer, raw) {
                        _checkAnswer(answer, 'voice');
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
