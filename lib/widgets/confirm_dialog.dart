import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'حذف',
  String cancelLabel = 'إلغاء',
  Color? confirmColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: confirmColor ?? theme.colorScheme.error,
          size: 36,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor ?? theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
