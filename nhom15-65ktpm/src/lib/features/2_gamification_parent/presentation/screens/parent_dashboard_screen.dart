import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/reminder_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/services/parent_dashboard_statistics_service.dart';
import '../../../../injection_container.dart';
import '../../../../shared/entities/attempt_log.dart';
import '../../../../shared/entities/badge_item.dart';
import '../../../../shared/entities/child_profile.dart';
import '../../../../shared/widgets/kid_badge_card.dart';
import '../widgets/parental_gate_dialog.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen._();

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class ParentDashboardRoute {
  const ParentDashboardRoute._();

  static Future<void> open(BuildContext context) async {
    final isAuthenticated = await ParentalGateDialog.authenticate(context);
    if (!isAuthenticated || !context.mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const ParentDashboardScreen._(),
      ),
    );
  }
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final StorageService _storageService = sl<StorageService>();
  ChildProfile? _profile;
  List<AttemptLog> _allLogs = [];
  ReminderSettings _reminderSettings = const ReminderSettings();
  String _logFilter = 'all'; // 'all', 'correct', 'incorrect'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _storageService.getChildProfile();
    final logs = await _storageService.getRecentLogs();
    final reminder = await ReminderService.getSettings();

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _allLogs = logs;
      _reminderSettings = reminder;
      _isLoading = false;
    });
  }

  Future<void> _toggleReminder(bool enabled) async {
    await ReminderService.saveSettings(
      enabled: enabled,
      hour: _reminderSettings.hour,
      minute: _reminderSettings.minute,
    );
    setState(() {
      _reminderSettings = ReminderSettings(
        enabled: enabled,
        hour: _reminderSettings.hour,
        minute: _reminderSettings.minute,
      );
    });
  }

  List<AttemptLog> get _filteredLogs {
    if (_logFilter == 'correct') {
      return _allLogs.where((l) => l.isCorrect).toList();
    }
    if (_logFilter == 'incorrect') {
      return _allLogs.where((l) => !l.isCorrect).toList();
    }
    return _allLogs;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final statistics = ParentDashboardStatisticsService.calculate(_allLogs);
    final totalAttempts = statistics.totalAttempts;
    final correctAttempts = statistics.correctAttempts;
    final accuracyPercent = statistics.accuracyPercent;
    final avgTimeMs = statistics.averageResponseTimeMs;
    final avgTimeSeconds =
        avgTimeMs == null ? '—' : '${(avgTimeMs / 1000).toStringAsFixed(1)}s';
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 400 ? 12.0 : 24.0;
    final metricColumns = width >= 1000
        ? 4
        : width >= 600
            ? 2
            : 1;
    final badgeColumns = width >= 1000
        ? 4
        : width >= 600
            ? 3
            : 2;

    return Theme(
      data: AppTheme.parentTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bảng điều khiển phụ huynh'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Tổng quan tiến độ học tập'),
                    const SizedBox(height: 12),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: metricColumns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: metricColumns == 1
                            ? 1.9
                            : metricColumns == 4
                                ? 1.8
                                : 2.1,
                      ),
                      children: [
                        _buildMetricCard(
                          title: 'Câu hỏi đã hoàn thành',
                          value: '$totalAttempts',
                          subtitle: 'Trong 7 ngày qua, tối đa 50 lượt lưu',
                          icon: Icons.assignment_turned_in_outlined,
                          color: AppColors.primaryText,
                        ),
                        _buildMetricCard(
                          title: 'Tỷ lệ trả lời chính xác',
                          value: accuracyPercent == null
                              ? '—'
                              : '$accuracyPercent%',
                          subtitle: totalAttempts == 0
                              ? 'Chưa có dữ liệu'
                              : '$correctAttempts / $totalAttempts câu đúng',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                        _buildMetricCard(
                          title: 'Thời gian suy nghĩ trung bình',
                          value: avgTimeSeconds,
                          subtitle: avgTimeMs == null
                              ? 'Chưa có dữ liệu'
                              : 'Trung bình $avgTimeMs ms',
                          icon: Icons.timer_outlined,
                          color: AppColors.primaryText,
                        ),
                        _buildMetricCard(
                          title: 'Chuỗi học hiện tại',
                          value: '${_profile?.streakCount ?? 0} ngày',
                          subtitle:
                              'Kỷ lục: ${_profile?.longestStreak ?? 0} ngày',
                          icon: Icons.local_fire_department_outlined,
                          color: AppColors.primaryText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                        context, 'Thống kê theo ngày trong tuần'),
                    const SizedBox(height: 12),
                    _buildBarChartContainer(statistics),
                    const SizedBox(height: 24),
                    _buildReminderCard(),
                    const SizedBox(height: 24),
                    _buildBadgesSection(badgeColumns),
                    const SizedBox(height: 24),
                    _buildDetailedHistorySection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _profile;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.cardBg,
            child: Icon(
              Icons.person_outline_rounded,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.name.trim().isNotEmpty == true
                      ? profile!.name
                      : 'Hồ sơ học tập',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile == null
                      ? 'Chưa có thông tin hồ sơ'
                      : '${profile.age} tuổi • Cấp độ ${profile.currentLevel}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildProfileTag(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Chuỗi: ${profile?.streakCount ?? 0} ngày',
                    ),
                    _buildProfileTag(
                      icon: Icons.emoji_events_outlined,
                      label:
                          '${profile?.unlockedBadgeIds.length ?? 0} huy hiệu',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTag({
    required IconData icon,
    required String label,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.primaryText),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartContainer(ParentDashboardStatistics statistics) {
    const weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final maximumAttempts = statistics.attemptsByWeekday.fold<int>(
      0,
      (maximum, count) => count > maximum ? count : maximum,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.parentCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            statistics.hasData
                ? 'Số lượt làm trong 7 ngày gần nhất'
                : 'Chưa có dữ liệu trong 7 ngày gần nhất',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(weekdayLabels.length, (index) {
                final count = statistics.attemptsByWeekday[index];
                final barHeight =
                    count == 0 ? 3.0 : 88 * count / maximumAttempts;

                return Expanded(
                  child: Semantics(
                    label: '${weekdayLabels[index]}: $count lượt làm',
                    child: Column(
                      children: [
                        Text(
                          '$count',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 18,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          weekdayLabels[index],
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: AppColors.accentOrange.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_on_rounded,
                color: AppColors.accentOrange, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch Nhắc Học Cố Định 19:00',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 3),
                Text(
                  _reminderSettings.statusText,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Switch(
            value: _reminderSettings.enabled,
            activeColor: AppColors.accentOrange,
            onChanged: _toggleReminder,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(int columns) {
    final unlockedIds = Set<String>.from(_profile?.unlockedBadgeIds ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildSectionTitle(context, 'Bộ sưu tập huy hiệu'),
            Text(
              '${unlockedIds.length} / ${BadgeDefinitions.allBadges.length} đã mở',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: BadgeDefinitions.allBadges.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns >= 4 ? 1.15 : 0.95,
          ),
          itemBuilder: (context, index) {
            final badge = BadgeDefinitions.allBadges[index];
            final isUnlocked = unlockedIds.contains(badge.id);

            return KidBadgeCard(
              badge: badge,
              isUnlocked: isUnlocked,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailedHistorySection() {
    final logs = _filteredLogs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Lịch sử làm bài chi tiết'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildFilterChip('Tất cả', 'all'),
            _buildFilterChip('Đúng', 'correct'),
            _buildFilterChip('Cần ôn', 'incorrect'),
          ],
        ),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                'Chưa có lịch sử làm bài theo bộ lọc này.',
                style: TextStyle(color: AppColors.textLight),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length > 20 ? 20 : logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: log.isCorrect
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        log.isCorrect ? Icons.check_circle : Icons.cancel,
                        color:
                            log.isCorrect ? AppColors.success : AppColors.error,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.questionText.isNotEmpty
                                ? log.questionText
                                : 'Bài tập ID: ${log.questionId}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đáp án của bé: ${log.userAnswer} • ${log.answeredVia == "voice" ? "🎙️ Giọng nói AI" : "🖐️ Bàn tay"}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${log.responseTimeMs} ms',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _logFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textDark,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.buttonPrimary,
      backgroundColor: AppColors.parentCardBg,
      side: BorderSide(
        color: isSelected ? AppColors.buttonPrimaryOutline : AppColors.outline,
      ),
      onSelected: (_) => setState(() => _logFilter = value),
    );
  }
}
