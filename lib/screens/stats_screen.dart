import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _stats = StatsService.instance;
  StatsSummary _summary = StatsSummary.empty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await _stats.loadSummary();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  static const _weekdayLabels = ['اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];

  String _weekdayLabel(DateTime day) => _weekdayLabels[day.weekday - 1];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.today_rounded,
                          label: 'اليوم',
                          value: '${_summary.todayCount}',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.calendar_view_week_rounded,
                          label: 'هذا الأسبوع',
                          value: '${_summary.last7DaysCount}',
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    icon: Icons.emoji_events_rounded,
                    label: 'إجمالي الأذكار المكتملة',
                    value: '${_summary.totalCompleted}',
                    color: Colors.amber.shade700,
                    isWide: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'النشاط خلال ٧ أيام',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: _WeeklyBarChart(
                        days: _summary.last7Days,
                        weekdayLabel: _weekdayLabel,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_summary.mostUsedSection != null)
                    _RankedCard(
                      icon: Icons.folder_special_rounded,
                      title: 'الأكثر استخداماً',
                      stat: _summary.mostUsedSection!,
                      unitLabel: 'مرة',
                      color: theme.colorScheme.primary,
                    ),
                  if (_summary.mostUsedSection != null)
                    const SizedBox(height: 12),
                  if (_summary.mostRepeatedZekr != null)
                    _RankedCard(
                      icon: Icons.repeat_rounded,
                      title: 'الأكثر تكراراً',
                      stat: _summary.mostRepeatedZekr!,
                      unitLabel: 'مرة',
                      color: theme.colorScheme.primary,
                    ),
                  if (_summary.totalCompleted == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.insights_outlined,
                            size: 56,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ابدأ بذكر الله وستظهر إحصائياتك هنا',
                            style: GoogleFonts.cairo(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isWide;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: isWide
            ? Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 14),
                  Text(label,
                      style: GoogleFonts.cairo(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    value,
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<DailyStat> days;
  final String Function(DateTime) weekdayLabel;
  final Color color;

  const _WeeklyBarChart({
    required this.days,
    required this.weekdayLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = days.fold<int>(1, (m, d) => d.count > m ? d.count : m);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final isToday = d.day.year == DateTime.now().year &&
              d.day.month == DateTime.now().month &&
              d.day.day == DateTime.now().day;
          final heightFraction = d.count / maxCount;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    d.count > 0 ? '${d.count}' : '',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: heightFraction.clamp(0.04, 1.0)),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Container(
                        height: 90 * value,
                        decoration: BoxDecoration(
                          color: isToday
                              ? color
                              : color.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    weekdayLabel(d.day),
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? color
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RankedCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final RankedStat stat;
  final String unitLabel;
  final Color color;

  const _RankedCard({
    required this.icon,
    required this.title,
    required this.stat,
    required this.unitLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${stat.count} $unitLabel',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
