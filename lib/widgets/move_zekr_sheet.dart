import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/section.dart';

Future<String?> showMoveZekrSheet({
  required BuildContext context,
  required List<Section> sections,
  required String currentSectionId,
  required String zekrTitle,
}) {
  final targets =
      sections.where((section) => section.id != currentSectionId).toList();

  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا توجد أقسام أخرى للنقل إليها')),
    );
    return Future.value(null);
  }

  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'نقل "$zekrTitle" إلى',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: targets.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final section = targets[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(section.name, style: GoogleFonts.cairo()),
                    subtitle: Text(
                      '${section.azkar.length} أذكار',
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                    onTap: () => Navigator.pop(context, section.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
