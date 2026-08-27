import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/default_data.dart';
import '../models/app_settings.dart';
import '../models/section.dart';
import '../models/zekr.dart';

/// Outcome of a JSON backup import, used to show a summary to the user.
class BackupImportResult {
  final bool replaced;
  final int sectionsAdded;
  final int azkarAdded;
  final bool settingsRestored;

  const BackupImportResult({
    required this.replaced,
    required this.sectionsAdded,
    required this.azkarAdded,
    required this.settingsRestored,
  });
}

/// Thrown when a backup file can't be parsed or has an unexpected shape.
class BackupFormatException implements Exception {
  final String message;
  const BackupFormatException(this.message);

  @override
  String toString() => message;
}

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _sectionsKey = 'sections_v2';
  static const _settingsKey = 'app_settings_v1';
  static const _themeKey = 'isDark';
  static const _legacySectionsKey = 'sections';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<AppSettings> loadSettings() async {
    final p = await prefs;
    final data = p.getString(_settingsKey);

    if (data != null) {
      return AppSettings.fromJson(jsonDecode(data) as Map<String, dynamic>);
    }

    final legacyIsDark = p.getBool(_themeKey) ?? true;
    final settings = AppSettings(isDark: legacyIsDark);
    await saveSettings(settings);
    return settings;
  }

  Future<void> saveSettings(AppSettings settings) async {
    final p = await prefs;
    await p.setString(_settingsKey, jsonEncode(settings.toJson()));
    await p.setBool(_themeKey, settings.isDark);
  }

  Future<bool> loadThemeIsDark() async {
    final settings = await loadSettings();
    return settings.isDark;
  }

  Future<void> saveThemeIsDark(bool isDark) async {
    final settings = await loadSettings();
    await saveSettings(settings.copyWith(isDark: isDark));
  }

  Future<List<Section>> loadSections() async {
    final p = await prefs;
    final data = p.getString(_sectionsKey);

    if (data != null) {
      final list = jsonDecode(data) as List<dynamic>;
      return list
          .map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final migrated = await _migrateLegacySections(p);
    if (migrated != null) {
      await saveSections(migrated);
      return migrated;
    }

    final defaults = DefaultData.initialSections();
    await saveSections(defaults);
    return defaults;
  }

  Future<List<Section>?> _migrateLegacySections(
    SharedPreferences p,
  ) async {
    final legacy = p.getString(_legacySectionsKey);
    if (legacy == null) return null;

    final names = List<String>.from(jsonDecode(legacy) as List);
    final sections = <Section>[];

    for (var i = 0; i < names.length; i++) {
      final name = names[i];
      final defaultSection = DefaultData.findDefaultByName(name);

      if (defaultSection != null) {
        sections.add(defaultSection.copyWith());
      } else {
        sections.add(
          Section(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: name,
            azkar: [],
          ),
        );
      }
    }

    await p.remove(_legacySectionsKey);
    return sections;
  }

  Future<void> saveSections(List<Section> sections) async {
    final p = await prefs;
    final encoded = jsonEncode(sections.map((s) => s.toJson()).toList());
    await p.setString(_sectionsKey, encoded);
  }

  Future<Section?> getSectionById(String sectionId) async {
    final sections = await loadSections();
    for (final section in sections) {
      if (section.id == sectionId) return section;
    }
    return null;
  }

  Future<void> updateSection(Section updated) async {
    final sections = await loadSections();
    final index = sections.indexWhere((s) => s.id == updated.id);
    if (index == -1) return;
    sections[index] = updated;
    await saveSections(sections);
  }

  Future<void> addSection(Section section) async {
    final sections = await loadSections();
    sections.add(section);
    await saveSections(sections);
  }

  Future<void> deleteSection(String sectionId) async {
    final sections = await loadSections();
    sections.removeWhere((s) => s.id == sectionId);
    await saveSections(sections);
  }

  Future<void> reorderAzkar({
    required String sectionId,
    required int oldIndex,
    required int newIndex,
  }) async {
    final section = await getSectionById(sectionId);
    if (section == null) return;

    if (newIndex > oldIndex) newIndex--;
    final item = section.azkar.removeAt(oldIndex);
    section.azkar.insert(newIndex, item);
    section.touch();
    await updateSection(section);
  }

  /// Reorders top-level sections (drag-and-drop on the home screen).
  Future<void> reorderSections({
    required int oldIndex,
    required int newIndex,
  }) async {
    final sections = await loadSections();
    if (newIndex > oldIndex) newIndex--;
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    await saveSections(sections);
  }

  /// Toggles favorite state for a single zekr and persists it.
  Future<bool> toggleFavorite({
    required String sectionId,
    required String zekrId,
  }) async {
    final section = await getSectionById(sectionId);
    if (section == null) return false;

    final index = section.azkar.indexWhere((z) => z.id == zekrId);
    if (index == -1) return false;

    section.azkar[index].toggleFavorite();
    section.touch();
    await updateSection(section);
    return section.azkar[index].isFavorite;
  }

  /// Returns every favorited zekr across all sections, paired with its
  /// parent section id/name so the Favorites screen can act on it.
  Future<List<({Section section, Zekr zekr})>> loadFavorites() async {
    final sections = await loadSections();
    final favorites = <({Section section, Zekr zekr})>[];
    for (final section in sections) {
      for (final zekr in section.azkar) {
        if (zekr.isFavorite) favorites.add((section: section, zekr: zekr));
      }
    }
    return favorites;
  }

  Future<bool> moveZekr({
    required String fromSectionId,
    required String toSectionId,
    required String zekrId,
  }) async {
    if (fromSectionId == toSectionId) return false;

    final sections = await loadSections();
    final fromIndex = sections.indexWhere((s) => s.id == fromSectionId);
    final toIndex = sections.indexWhere((s) => s.id == toSectionId);
    if (fromIndex == -1 || toIndex == -1) return false;

    final zekrIndex =
        sections[fromIndex].azkar.indexWhere((z) => z.id == zekrId);
    if (zekrIndex == -1) return false;

    final zekr = sections[fromIndex].azkar.removeAt(zekrIndex);
    sections[toIndex].azkar.add(zekr);
    await saveSections(sections);
    return true;
  }

  Future<void> updateZekr({
    required String sectionId,
    required Zekr zekr,
  }) async {
    final section = await getSectionById(sectionId);
    if (section == null) return;

    final index = section.azkar.indexWhere((z) => z.id == zekr.id);
    if (index == -1) return;

    section.azkar[index] = zekr;
    section.touch();
    await updateSection(section);
  }

  Future<void> addZekr({
    required String sectionId,
    required Zekr zekr,
  }) async {
    final section = await getSectionById(sectionId);
    if (section == null) return;

    section.azkar.add(zekr);
    section.touch();
    await updateSection(section);
  }

  Future<void> deleteZekr({
    required String sectionId,
    required String zekrId,
  }) async {
    final section = await getSectionById(sectionId);
    if (section == null) return;

    section.azkar.removeWhere((z) => z.id == zekrId);
    section.touch();
    await updateSection(section);
  }

  /// Restores a zekr coming from the Recycle Bin into its original section.
  /// If that section no longer exists, it's recreated (or an existing
  /// section with the same name is reused) so the zekr has somewhere to
  /// live.
  Future<void> restoreZekrIntoSection({
    required String sectionId,
    required String sectionName,
    required Zekr zekr,
  }) async {
    final section = await getSectionById(sectionId);
    if (section != null) {
      section.azkar.add(zekr);
      section.touch();
      await updateSection(section);
      return;
    }

    final sections = await loadSections();
    final matchIndex = sections.indexWhere((s) => s.name == sectionName);

    if (matchIndex != -1) {
      final match = sections[matchIndex];
      match.azkar.add(zekr);
      match.touch();
      await updateSection(match);
      return;
    }

    final recreated = Section(
      id: generateId(),
      name: sectionName,
      azkar: [zekr],
    );
    await addSection(recreated);
  }

  Future<void> resetAllCounters(String sectionId) async {
    final section = await getSectionById(sectionId);
    if (section == null) return;

    for (final zekr in section.azkar) {
      zekr.resetCounter();
    }
    section.touch();
    await updateSection(section);
  }

  static const int _backupVersion = 1;

  /// Serializes every section (with its azkar, counters, order and
  /// favorites) plus the current settings into a single JSON string that
  /// can be written to a file and shared.
  Future<String> exportBackupJson() async {
    final sections = await loadSections();
    final settings = await loadSettings();

    final backup = <String, dynamic>{
      'backupVersion': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'sections': sections.map((s) => s.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Restores data from a previously exported backup.
  ///
  /// When [merge] is false, local sections and settings are fully replaced
  /// by the backup's contents (order, counters, favorites, and progress are
  /// preserved exactly as exported). When [merge] is true, sections/azkar
  /// that already exist locally (matched by id) are kept untouched and only
  /// new sections/azkar from the backup are added; local settings are left
  /// alone.
  Future<BackupImportResult> importBackupJson(
    String jsonString, {
    required bool merge,
  }) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupFormatException('ملف النسخة الاحتياطية غير صالح');
    }

    final sectionsJson = data['sections'];
    if (sectionsJson is! List) {
      throw const BackupFormatException('ملف النسخة الاحتياطية غير صالح');
    }

    final importedSections = sectionsJson
        .map((e) => Section.fromJson(e as Map<String, dynamic>))
        .toList();

    final settingsJson = data['settings'];
    final importedSettings = settingsJson != null
        ? AppSettings.fromJson(settingsJson as Map<String, dynamic>)
        : null;

    if (!merge) {
      await saveSections(importedSections);
      if (importedSettings != null) {
        await saveSettings(importedSettings);
      }
      final azkarCount =
          importedSections.fold<int>(0, (sum, s) => sum + s.azkar.length);
      return BackupImportResult(
        replaced: true,
        sectionsAdded: importedSections.length,
        azkarAdded: azkarCount,
        settingsRestored: importedSettings != null,
      );
    }

    final currentSections = await loadSections();
    int sectionsAdded = 0;
    int azkarAdded = 0;

    for (final importedSection in importedSections) {
      final existingIndex =
          currentSections.indexWhere((s) => s.id == importedSection.id);

      if (existingIndex == -1) {
        currentSections.add(importedSection);
        sectionsAdded++;
        azkarAdded += importedSection.azkar.length;
        continue;
      }

      final existing = currentSections[existingIndex];
      final existingZekrIds = existing.azkar.map((z) => z.id).toSet();
      for (final zekr in importedSection.azkar) {
        if (!existingZekrIds.contains(zekr.id)) {
          existing.azkar.add(zekr);
          azkarAdded++;
        }
      }
      if (azkarAdded > 0) existing.touch();
    }

    await saveSections(currentSections);

    return BackupImportResult(
      replaced: false,
      sectionsAdded: sectionsAdded,
      azkarAdded: azkarAdded,
      settingsRestored: false,
    );
  }

  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}
