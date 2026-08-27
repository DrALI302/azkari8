import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ImportMode { merge, replace }

/// Asks the user whether an imported backup should be merged with the
/// current data or replace it entirely. Returns null if cancelled.
Future<ImportMode?> showImportModeDialog({required BuildContext context}) {
  return showDialog<ImportMode>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        icon: Icon(Icons.upload_file_rounded, color: theme.colorScheme.primary),
        title: const Text('استيراد نسخة احتياطية', textAlign: TextAlign.center),
        content: Text(
          'هل تريد دمج البيانات المستوردة مع بياناتك الحالية، أم استبدال جميع '
          'البيانات الحالية بها؟',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(fontSize: 14, height: 1.6),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, ImportMode.merge),
            child: const Text('دمج'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, ImportMode.replace),
            child: const Text('استبدال الكل'),
          ),
        ],
      );
    },
  );
}
