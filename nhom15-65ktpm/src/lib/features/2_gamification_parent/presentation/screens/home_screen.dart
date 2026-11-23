import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/child_profile.dart';
import '../../../../shared/widgets/mascot_bubble.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/controllers/finger_math_controller.dart';
import 'package:soroban_kids_app/features/1_abacus_engine/presentation/widgets/finger_math_board_widget.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/presentation/screens/flash_anzan_screen.dart';
import 'package:soroban_kids_app/features/3_lessons_flash_anzan/presentation/screens/lesson_play_screen.dart';
import '../widgets/parental_gate_dialog.dart';
import 'parent_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = sl<AudioService>();
  final StorageService _storageService = sl<StorageService>();
  ChildProfile? _profile;
  bool _showReminderBanner = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _storageService.getChildProfile();
    final reminderSettings = await ReminderService.getSettings();
    final showReminder = ReminderService.shouldShowInAppReminder(
      settings: reminderSettings,
      profile: profile,
    );

    if (mounted) {
      setState(() {
        _profile = profile;
        _showReminderBanner = showReminder;
      });
    }
  }

  void _openFreePlayModal() {
    final fingerController = FingerMathController(showLeftHand: true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              const Text('✋', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Expanded(
                child: FingerMathBoardWidget(
                  controller: fingerController,
                  height: 230,
                  showLiveValue: true,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _audioService.speak(fingerController.speechDescription);
                },
                icon: const Icon(Icons.volume_up_rounded, size: 28),
                label: const Text(''),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.textDark,
                  minimumSize: const Size(
                    AppDimensions.minTouchSize,
                    AppDimensions.buttonHeight,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => _loadProfile());
  }

  /// Biểu cảm Panda dựa trên chuỗi Streak hiện tại.
  PandaExpression get _pandaExpression {
    final streak = _profile?.streakCount ?? 0;
    if (streak >= 7) return PandaExpression.celebrating;
    if (streak >= 3) return PandaExpression.encouraging;
    return PandaExpression.happy;
  }

  /// Lời nhắn ngắn của Panda; tên bé và Streak được hiển thị bên dưới.
  String get _greetingText {
    final streak = _profile?.streakCount ?? 0;
    if (streak >= 7) {
      return 'Cùng giữ phong độ tuyệt vời nhé! 🎉';
    } else if (streak >= 3) {
      return 'Mình cùng giữ chuỗi ngày học nhé! 🔥';
    }
    return 'Hôm nay mình cùng chơi toán nhé!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh tiêu đề trên cùng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accentOrange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text(
                          '${_profile?.streakCount ?? 3} Ngày',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentOrange,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Chọn hoạt động',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: isTablet ? 4 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isTablet ? 1.15 : 0.92,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildFeatureCard(
                            label: 'Tập đếm',
                            semanticLabel: 'Tập đếm ngón tay tự do',
                            icon: Icons.back_hand_rounded,
                            color: AppColors.secondary,
                            onTap: _openFreePlayModal,
                          ),
                          _buildFeatureCard(
                            label: 'Luyện tập',
                            semanticLabel:
                                'Chọn bài luyện toán cơ bản hoặc công thức',
                            icon: Icons.calculate_rounded,
                            color: AppColors.primary,
                            onTap: _openPracticeOptions,
                          ),
                          _buildFeatureCard(
                            label: 'Flash Anzan',
                            semanticLabel: 'Luyện tính nhẩm Flash Anzan',
                            icon: Icons.bolt_rounded,
                            color: AppColors.accentPurple,
                            onTap: _openFlashAnzan,
                          ),
                          _buildFeatureCard(
                            label: 'Phụ huynh',
                            semanticLabel: 'Mở cổng phụ huynh',
                            icon: Icons.family_restroom_rounded,
                            color: AppColors.success,
                            onTap: _openParentDashboard,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: AppColors.textLight,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
              if (_showReminderBanner) ...[
                const SizedBox(height: 12),
                _buildReminderBanner(),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 16),

              // Linh vật hoạt hình Mascot
              MascotBubbleWidget(
                speechText:
                    'Hôm nay bé muốn đếm ngón tay Finger Math hay thi đấu tính nhẩm nhanh nè?',
                onMascotTap: () {
                  _audioService.speak(
                    'Hôm nay bé muốn đếm ngón tay Finger Math hay thi đấu tính nhẩm nhanh nè?',
                  );
                },
              ),
              const SizedBox(height: 24),

              // Danh sách 3 Cấp độ học tập dạng thẻ to rực rỡ
              _buildLevelCard(
                title: 'CẤP ĐỘ 1: FINGER MATH CƠ BẢN',
                subtitle:
                    'Đếm ngón 0-9: Tay Phải hàng đơn vị, Tay Trái hàng chục',
                color: AppColors.secondary,
                emoji: '✌️',
                badgeText: 'Cơ Bản',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LessonPlayScreen(level: 1),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),
              const SizedBox(height: 16),

              _buildLevelCard(
                title: 'CẤP ĐỘ 2: ANH BẠN NHỎ & ANH BẠN LỚN',
                subtitle:
                    'Công thức xòe/gập ngón tay: +4 = +5 - 1, +9 = +10 - 1',
                color: AppColors.primary,
                emoji: '👍',
                badgeText: 'Công Thức',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LessonPlayScreen(level: 2),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),
              const SizedBox(height: 16),

              _buildLevelCard(
                title: 'CẤP ĐỘ 3: FLASH ANZAN FINGER MATH',
                subtitle: 'Tính nhẩm nhanh siêu tốc bằng 2 bàn tay (0 - 99)',
                color: AppColors.accentPurple,
                emoji: '⚡',
                badgeText: 'Siêu Tốc',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FlashAnzanScreen(),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),
              const SizedBox(height: 20),

              // Nút Bàn tay Finger Math tự do
              OutlinedButton.icon(
                onPressed: _openFreePlayModal,
                icon: const Icon(Icons.front_hand, size: 26),
                label: const Text('BÀN TAY FINGER MATH (CHƠI TỰ DO) ✋'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textDark,
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.accentOrange.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Text('⏰', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đã 19:00 rồi! Giờ luyện tập Finger Math!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.accentOrange,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Cùng luyện tập để giữ ngọn lửa chuỗi Streak nhé bé ơi! 🔥',
                  style: TextStyle(fontSize: 12, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LessonPlayScreen(level: 1),
                      ),
                    ).then((_) => _loadProfile());
                  },
                  child: const Text(
                    '👉 Bắt đầu ngay!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
            onPressed: () => setState(() => _showReminderBanner = false),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required String title,
    required String subtitle,
    required Color color,
    required String emoji,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return KidCard(
      onTap: () {
        onTap();
      },
      semanticLabel: semanticLabel,
      color: AppColors.cardBg,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
          ),
        ],
      ),
    );
  }

  void _openParentDashboard() {
    ParentalGateDialog.show(
      context,
      onPass: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ParentDashboardScreen(),
          ),
        ).then((_) => _loadProfile());
      },
    );
  }

  void _openPracticeOptions() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
