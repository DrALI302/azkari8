import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/section.dart';

class SectionCard extends StatelessWidget {
  final Section section;
  final bool hideCompleted;
  final bool showDragHandle;
  final int? dragIndex;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SectionCard({
    super.key,
    required this.section,
    this.hideCompleted = false,
    this.showDragHandle = false,
    this.dragIndex,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  String get _emoji {
    final parts = section.name.split(' ');
    if (parts.isNotEmpty && parts.first.runes.length <= 2) {
      return parts.first;
    }
    return '📿';
  }

  String get _title {
    final parts = section.name.split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    }
    return section.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = colorScheme.primary;
    final softBg = colorScheme.surfaceContainerHighest;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.92 + (0.08 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showDragHandle ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? [
                        colorScheme.surfaceContainerHighest,
                        colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.85),
                      ]
                    : [
                        Colors.white,
                        softBg.withValues(alpha: 0.5),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : accent.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.15 : 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (showDragHandle && dragIndex != null)
                    ReorderableDragStartListener(
                      index: dragIndex!,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.drag_handle,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? accent.withValues(alpha: 0.3)
                          : softBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _title,
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (section.favoriteCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hideCompleted
                              ? '${section.azkar.where((z) => z.remaining > 0).length} متبقي • ${section.completedCount} مكتمل'
                              : '${section.azkar.length} أذكار • ${section.completedCount} مكتمل',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        if (section.azkar.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: section.overallProgress,
                              minHeight: 6,
                              color: accent,
                              backgroundColor: softBg,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text('تعديل', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 20, color: theme.colorScheme.error),
                            const SizedBox(width: 12),
                            Text('حذف', style: GoogleFonts.cairo()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
