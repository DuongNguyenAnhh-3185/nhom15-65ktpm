import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/features/2_gamification_parent/domain/streak_calculator.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/engine/adaptive_learning_engine.dart';
import 'package:soroban_kids_app/shared/entities/attempt_log.dart';

void main() {
  group('Adaptive Tutor Engine Legacy Tests (Module 4 - Cẩm Ly)', () {
    test('TC_AI_01: Tăng tốc độ và độ khó khi bé làm đúng 100% và rất nhanh', () {
      final fastCorrectLogs = List.generate(
        5,
        (i) => AttemptLog(
          questionId: 'q_$i',
          userAnswer: 5,
          isCorrect: true,
          responseTimeMs: 1500, // 1.5s
          answeredVia: 'voice',
          timestamp: DateTime.now().toIso8601String(),
        ),
      );

      final decision = AdaptiveTutorEngine.evaluatePerformance(
        recentAttempts: fastCorrectLogs,
        currentFlashSpeedMs: 1200,
      );

      expect(decision.action, AdaptiveAction.speedUp);
      expect(decision.recommendedSpeedMs, 1000); // 1200 - 200 = 1000ms
    });

    test('TC_AI_02: Chuyển sang hướng dẫn thị phạm khi bé làm sai nhiều', () {
      final strugglingLogs = [
        AttemptLog(
          questionId: 'q_1',
          userAnswer: 2,
          isCorrect: false,
          responseTimeMs: 7000,
          answeredVia: 'abacus_touch',
          timestamp: DateTime.now().toIso8601String(),
        ),
        AttemptLog(
          questionId: 'q_2',
          userAnswer: 3,
          isCorrect: false,
          responseTimeMs: 6500,
          answeredVia: 'abacus_touch',
          timestamp: DateTime.now().toIso8601String(),
        ),
        AttemptLog(
          questionId: 'q_3',
          userAnswer: 5,
          isCorrect: true,
          responseTimeMs: 4000,
          answeredVia: 'voice',
          timestamp: DateTime.now().toIso8601String(),
        ),
      ];

      final decision = AdaptiveTutorEngine.evaluatePerformance(
        recentAttempts: strugglingLogs,
        currentFlashSpeedMs: 1200,
      );

      expect(decision.action, AdaptiveAction.guideHighlight);
      expect(decision.recommendedSpeedMs, 1400); // 1200 + 200 = 1400ms
    });

    test('TC_AI_03: Duy trì độ khó khi bé làm bài ổn định', () {
      final steadyLogs = List.generate(
        5,
        (i) => AttemptLog(
          questionId: 'q_$i',
          userAnswer: 5,
          isCorrect: i != 0, // 4/5 đúng = 80%
          responseTimeMs: 3500, // 3.5s
          answeredVia: 'abacus_touch',
          timestamp: DateTime.now().toIso8601String(),
        ),
      );

      final decision = AdaptiveTutorEngine.evaluatePerformance(
        recentAttempts: steadyLogs,
        currentFlashSpeedMs: 1200,
      );

      expect(decision.action, AdaptiveAction.stayCurrent);
      expect(decision.recommendedSpeedMs, 1200);
    });
  });

  group('Adaptive Learning Engine Stateful Sliding Window Tests (Mục 7.8)', () {
    test('TC_ENG_01: Cửa sổ trượt chưa đủ 5 bài -> Duy trì (maintain), không thay đổi cấp độ', () {
      final engine = AdaptiveLearningEngine(
        initialState: const AdaptiveState(
          currentDifficulty: 2,
          flashDurationMs: 1000,
          isFingerGuideEnabled: false,
        ),
      );

      // Thêm 4 bài làm đúng nhanh liên tiếp
      for (int i = 0; i < 4; i++) {
        final decision = engine.processAttempt(
          AttemptResult(
            isCorrect: true,
            responseTimeMs: 1200,
            mode: PracticeMode.fingerMath,
          ),
        );

        expect(decision.adaptationAction, AdaptationAction.maintain);
        expect(decision.isMaintain, isTrue);
        expect(engine.state.currentDifficulty, 2);
        expect(engine.window.length, i + 1);
      }
    });

    test('TC_ENG_02: Đủ 5 bài Finger Math đúng >= 80% & thời gian < 2500ms -> Thăng cấp (levelUp), tăng level + 1, tắt guide', () {
      final engine = AdaptiveLearningEngine(
        initialState: const AdaptiveState(
          currentDifficulty: 1,
          isFingerGuideEnabled: true, // đang bật hướng dẫn
        ),
      );

      // Gửi 4 bài đầu đúng nhanh
      for (int i = 0; i < 4; i++) {
        engine.processAttempt(
          AttemptResult(
            isCorrect: true,
            responseTimeMs: 1500,
            mode: PracticeMode.fingerMath,
          ),
        );
      }

      // Bài thứ 5: đúng nhanh -> đủ 5/5 bài đúng (100%), time 1500ms
      final decision = engine.processAttempt(
        AttemptResult(
          isCorrect: true,
          responseTimeMs: 1500,
          mode: PracticeMode.fingerMath,
        ),
      );

      expect(decision.adaptationAction, AdaptationAction.levelUp);
      expect(decision.isLevelUp, isTrue);
      expect(decision.recommendedLevel, 2);
      expect(decision.fingerGuideEnabled, isFalse);
      expect(engine.state.currentDifficulty, 2);
      expect(engine.state.isFingerGuideEnabled, isFalse);
      expect(decision.message.contains('Cấp độ 2'), isTrue);
    });

    test('TC_ENG_03: Đủ 5 bài Flash Anzan đúng >= 80% & thời gian < 2500ms -> Giảm thời gian chớp (-200ms)', () {
      final engine = AdaptiveLearningEngine(
        initialState: const AdaptiveState(
          flashDurationMs: 1200,
        ),
      );

      // 4 bài đúng + 1 bài sai (4/5 = 80%), avgTime = 1600ms < 2500ms
      for (int i = 0; i < 4; i++) {
        engine.processAttempt(
          AttemptResult(
            isCorrect: true,
            responseTimeMs: 1500,
            mode: PracticeMode.flashAnzan,
          ),
        );
      }

      final decision = engine.processAttempt(
        AttemptResult(
          isCorrect: false,
          responseTimeMs: 2000,
          mode: PracticeMode.flashAnzan,
        ),
      );

      expect(decision.adaptationAction, AdaptationAction.levelUp);
      expect(decision.recommendedSpeedMs, 1000); // 1200 - 200 = 1000ms
      expect(engine.state.flashDurationMs, 1000);
      expect(decision.message.contains('1000ms'), isTrue);
    });

    test('TC_ENG_04: Giới hạn trần khi đạt maxLevel (4) và sàn minSpeedMs (300ms)', () {
      final engine = AdaptiveLearningEngine(
        initialState: const AdaptiveState(
          currentDifficulty: 4, // Max level
          flashDurationMs: 300, // Min speed
        ),
      );

      for (int i = 0; i < 5; i++) {
        engine.processAttempt(
          AttemptResult(
            isCorrect: true,
            responseTimeMs: 1000,
            mode: PracticeMode.fingerMath,
          ),
        );
      }

      expect(engine.state.currentDifficulty, 4); // Không vượt quá 4
      expect(engine.state.flashDurationMs, 300); // Không nhỏ hơn 300ms
    });

    test('TC_ENG_05: Đủ 5 bài accuracy < 50% -> Hạ cấp (levelDown), level - 1 và bật hướng dẫn ngón tay (fingerGuide = true)', () {
      final engine = AdaptiveLearningEngine(
        initialState: const AdaptiveState(
          currentDifficulty: 3,
          isFingerGuideEnabled: false,
        ),
      );

      // 1 đúng, 4 sai -> 1/5 = 20% < 50%
      engine.processAttempt(
        AttemptResult(
          isCorrect: true,
          responseTimeMs: 3000,
          mode: PracticeMode.fingerMath,
        ),
      );
      for (int i = 0; i < 4; i++) {
        engine.processAttempt(
          AttemptResult(
            isCorrect: false,
            responseTimeMs: 4000,
            mode: PracticeMode.fingerMath,
          ),
        );
      }

      expect(engine.state.lastAction, AdaptationAction.levelDown);
      expect(engine.state.currentDifficulty, 2); // 3 -> 2
      expect(engine.state.isFingerGuideEnabled, isTrue); // Bật hướng dẫn ngón tay
    });

    test('TC_ENG_06: Đủ 5 bài avgResponseTimeMs > 6000ms -> Hạ cấp & hỗ trợ (levelDown), bật fingerGuide', () {
      final engine = AdaptiveLearningEngine(
        initialState: const AdaptiveState(
          currentDifficulty: 2,
          isFingerGuideEnabled: false,
        ),
      );

      // Cả 5 bài đều đúng (100%) nhưng làm rất chậm (> 6000ms, ví dụ 7000ms)
      for (int i = 0; i < 5; i++) {
        engine.processAttempt(
          AttemptResult(
            isCorrect: true,
            responseTimeMs: 7000,
            mode: PracticeMode.fingerMath,
          ),
        );
      }

      expect(engine.state.lastAction, AdaptationAction.levelDown);
      expect(engine.state.currentDifficulty, 1);
      expect(engine.state.isFingerGuideEnabled, isTrue);
    });

    test('TC_ENG_07: Giới hạn sàn khi đã ở minLevel (1) -> Không giảm xuống dưới 1', () {
      final engine = AdaptiveLearningEngine(
        initialState: const AdaptiveState(
          currentDifficulty: 1, // Min level
          isFingerGuideEnabled: false,
        ),
      );

      for (int i = 0; i < 5; i++) {
        engine.processAttempt(
          AttemptResult(
            isCorrect: false,
            responseTimeMs: 8000,
            mode: PracticeMode.fingerMath,
          ),
        );
      }

      expect(engine.state.currentDifficulty, 1); // Vẫn ở level 1
      expect(engine.state.isFingerGuideEnabled, isTrue); // Nhưng bật hướng dẫn
    });

    test('TC_ENG_08: Flash Anzan khi gặp khó -> Tăng thời gian chớp số +200ms (tối đa maxSpeedMs = 2500ms)', () {
      final engine = AdaptiveLearningEngine(
        initialState: const AdaptiveState(
          flashDurationMs: 1400,
        ),
      );

      for (int i = 0; i < 5; i++) {
        engine.processAttempt(
          AttemptResult(
            isCorrect: false,
            responseTimeMs: 7000,
            mode: PracticeMode.flashAnzan,
          ),
        );
      }

      expect(engine.state.lastAction, AdaptationAction.levelDown);
      expect(engine.state.flashDurationMs, 1600); // 1400 + 200 = 1600ms
    });

    test('TC_ENG_09: Cơ chế chống dao động (Hysteresis / Cooldown) sau khi đổi cấp', () {
      final engine = AdaptiveLearningEngine(
        resetWindowOnAdaptation: true,
        initialState: const AdaptiveState(
          currentDifficulty: 1,
        ),
      );

      // Đợt 1: 5 bài đúng nhanh -> Nâng lên level 2
      for (int i = 0; i < 5; i++) {
        engine.processAttempt(
          AttemptResult(
            isCorrect: true,
            responseTimeMs: 1500,
            mode: PracticeMode.fingerMath,
          ),
        );
      }
      expect(engine.state.currentDifficulty, 2);
      expect(engine.window.isEmpty, isTrue); // Cửa sổ trượt được reset để chống dao động

      // 4 bài tiếp theo ở cấp mới dù làm chậm hay sai cũng KHÔNG bị tụt cấp ngay lập tức
      for (int i = 0; i < 4; i++) {
        final decision = engine.processAttempt(
          AttemptResult(
            isCorrect: false,
            responseTimeMs: 8000,
            mode: PracticeMode.fingerMath,
          ),
        );
        expect(decision.adaptationAction, AdaptationAction.maintain);
        expect(engine.state.currentDifficulty, 2); // Vẫn giữ level 2 để trẻ làm quen
      }
    });

    test('TC_ENG_10: Duy trì (maintain) khi kết quả trung bình ổn định (accuracy 60%, time 3500ms)', () {
      final engine = AdaptiveLearningEngine(
        initialState: const AdaptiveState(
          currentDifficulty: 2,
          flashDurationMs: 1200,
        ),
      );

      // 3 đúng, 2 sai (3/5 = 60%), time = 3500ms (giữa 2500ms và 6000ms)
      for (int i = 0; i < 3; i++) {
        engine.processAttempt(
          AttemptResult(
            isCorrect: true,
            responseTimeMs: 3500,
            mode: PracticeMode.fingerMath,
          ),
        );
      }
      for (int i = 0; i < 2; i++) {
        engine.processAttempt(
          AttemptResult(
            isCorrect: false,
            responseTimeMs: 3500,
            mode: PracticeMode.fingerMath,
          ),
        );
      }

      expect(engine.state.lastAction, AdaptationAction.maintain);
      expect(engine.state.currentDifficulty, 2);
      expect(engine.state.flashDurationMs, 1200);
    });
  });

  group('Streak Calculator Tests (Module 2 - Duy Thái)', () {
    test('Duy trì streak khi học tiếp tục vào ngày kế tiếp', () {
      final yesterday = DateTime(2026, 11, 13);
      final today = DateTime(2026, 11, 14);

      final streak = StreakCalculator.updateStreak(
        currentStreak: 3,
        lastActiveDate: yesterday,
        today: today,
      );

      expect(streak, 4);
    });

    test('Giữ nguyên streak khi bé học nhiều lần trong cùng 1 ngày', () {
      final todayMorning = DateTime(2026, 11, 14, 8, 0);
      final todayEvening = DateTime(2026, 11, 14, 19, 0);

      final streak = StreakCalculator.updateStreak(
        currentStreak: 5,
        lastActiveDate: todayMorning,
        today: todayEvening,
      );

      expect(streak, 5);
    });

    test('Reset streak về 1 khi bị gián đoạn nhiều hơn 1 ngày', () {
      final threeDaysAgo = DateTime(2026, 11, 10);
      final today = DateTime(2026, 11, 14);

      final streak = StreakCalculator.updateStreak(
        currentStreak: 10,
        lastActiveDate: threeDaysAgo,
        today: today,
      );

      expect(streak, 1);
    });
  });
}
