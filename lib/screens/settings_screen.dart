import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/import_mode_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = StorageService.instance;
  late AppSettings _settings;
  bool _isBackupBusy = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  Future<void> _updateSettings(AppSettings updated) async {
    setState(() => _settings = updated);
    await _storage.saveSettings(updated);
    widget.onSettingsChanged(updated);
  }

  String _themeColorLabel(AppThemeColor color) {
    switch (color) {
      case AppThemeColor.green:
        return 'أخضر';
      case AppThemeColor.blue:
        return 'أزرق';
      case AppThemeColor.gold:
        return 'ذهبي';
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleMorningReminder(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        _showSnackBar('يرجى تفعيل إذن الإشعارات من إعدادات الجهاز');
        return;
      }
    }

    await _updateSettings(_settings.copyWith(morningReminderEnabled: enabled));

    if (enabled) {
      await NotificationService.instance
          .scheduleMorningReminder(_settings.morningReminderTime);
    } else {
      await NotificationService.instance.cancelMorningReminder();
    }
  }

  Future<void> _toggleEveningReminder(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        _showSnackBar('يرجى تفعيل إذن الإشعارات من إعدادات الجهاز');
        return;
      }
    }

    await _updateSettings(_settings.copyWith(eveningReminderEnabled: enabled));

    if (enabled) {
      await NotificationService.instance
          .scheduleEveningReminder(_settings.eveningReminderTime);
    } else {
      await NotificationService.instance.cancelEveningReminder();
    }
  }

  Future<void> _pickMorningTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settings.morningReminderTime,
    );
    if (picked == null) return;

    await _updateSettings(_settings.copyWith(
      morningReminderHour: picked.hour,
      morningReminderMinute: picked.minute,
    ));

    if (_settings.morningReminderEnabled) {
      await NotificationService.instance.scheduleMorningReminder(picked);
    }
  }

  Future<void> _pickEveningTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _settings.eveningReminderTime,
    );
    if (picked == null) return;

    await _updateSettings(_settings.copyWith(
      eveningReminderHour: picked.hour,
      eveningReminderMinute: picked.minute,
    ));

    if (_settings.eveningReminderEnabled) {
      await NotificationService.instance.scheduleEveningReminder(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  Future<void> _exportBackup() async {
    setState(() => _isBackupBusy = true);
    try {
      final json = await _storage.exportBackupJson();
      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final file = File('${dir.path}/azkari_backup_$stamp.json');
      await file.writeAsString(json, encoding: utf8);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          text: 'نسخة احتياطية من تطبيق أذكاري',
        ),
      );
    } catch (_) {
      _showSnackBar('تعذر إنشاء النسخة الاحتياطية');
    } finally {
      if (mounted) setState(() => _isBackupBusy = false);
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    final picked = result.files.single;
    final bytes = picked.bytes;
    String? content;
    if (bytes != null) {
      content = utf8.decode(bytes);
    } else if (picked.path != null) {
      content = await File(picked.path!).readAsString(encoding: utf8);
    }
    if (content == null || !mounted) {
      _showSnackBar('تعذر قراءة الملف');
      return;
    }

    final mode = await showImportModeDialog(context: context);
    if (mode == null || !mounted) return;

    setState(() => _isBackupBusy = true);
    try {
      final importResult = await _storage.importBackupJson(
        content,
        merge: mode == ImportMode.merge,
      );

      if (importResult.settingsRestored) {
        final restored = await _storage.loadSettings();
        setState(() => _settings = restored);
        widget.onSettingsChanged(restored);
      }

      if (!mounted) return;
      _showSnackBar(
        importResult.replaced
            ? 'تم استبدال البيانات بـ ${importResult.sectionsAdded} قسم'
            : 'تمت إضافة ${importResult.sectionsAdded} قسم و'
                '${importResult.azkarAdded} ذكر جديد',
      );
    } on BackupFormatException catch (e) {
      _showSnackBar(e.message);
    } catch (_) {
      _showSnackBar('تعذر استيراد النسخة الاحتياطية');
    } finally {
      if (mounted) setState(() => _isBackupBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _SectionHeader(title: 'المظهر'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_size, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'حجم الخط',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_settings.fontSize.round()}',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settings.fontSize,
                    min: 14,
                    max: 28,
                    divisions: 14,
                    label: '${_settings.fontSize.round()}',
                    onChanged: (value) =>
                        _updateSettings(_settings.copyWith(fontSize: value)),
                  ),
                  Text(
                    'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
                    textAlign: _settings.textAlign,
                    style: GoogleFonts.amiri(
                      fontSize: _settings.fontSize,
                      fontWeight: _settings.fontWeight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_bold, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'سُمك الخط',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<FontWeight>(
                    segments: const [
                      ButtonSegment(
                        value: FontWeight.w300,
                        label: Text('خفيف'),
                      ),
                      ButtonSegment(
                        value: FontWeight.w400,
                        label: Text('عادي'),
                      ),
                      ButtonSegment(
                        value: FontWeight.w600,
                        label: Text('متوسط'),
                      ),
                      ButtonSegment(
                        value: FontWeight.w700,
                        label: Text('عريض'),
                      ),
                    ],
                    selected: {_settings.fontWeight},
                    onSelectionChanged: (selection) => _updateSettings(
                      _settings.copyWith(fontWeight: selection.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'لون التطبيق',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: AppThemeColor.values.map((color) {
                      final isSelected = _settings.themeColor == color;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _updateSettings(
                            _settings.copyWith(themeColor: color),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: themeAccentColor(color),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.onSurface
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 20)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _themeColorLabel(color),
                                  style: GoogleFonts.cairo(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_align_right,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'محاذاة النص',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<TextAlign>(
                    segments: const [
                      ButtonSegment(
                        value: TextAlign.right,
                        icon: Icon(Icons.format_align_right),
                        label: Text('يمين'),
                      ),
                      ButtonSegment(
                        value: TextAlign.center,
                        icon: Icon(Icons.format_align_center),
                        label: Text('وسط'),
                      ),
                      ButtonSegment(
                        value: TextAlign.left,
                        icon: Icon(Icons.format_align_left),
                        label: Text('يسار'),
                      ),
                    ],
                    selected: {_settings.textAlign},
                    onSelectionChanged: (selection) => _updateSettings(
                      _settings.copyWith(textAlign: selection.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              secondary: Icon(Icons.dark_mode, color: theme.colorScheme.primary),
              title: Text('الوضع الداكن', style: GoogleFonts.cairo()),
              subtitle: Text(
                'تبديل بين الوضع الفاتح والداكن',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              value: _settings.isDark,
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(isDark: value)),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'الأذكار'),
          Card(
            child: SwitchListTile(
              secondary:
                  Icon(Icons.visibility_off, color: theme.colorScheme.primary),
              title: Text('إخفاء الأذكار المكتملة', style: GoogleFonts.cairo()),
              subtitle: Text(
                'إخفاء الذكر تلقائياً عند وصول العداد إلى صفر',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              value: _settings.hideCompleted,
              onChanged: (value) =>
                  _updateSettings(_settings.copyWith(hideCompleted: value)),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'التذكيرات'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary:
                      Icon(Icons.wb_sunny_outlined, color: theme.colorScheme.primary),
                  title: Text('تذكير أذكار الصباح', style: GoogleFonts.cairo()),
                  subtitle: Text(
                    _settings.morningReminderEnabled
                        ? 'يومياً الساعة ${_formatTime(_settings.morningReminderTime)}'
                        : 'غير مفعّل',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  value: _settings.morningReminderEnabled,
                  onChanged: _toggleMorningReminder,
                ),
                if (_settings.morningReminderEnabled)
                  ListTile(
                    contentPadding:
                        const EdgeInsets.only(right: 16, left: 16, bottom: 8),
                    leading: const SizedBox(width: 24),
                    title: Text('وقت التذكير', style: GoogleFonts.cairo(fontSize: 13)),
                    trailing: TextButton(
                      onPressed: _pickMorningTime,
                      child: Text(_formatTime(_settings.morningReminderTime)),
                    ),
                  ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.nights_stay_outlined,
                      color: theme.colorScheme.primary),
                  title: Text('تذكير أذكار المساء', style: GoogleFonts.cairo()),
                  subtitle: Text(
                    _settings.eveningReminderEnabled
                        ? 'يومياً الساعة ${_formatTime(_settings.eveningReminderTime)}'
                        : 'غير مفعّل',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  value: _settings.eveningReminderEnabled,
                  onChanged: _toggleEveningReminder,
                ),
                if (_settings.eveningReminderEnabled)
                  ListTile(
                    contentPadding:
                        const EdgeInsets.only(right: 16, left: 16, bottom: 8),
                    leading: const SizedBox(width: 24),
                    title: Text('وقت التذكير', style: GoogleFonts.cairo(fontSize: 13)),
                    trailing: TextButton(
                      onPressed: _pickEveningTime,
                      child: Text(_formatTime(_settings.eveningReminderTime)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'النسخ الاحتياطي والاستعادة'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.upload_rounded,
                      color: theme.colorScheme.primary),
                  title: Text('تصدير نسخة احتياطية', style: GoogleFonts.cairo()),
                  subtitle: Text(
                    'حفظ جميع الأقسام والأذكار والإعدادات في ملف JSON',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  trailing: _isBackupBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_left),
                  onTap: _isBackupBusy ? null : _exportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.download_rounded,
                      color: theme.colorScheme.primary),
                  title: Text('استيراد نسخة احتياطية', style: GoogleFonts.cairo()),
                  subtitle: Text(
                    'استعادة البيانات من ملف نسخة احتياطية (دمج أو استبدال)',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                  trailing: _isBackupBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_left),
                  onTap: _isBackupBusy ? null : _importBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'يتم حفظ جميع الإعدادات تلقائياً على جهازك.',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
