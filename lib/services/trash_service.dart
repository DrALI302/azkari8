import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/section.dart';
import '../models/zekr.dart';

/// A deleted section sitting in the recycle bin, along with everything
/// needed to restore it exactly as it was (azkar, counters, favorites,
/// order).
class TrashedSection {
  final String trashId;
  final Section section;
  final DateTime deletedAt;

  const TrashedSection({
    required this.trashId,
    required this.section,
    required this.deletedAt,
  });
}

/// A deleted single zekr, remembering which section it came from so it can
/// be restored back into place (or recreated if that section is gone too).
class TrashedZekr {
  final String trashId;
  final String sectionId;
  final String sectionName;
  final Zekr zekr;
  final DateTime deletedAt;

  const TrashedZekr({
    required this.trashId,
    required this.sectionId,
    required this.sectionName,
    required this.zekr,
    required this.deletedAt,
  });
}

/// Persists deleted sections/azkar for a limited time so the user can
/// restore them — either via the quick "تراجع" snackbar action right after
/// deleting, or later from the full Recycle Bin screen.
///
/// Storage shape (SharedPreferences, key `trash_v1`, JSON):
/// {
///   "sections": [ {"trashId": str, "deletedAt": iso, "section": {...}} ],
///   "azkar": [ {"trashId": str, "deletedAt": iso, "sectionId": str,
///               "sectionName": str, "zekr": {...}} ]
/// }
class TrashService {
  TrashService._();
  static final TrashService instance = TrashService._();

  static const _key = 'trash_v1';
  static const _retentionDays = 30;

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<Map<String, dynamic>> _load() async {
    final p = await _p;
    final raw = p.getString(_key);
    if (raw == null) {
      return {'sections': <dynamic>[], 'azkar': <dynamic>[]};
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _save(Map<String, dynamic> data) async {
    final p = await _p;
    await p.setString(_key, jsonEncode(data));
  }

  String _generateTrashId() =>
      'trash_${DateTime.now().microsecondsSinceEpoch}';

  /// Removes entries older than [_retentionDays] so the trash doesn't grow
  /// forever.
  Map<String, dynamic> _pruneExpired(Map<String, dynamic> data) {
    final cutoff = DateTime.now().subtract(const Duration(days: _retentionDays));

    bool isExpired(dynamic entry) {
      final map = entry as Map<String, dynamic>;
      final deletedAt = DateTime.tryParse(map['deletedAt'] as String? ?? '');
      return deletedAt == null || deletedAt.isBefore(cutoff);
    }

    final sections = (data['sections'] as List<dynamic>? ?? [])
        .where((e) => !isExpired(e))
        .toList();
    final azkar = (data['azkar'] as List<dynamic>? ?? [])
        .where((e) => !isExpired(e))
        .toList();

    return {'sections': sections, 'azkar': azkar};
  }

  /// Moves a whole section (with its azkar) to the trash. Returns the
  /// trash entry id, useful for a quick-undo snackbar action.
  Future<String> trashSection(Section section) async {
    final data = _pruneExpired(await _load());
    final trashId = _generateTrashId();

    final sections = List<dynamic>.from(data['sections'] as List);
    sections.add({
      'trashId': trashId,
      'deletedAt': DateTime.now().toIso8601String(),
      'section': section.toJson(),
    });
    data['sections'] = sections;

    await _save(data);
    return trashId;
  }

  /// Moves a single zekr to the trash, remembering its parent section.
  Future<String> trashZekr({
    required String sectionId,
    required String sectionName,
    required Zekr zekr,
  }) async {
    final data = _pruneExpired(await _load());
    final trashId = _generateTrashId();

    final azkar = List<dynamic>.from(data['azkar'] as List);
    azkar.add({
      'trashId': trashId,
      'deletedAt': DateTime.now().toIso8601String(),
      'sectionId': sectionId,
      'sectionName': sectionName,
      'zekr': zekr.toJson(),
    });
    data['azkar'] = azkar;

    await _save(data);
    return trashId;
  }

  Future<List<TrashedSection>> loadTrashedSections() async {
    final data = _pruneExpired(await _load());
    await _save(data);

    return (data['sections'] as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      return TrashedSection(
        trashId: map['trashId'] as String,
        section: Section.fromJson(map['section'] as Map<String, dynamic>),
        deletedAt: DateTime.parse(map['deletedAt'] as String),
      );
    }).toList()
      ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
  }

  Future<List<TrashedZekr>> loadTrashedAzkar() async {
    final data = _pruneExpired(await _load());
    await _save(data);

    return (data['azkar'] as List<dynamic>).map((e) {
      final map = e as Map<String, dynamic>;
      return TrashedZekr(
        trashId: map['trashId'] as String,
        sectionId: map['sectionId'] as String,
        sectionName: map['sectionName'] as String,
        zekr: Zekr.fromJson(map['zekr'] as Map<String, dynamic>),
        deletedAt: DateTime.parse(map['deletedAt'] as String),
      );
    }).toList()
      ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
  }

  /// Removes a trashed section entry and returns the [Section] so the
  /// caller can re-add it to active storage. Returns null if not found.
  Future<Section?> restoreSection(String trashId) async {
    final data = await _load();
    final sections = List<dynamic>.from(data['sections'] as List);

    final index = sections.indexWhere((e) =>
        (e as Map<String, dynamic>)['trashId'] == trashId);
    if (index == -1) return null;

    final entry = sections.removeAt(index) as Map<String, dynamic>;
    data['sections'] = sections;
    await _save(data);

    return Section.fromJson(entry['section'] as Map<String, dynamic>);
  }

  /// Removes a trashed zekr entry and returns it (with its original
  /// section id/name) so the caller can re-insert it. Returns null if not
  /// found.
  Future<TrashedZekr?> restoreZekr(String trashId) async {
    final data = await _load();
    final azkar = List<dynamic>.from(data['azkar'] as List);

    final index = azkar.indexWhere((e) =>
        (e as Map<String, dynamic>)['trashId'] == trashId);
    if (index == -1) return null;

    final entry = azkar.removeAt(index) as Map<String, dynamic>;
    data['azkar'] = azkar;
    await _save(data);

    return TrashedZekr(
      trashId: entry['trashId'] as String,
      sectionId: entry['sectionId'] as String,
      sectionName: entry['sectionName'] as String,
      zekr: Zekr.fromJson(entry['zekr'] as Map<String, dynamic>),
      deletedAt: DateTime.parse(entry['deletedAt'] as String),
    );
  }

  Future<void> permanentlyDeleteSection(String trashId) async {
    final data = await _load();
    final sections = (data['sections'] as List<dynamic>)
        .where((e) => (e as Map<String, dynamic>)['trashId'] != trashId)
        .toList();
    data['sections'] = sections;
    await _save(data);
  }

  Future<void> permanentlyDeleteZekr(String trashId) async {
    final data = await _load();
    final azkar = (data['azkar'] as List<dynamic>)
        .where((e) => (e as Map<String, dynamic>)['trashId'] != trashId)
        .toList();
    data['azkar'] = azkar;
    await _save(data);
  }

  Future<void> emptyTrash() async {
    await _save({'sections': <dynamic>[], 'azkar': <dynamic>[]});
  }
}
