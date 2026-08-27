import 'package:flutter/material.dart';

enum AppThemeColor { green, blue, gold }

class AppSettings {
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final bool hideCompleted;
  final bool isDark;
  final AppThemeColor themeColor;
  final bool morningReminderEnabled;
  final int morningReminderHour;
  final int morningReminderMinute;
  final bool eveningReminderEnabled;
  final int eveningReminderHour;
  final int eveningReminderMinute;

  const AppSettings({
    this.fontSize = 18,
    this.fontWeight = FontWeight.w400,
    this.textAlign = TextAlign.right,
    this.hideCompleted = true,
    this.isDark = true,
    this.themeColor = AppThemeColor.green,
    this.morningReminderEnabled = false,
    this.morningReminderHour = 6,
    this.morningReminderMinute = 0,
    this.eveningReminderEnabled = false,
    this.eveningReminderHour = 17,
    this.eveningReminderMinute = 0,
  });

  TimeOfDay get morningReminderTime =>
      TimeOfDay(hour: morningReminderHour, minute: morningReminderMinute);

  TimeOfDay get eveningReminderTime =>
      TimeOfDay(hour: eveningReminderHour, minute: eveningReminderMinute);

  AppSettings copyWith({
    double? fontSize,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    bool? hideCompleted,
    bool? isDark,
    AppThemeColor? themeColor,
    bool? morningReminderEnabled,
    int? morningReminderHour,
    int? morningReminderMinute,
    bool? eveningReminderEnabled,
    int? eveningReminderHour,
    int? eveningReminderMinute,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      textAlign: textAlign ?? this.textAlign,
      hideCompleted: hideCompleted ?? this.hideCompleted,
      isDark: isDark ?? this.isDark,
      themeColor: themeColor ?? this.themeColor,
      morningReminderEnabled:
          morningReminderEnabled ?? this.morningReminderEnabled,
      morningReminderHour: morningReminderHour ?? this.morningReminderHour,
      morningReminderMinute:
          morningReminderMinute ?? this.morningReminderMinute,
      eveningReminderEnabled:
          eveningReminderEnabled ?? this.eveningReminderEnabled,
      eveningReminderHour: eveningReminderHour ?? this.eveningReminderHour,
      eveningReminderMinute:
          eveningReminderMinute ?? this.eveningReminderMinute,
    );
  }

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'fontWeight': _weightToString(fontWeight),
        'textAlign': _alignToString(textAlign),
        'hideCompleted': hideCompleted,
        'isDark': isDark,
        'themeColor': themeColor.name,
        'morningReminderEnabled': morningReminderEnabled,
        'morningReminderHour': morningReminderHour,
        'morningReminderMinute': morningReminderMinute,
        'eveningReminderEnabled': eveningReminderEnabled,
        'eveningReminderHour': eveningReminderHour,
        'eveningReminderMinute': eveningReminderMinute,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
      fontWeight: _weightFromString(json['fontWeight'] as String?),
      textAlign: _alignFromString(json['textAlign'] as String?),
      hideCompleted: json['hideCompleted'] as bool? ?? true,
      isDark: json['isDark'] as bool? ?? true,
      themeColor: _themeColorFromString(json['themeColor'] as String?),
      morningReminderEnabled:
          json['morningReminderEnabled'] as bool? ?? false,
      morningReminderHour:
          (json['morningReminderHour'] as num?)?.toInt() ?? 6,
      morningReminderMinute:
          (json['morningReminderMinute'] as num?)?.toInt() ?? 0,
      eveningReminderEnabled:
          json['eveningReminderEnabled'] as bool? ?? false,
      eveningReminderHour:
          (json['eveningReminderHour'] as num?)?.toInt() ?? 17,
      eveningReminderMinute:
          (json['eveningReminderMinute'] as num?)?.toInt() ?? 0,
    );
  }

  static String _alignToString(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return 'left';
      case TextAlign.center:
        return 'center';
      case TextAlign.right:
      default:
        return 'right';
    }
  }

  static TextAlign _alignFromString(String? value) {
    switch (value) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
      default:
        return TextAlign.right;
    }
  }

  static String _weightToString(FontWeight weight) {
    if (weight == FontWeight.w300) return 'light';
    if (weight == FontWeight.w600) return 'medium';
    if (weight == FontWeight.w700) return 'bold';
    return 'regular';
  }

  static FontWeight _weightFromString(String? value) {
    switch (value) {
      case 'light':
        return FontWeight.w300;
      case 'medium':
        return FontWeight.w600;
      case 'bold':
        return FontWeight.w700;
      case 'regular':
      default:
        return FontWeight.w400;
    }
  }

  static AppThemeColor _themeColorFromString(String? value) {
    return AppThemeColor.values.firstWhere(
      (c) => c.name == value,
      orElse: () => AppThemeColor.green,
    );
  }
}
