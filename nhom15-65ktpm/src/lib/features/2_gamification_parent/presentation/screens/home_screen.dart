import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/child_profile.dart';
import '../../../../shared/widgets/kid_button.dart';
import '../../../../shared/widgets/kid_card.dart';
import '../../../../shared/widgets/kid_decoration.dart';
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 640;
            final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 20.0;
            final mascotWidth =
                constraints.maxWidth < 352 ? constraints.maxWidth - 32 : 320.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const KidDecoration(type: KidDecorationType.star),
                          KidButton(
                            onPressed: _openParentDashboard,
                            icon: Icons.settings_rounded,
                            semanticLabel: 'Khu vực phụ huynh',
                            backgroundColor: AppColors.cardBg,
                            width: 52,
                            height: 52,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: SizedBox(
                          width: mascotWidth,
                          child: MascotBubbleWidget(
                            speechText:
                                'Chào bé! Hôm nay mình cùng chơi toán nhé!',
                            onMascotTap: () {
                              _audioService.speak(
                                'Chào bé! Hôm nay mình cùng chơi toán nhé!',
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _profile == null
                            ? 'Chào bé!'
                            : 'Chào bé ${_profile!.name}!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hôm nay mình cùng chơi toán nhé!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      _buildStreakCard(context),
                      if (_showReminderBanner) ...[
                        const SizedBox(height: 12),
                        _buildReminderBanner(),
                      ],
                      const SizedBox(height: 24),
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
                            label: 'Toán cơ bản',
                            semanticLabel: 'Luyện toán cơ bản cấp độ 1',
                            icon: Icons.calculate_rounded,
                            color: AppColors.primary,
                            onTap: () => _openLesson(1),
                          ),
                          _buildFeatureCard(
                            label: 'Công thức',
                            semanticLabel:
                                'Luyện công thức Anh bạn nhỏ và Anh bạn lớn',
                            icon: Icons.swap_horiz_rounded,
                            color: AppColors.accentPurple,
                            onTap: () => _openLesson(2),
                          ),
                          _buildFeatureCard(
                            label: 'Chớp số',
                            semanticLabel: 'Luyện tính nhẩm Flash Anzan',
                            icon: Icons.bolt_rounded,
                            color: AppColors.success,
                            onTap: _openFlashAnzan,
                          ),
                        ],
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

  Widget _buildStreakCard(BuildContext context) {
    final streakCount = _profile?.streakCount;
    return KidCard(
      color: Theme.of(context).colorScheme.secondaryContainer,
      semanticLabel: streakCount == null
          ? 'Đang tải chuỗi ngày học'
          : 'Chuỗi ngày học: $streakCount ngày',
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.accentYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuỗi ngày học',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  streakCount == null ? 'Đang tải…' : '$streakCount ngày',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const KidDecoration(
            type: KidDecorationType.star,
            size: 32,
          ),
        ],
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

  Widget _buildFeatureCard({
    required String label,
    required String semanticLabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return KidCard(
      onTap: () {
        HapticFeedback.selectionClick();
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

  void _openLesson(int level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPlayScreen(level: level),
      ),
    ).then((_) => _loadProfile());
  }

  void _openFlashAnzan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FlashAnzanScreen(),
      ),
    ).then((_) => _loadProfile());
  }
}
