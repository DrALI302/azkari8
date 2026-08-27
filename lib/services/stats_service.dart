import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single day's completion count, used for the weekly mini chart.
class DailyStat {
  final DateTime day;
  final int count;
  const DailyStat({required this.day, required this.count});
}

/// A ranked entry (section or zekr) with a display label and a count.
class RankedStat {
  final String label;
  final String? sublabel;
  final int count;
  const RankedStat({required this.label, this.sublabel, required this.count});
}

class StatsSummary {
  final int totalCompleted;
  final int todayCount;
  final int last7DaysCount;
  final List<DailyStat> last7Days;
  final RankedStat? mostUsedSection;
  final RankedStat? mostRepeatedZekr;

  const StatsSummary({
    required this.totalCompleted,
    required this.todayCount,
    required this.last7DaysCount,
    required this.last7Days,
    required this.mostUsedSection,
    required this.mostRepeatedZekr,
  });

  static const empty = StatsSummary(
    totalCompleted: 0,
    todayCount: 0,
    last7DaysCount: 0,
    last7Days: [],
    mostUsedSection: null,
    mostRepeatedZekr: null,
  );
}

/// Tracks how many times the user has ticked off a zekr, broken down by
/// day, by section, and by zekr — so Statistics can show daily/weekly
/// totals plus "most used section" and "most repeated zikr".
///
/// Storage shape (SharedPreferences, key `stats_v1`, JSON):
/// {
///   "totalCompleted": int,
///   "dailyCounts": { "yyyy-MM-dd": int, ... },   // pruned to last 35 days
///   "sectionStats": { sectionId: {"name": str, "count": int}, ... },
///   "zekrStats": { zekrId: {"title": str, "count": int}, ... }
/// }
class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  static const _key = 'stats_v1';
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
    final raw = p.getString(_key);
    if (raw == null) {
      return {
        'totalCompleted': 0,
        'dailyCounts': <String, dynamic>{},
        'sectionStats': <String, dynamic>{},
        'zekrStats': <String, dynamic>{},
      };
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _save(Map<String, dynamic> data) async {
    final p = await _p;
    await p.setString(_key, jsonEncode(data));
  }

  /// Records one completed repetition of [zekrId] (inside [sectionId]).
  /// Call this once per tap that decrements a zekr's counter.
  Future<void> recordCompletion({
    required String sectionId,
    required String sectionName,
    required String zekrId,
    required String zekrTitle,
  }) async {
    final data = await _load();

    data['totalCompleted'] = (data['totalCompleted'] as int? ?? 0) + 1;

    final dailyCounts =
        Map<String, dynamic>.from(data['dailyCounts'] as Map? ?? {});
    final todayKey = _dateKey(DateTime.now());
    dailyCounts[todayKey] = (dailyCounts[todayKey] as int? ?? 0) + 1;

    // Prune anything older than _maxDailyHistoryDays to bound storage.
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

    final sectionStats =
        Map<String, dynamic>.from(data['sectionStats'] as Map? ?? {});
    final currentSection =
        Map<String, dynamic>.from(sectionStats[sectionId] as Map? ?? {});
    sectionStats[sectionId] = {
      'name': sectionName,
      'count': (currentSection['count'] as int? ?? 0) + 1,
    };
    data['sectionStats'] = sectionStats;

    final zekrStats =
        Map<String, dynamic>.from(data['zekrStats'] as Map? ?? {});
    final currentZekr =
        Map<String, dynamic>.from(zekrStats[zekrId] as Map? ?? {});
    zekrStats[zekrId] = {
      'title': zekrTitle,
      'count': (currentZekr['count'] as int? ?? 0) + 1,
    };
    data['zekrStats'] = zekrStats;

    await _save(data);
  }

  Future<StatsSummary> loadSummary() async {
    final data = await _load();

    final total = data['totalCompleted'] as int? ?? 0;
    final dailyCounts =
        Map<String, dynamic>.from(data['dailyCounts'] as Map? ?? {});

    final now = DateTime.now();
    final last7Days = <DailyStat>[];
    var last7DaysTotal = 0;
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final count = dailyCounts[_dateKey(day)] as int? ?? 0;
      last7Days.add(DailyStat(day: day, count: count));
      last7DaysTotal += count;
    }
    final todayCount = dailyCounts[_dateKey(now)] as int? ?? 0;

    final sectionStats =
        Map<String, dynamic>.from(data['sectionStats'] as Map? ?? {});
    RankedStat? mostUsedSection;
    for (final entry in sectionStats.entries) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      final count = map['count'] as int? ?? 0;
      if (mostUsedSection == null || count > mostUsedSection.count) {
        mostUsedSection = RankedStat(
          label: map['name'] as String? ?? 'قسم',
          count: count,
        );
      }
    }

    final zekrStats =
        Map<String, dynamic>.from(data['zekrStats'] as Map? ?? {});
    RankedStat? mostRepeatedZekr;
    for (final entry in zekrStats.entries) {
      final map = Map<String, dynamic>.from(entry.value as Map);
      final count = map['count'] as int? ?? 0;
      if (mostRepeatedZekr == null || count > mostRepeatedZekr.count) {
        mostRepeatedZekr = RankedStat(
          label: map['title'] as String? ?? 'ذكر',
          count: count,
        );
      }
    }

    return StatsSummary(
      totalCompleted: total,
      todayCount: todayCount,
      last7DaysCount: last7DaysTotal,
      last7Days: last7Days,
      mostUsedSection: mostUsedSection,
      mostRepeatedZekr: mostRepeatedZekr,
    );
  }

  /// Clears all recorded statistics (used only if the user wants a clean
  /// slate; not wired to any UI yet).
  Future<void> reset() async {
    final p = await _p;
    await p.remove(_key);
  }
}
