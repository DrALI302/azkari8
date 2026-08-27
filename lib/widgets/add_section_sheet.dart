import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<String?> showSectionSheet({
  required BuildContext context,
  String title = 'إضافة قسم',
  String? initialName,
  String confirmLabel = 'إضافة',
}) {
  final nameController = TextEditingController(text: initialName ?? '');

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

      return Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              autofocus: true,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'اسم القسم',
                hintText: 'مثال: 📿 أذكار السفر',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(context, name);
                    },
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
