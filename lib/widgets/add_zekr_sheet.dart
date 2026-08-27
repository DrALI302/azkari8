import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ZekrFormResult {
  final String title;
  final String text;
  final int repeat;

  const ZekrFormResult({
    required this.title,
    required this.text,
    required this.repeat,
  });
}

Future<ZekrFormResult?> showZekrSheet({
  required BuildContext context,
  String title = 'إضافة ذكر',
  String? initialTitle,
  String? initialText,
  int? initialRepeat,
  String confirmLabel = 'إضافة',
  bool showRepeatField = true,
}) {
  final titleController = TextEditingController(text: initialTitle ?? '');
  final textController = TextEditingController(text: initialText ?? '');
  final repeatController = TextEditingController(
    text: (initialRepeat ?? 1).toString(),
  );

  return showModalBottomSheet<ZekrFormResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

      return Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
        child: SingleChildScrollView(
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
                controller: titleController,
                autofocus: true,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: 'عنوان الذكر',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                textAlign: TextAlign.right,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'نص الذكر',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                ),
              ),
              if (showRepeatField) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: repeatController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: 'عدد التكرار',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                  ),
                ),
              ],
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
                        final text = textController.text.trim();
                        if (text.isEmpty) return;

                        final repeat = showRepeatField
                            ? int.tryParse(repeatController.text.trim()) ?? 1
                            : (initialRepeat ?? 1);

                        Navigator.pop(
                          context,
                          ZekrFormResult(
                            title: titleController.text.trim().isEmpty
                                ? 'ذكر'
                                : titleController.text.trim(),
                            text: text,
                            repeat: repeat.clamp(1, 9999),
                          ),
                        );
                      },
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
