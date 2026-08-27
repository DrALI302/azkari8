import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/digital_counter_service.dart';
import '../services/stats_service.dart' show DailyStat;

class DigitalCounterScreen extends StatefulWidget {
  final String title;
  final String dhikrText;
  final DigitalCounterService service;
  final List<int> targetPresets;
  final Color? accentColor;

  const DigitalCounterScreen({
    super.key,
    required this.title,
    required this.dhikrText,
    required this.service,
    this.targetPresets = const [33, 99, 100, 1000],
    this.accentColor,
  });

  @override
  State<DigitalCounterScreen> createState() => _DigitalCounterScreenState();
}

class _DigitalCounterScreenState extends State<DigitalCounterScreen>
    with SingleTickerProviderStateMixin {
  CounterState _state = CounterState.empty;
  bool _isLoading = true;
  late AnimationController _tapController;
  late Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeOut),
    );
    _load();
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = await widget.service.load();
    if (!mounted) return;
    setState(() {
      _state = state;
      _isLoading = false;
    });
  }

  Future<void> _onTap() async {
    await _tapController.forward();
    await _tapController.reverse();

    final wasAboutToComplete = _state.currentCount + 1 >= _state.target;
    HapticFeedback.selectionClick();
    final state = await widget.service.increment();
    if (!mounted) return;
    setState(() => _state = state);

    if (wasAboutToComplete) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1, milliseconds: 200),
            content: Text('أكملت دورة كاملة (${_state.target}) 🎉'),
          ),
        );
      }
    }
  }

  Future<void> _reset() async {
    final state = await widget.service.resetProgress();
    if (!mounted) return;
    setState(() => _state = state);
  }

  Future<void> _pickTarget() async {
    final theme = Theme.of(context);
    final selected = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اختر العدد المستهدف',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.targetPresets.map((preset) {
                    final isSelected = preset == _state.target;
                    return ChoiceChip(
                      label: Text('$preset'),
                      selected: isSelected,
                      onSelected: (_) => Navigator.pop(context, preset),
                      selectedColor: (widget.accentColor ??
                          theme.colorScheme.primary),
                      labelStyle: GoogleFonts.cairo(
                        color: isSelected ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    final state = await widget.service.setTarget(selected);
    if (!mounted) return;
    setState(() => _state = state);
  }

  Future<void> _confirmClearStats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح الإحصائيات'),
        content: const Text(
          'سيتم مسح إجمالي العدّاد وسجل الأيام السابقة نهائياً. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final state = await widget.service.clearStatistics();
    if (!mounted) return;
    setState(() => _state = state);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final progress = _state.target == 0
        ? 0.0
        : (_state.currentCount / _state.target).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'مسح الإحصائيات',
            onPressed: _confirmClearStats,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              widget.dhikrText,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(fontSize: 20, height: 1.7),
            ),
            const SizedBox(height: 28),
            Center(
              child: GestureDetector(
                onTap: _onTap,
                child: ScaleTransition(
                  scale: _tapScale,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.18),
                          accent.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 250),
                            builder: (context, value, _) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 8,
                                backgroundColor:
                                    accent.withValues(alpha: 0.12),
                                color: accent,
                              );
                            },
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_state.currentCount}',
                              style: GoogleFonts.cairo(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                color: accent,
                              ),
                            ),
                            Text(
                              'من ${_state.target}',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'اضغط في أي مكان على الدائرة للعد',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة التعيين'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _pickTarget,
                    icon: const Icon(Icons.flag_outlined),
                    label: Text('الهدف: ${_state.target}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'اليوم',
                    value: '${_state.todayCount}',
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'الدورات المكتملة',
                    value: '${_state.cyclesCompleted}',
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStat(
                    label: 'الإجمالي',
                    value: '${_state.totalCount}',
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'النشاط خلال ٧ أيام',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                child: _MiniWeeklyChart(days: _state.last7Days, color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniWeeklyChart extends StatelessWidget {
  final List<DailyStat> days;
  final Color color;

  const _MiniWeeklyChart({required this.days, required this.color});

  static const _weekdayLabels = ['اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];

  @override
  Widget build(BuildContext context) {
    final maxCount = days.fold<int>(1, (m, d) => d.count > m ? d.count : m);
    final now = DateTime.now();

    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((d) {
          final isToday = d.day.year == now.year &&
              d.day.month == now.month &&
              d.day.day == now.day;
          final fraction = d.count / maxCount;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction.clamp(0.04, 1.0)),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, _) => Container(
                      height: 60 * value,
                      decoration: BoxDecoration(
                        color: isToday ? color : color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _weekdayLabels[d.day.weekday - 1],
                    style: GoogleFonts.cairo(
                      fontSize: 9,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? color
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
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
