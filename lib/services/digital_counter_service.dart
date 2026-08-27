import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'stats_service.dart' show DailyStat;

/// Snapshot of a digital counter's saved progress and stats.
class CounterState {
  final int currentCount;
  final int target;
  final int totalCount;
  final int cyclesCompleted;
  final int todayCount;
  final List<DailyStat> last7Days;

  const CounterState({
    required this.currentCount,
    required this.target,
    required this.totalCount,
    required this.cyclesCompleted,
    required this.todayCount,
    required this.last7Days,
  });

  static const empty = CounterState(
    currentCount: 0,
    target: 33,
    totalCount: 0,
    cyclesCompleted: 0,
    todayCount: 0,
    last7Days: [],
  );
}

/// A persisted tap-counter (used for both the Tasbeeh and Salawat screens).
/// Each instance is scoped to its own SharedPreferences key so the two
/// counters never interfere with each other.
///
/// Storage shape (JSON):
/// {
///   "currentCount": int,
///   "target": int,
///   "totalCount": int,
///   "cyclesCompleted": int,
///   "dailyCounts": { "yyyy-MM-dd": int, ... }   // pruned to last 35 days
/// }
class DigitalCounterService {
  DigitalCounterService(this._storageKey, {this.defaultTarget = 33});

  final String _storageKey;
  final int defaultTarget;

  static const _maxDailyHistoryDays = 35;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> _load() async {
    final p = await _p;
    final raw = p.getString(_storageKey);
    if (raw == null) {
      return {
        'currentCount': 0,
        'target': defaultTarget,
        'totalCount': 0,
        'cyclesCompleted': 0,
        'dailyCounts': <String, dynamic>{},
      };
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _save(Map<String, dynamic> data) async {
    final p = await _p;
    await p.setString(_storageKey, jsonEncode(data));
  }

  CounterState _toState(Map<String, dynamic> data) {
    final dailyCounts =
        Map<String, dynamic>.from(data['dailyCounts'] as Map? ?? {});
    final now = DateTime.now();
    final last7Days = <DailyStat>[];
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final count = dailyCounts[_dateKey(day)] as int? ?? 0;
      last7Days.add(DailyStat(day: day, count: count));
    }

    return CounterState(
      currentCount: data['currentCount'] as int? ?? 0,
      target: data['target'] as int? ?? defaultTarget,
      totalCount: data['totalCount'] as int? ?? 0,
      cyclesCompleted: data['cyclesCompleted'] as int? ?? 0,
      todayCount: dailyCounts[_dateKey(now)] as int? ?? 0,
      last7Days: last7Days,
    );
  }

  Future<CounterState> load() async {
    final data = await _load();
    return _toState(data);
  }

  /// Registers one tap: bumps current/total/today counts, haptic-cycle
  /// completion is signalled via [CounterState.cyclesCompleted] increasing.
  Future<CounterState> increment() async {
    final data = await _load();

    final target = data['target'] as int? ?? defaultTarget;
    var current = (data['currentCount'] as int? ?? 0) + 1;
    var cycles = data['cyclesCompleted'] as int? ?? 0;

    if (current >= target) {
      cycles++;
      current = 0;
    }

    data['currentCount'] = current;
    data['cyclesCompleted'] = cycles;
    data['totalCount'] = (data['totalCount'] as int? ?? 0) + 1;

    final dailyCounts =
        Map<String, dynamic>.from(data['dailyCounts'] as Map? ?? {});
    final todayKey = _dateKey(DateTime.now());
    dailyCounts[todayKey] = (dailyCounts[todayKey] as int? ?? 0) + 1;

    final cutoff =
        DateTime.now().subtract(const Duration(days: _maxDailyHistoryDays));
    dailyCounts.removeWhere((key, _) {
      final parts = key.split('-');
      if (parts.length != 3) return true;
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return date.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day));
    });
    data['dailyCounts'] = dailyCounts;

    await _save(data);
    return _toState(data);
  }

  /// Resets only the current (in-progress) count back to zero; totals and
  /// history are kept.
  Future<CounterState> resetProgress() async {
    final data = await _load();
    data['currentCount'] = 0;
    await _save(data);
    return _toState(data);
  }

  Future<CounterState> setTarget(int target) async {
    final data = await _load();
    data['target'] = target;
    if ((data['currentCount'] as int? ?? 0) >= target) {
      data['currentCount'] = 0;
    }
    await _save(data);
    return _toState(data);
  }

  /// Clears everything: current progress, totals, cycles and daily history.
  Future<CounterState> clearStatistics() async {
    final p = await _p;
    await p.remove(_storageKey);
    return _toState(await _load());
  }
}
