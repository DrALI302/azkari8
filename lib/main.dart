import 'dart:async';

import 'package:flutter/material.dart';

import 'models/app_settings.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AzkariApp());
}

class AzkariApp extends StatefulWidget {
  const AzkariApp({super.key});

  @override
  State<AzkariApp> createState() => _AzkariAppState();
}

class _AzkariAppState extends State<AzkariApp> {
  final _storage = StorageService.instance;
  AppSettings _settings = const AppSettings();
  bool _settingsLoaded = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _storage.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _settingsLoaded = true;
    });
    unawaited(_syncReminders(settings));
  }

  /// Re-applies the saved reminder schedule on every app launch. This is a
  /// pragmatic workaround for Android alarms not always surviving a device
  /// reboot without a dedicated boot-receiver.
  Future<void> _syncReminders(AppSettings settings) async {
    final notifications = NotificationService.instance;
    await notifications.init();

    if (settings.morningReminderEnabled) {
      await notifications.scheduleMorningReminder(settings.morningReminderTime);
    } else {
      await notifications.cancelMorningReminder();
    }

    if (settings.eveningReminderEnabled) {
      await notifications.scheduleEveningReminder(settings.eveningReminderTime);
    } else {
      await notifications.cancelEveningReminder();
    }
  }

  void _onSettingsChanged(AppSettings settings) {
    setState(() => _settings = settings);
  }

  void _onSplashFinished() {
    if (!mounted) return;
    setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_settingsLoaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'أذكاري',
      theme: AppTheme.light(
        fontSize: _settings.fontSize,
        fontWeight: _settings.fontWeight,
        themeColor: _settings.themeColor,
      ),
      darkTheme: AppTheme.dark(
        fontSize: _settings.fontSize,
        fontWeight: _settings.fontWeight,
        themeColor: _settings.themeColor,
      ),
      themeMode: _settings.isDark ? ThemeMode.dark : ThemeMode.light,
      home: _showSplash
          ? SplashScreen(onFinished: _onSplashFinished)
          : HomeScreen(
              settings: _settings,
              onSettingsChanged: _onSettingsChanged,
            ),
    );
  }
}
