import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../models/zekr.dart';

class ZekrCard extends StatefulWidget {
  final Zekr zekr;
  final double fontSize;
  final TextAlign textAlign;
  final bool showDragHandle;
  final int? dragIndex;
  final String? highlightQuery;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReset;
  final VoidCallback onMove;
  final VoidCallback? onToggleFavorite;
  final bool allowEditMoveDelete;

  const ZekrCard({
    super.key,
    required this.zekr,
    required this.fontSize,
    required this.textAlign,
    this.showDragHandle = false,
    this.dragIndex,
    this.highlightQuery,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.onReset,
    required this.onMove,
    this.onToggleFavorite,
    this.allowEditMoveDelete = true,
  });

  @override
  State<ZekrCard> createState() => _ZekrCardState();
}

class _ZekrCardState extends State<ZekrCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.zekr.isCompleted) return;
    HapticFeedback.lightImpact();
    await _pulseController.forward();
    await _pulseController.reverse();
    widget.onTap();
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.zekr.shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الذكر')),
    );
  }

  void _share() {
    SharePlus.instance.share(ShareParams(text: widget.zekr.shareText));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final zekr = widget.zekr;
    final isCompleted = zekr.isCompleted;

    // Theme-aware accent colors so the card reacts to the selected
    // green/blue/gold theme instead of always rendering green.
    final accent = isDark ? colorScheme.primary : colorScheme.primary;
    final softBg = colorScheme.surfaceContainerHighest;
    final surfaceCard = isDark ? colorScheme.surfaceContainerHighest : Colors.white;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.showDragHandle ? null : _handleTap,
          onLongPress: widget.showDragHandle ? null : widget.onLongPress,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isCompleted
                    ? (isDark
                        ? [
                            accent.withValues(alpha: 0.2),
                            surfaceCard,
                          ]
                        : [
                            softBg,
                            Colors.white,
                          ])
                    : (isDark
                        ? [surfaceCard, colorScheme.surface]
                        : [
                            Colors.white,
                            softBg.withValues(alpha: 0.5),
                          ]),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : accent.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: isCompleted
                    ? accent.withValues(alpha: 0.5)
                    : accent.withValues(alpha: isDark ? 0.12 : 0.15),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.showDragHandle && widget.dragIndex != null)
                        ReorderableDragStartListener(
                          index: widget.dragIndex!,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Icon(
                              Icons.drag_handle,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zekr.title,
                              style: GoogleFonts.cairo(
                                fontSize: widget.fontSize - 1,
                                fontWeight: FontWeight.bold,
                                color:
                                    isCompleted ? accent : theme.colorScheme.onSurface,
                              ),
                              textAlign: widget.textAlign,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              zekr.text,
                              style: GoogleFonts.amiri(
                                fontSize: widget.fontSize,
                                height: 1.8,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: isCompleted ? 0.6 : 0.85),
                              ),
                              textAlign: widget.textAlign,
                            ),
                          ],
                        ),
                      ),
                      if (widget.onToggleFavorite != null)
                        IconButton(
                          tooltip: zekr.isFavorite
                              ? 'إزالة من المفضلة'
                              : 'إضافة للمفضلة',
                          onPressed: widget.onToggleFavorite,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              zekr.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              key: ValueKey(zekr.isFavorite),
                              color: zekr.isFavorite
                                  ? Colors.amber
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              widget.onEdit();
                            case 'move':
                              widget.onMove();
                            case 'reset':
                              widget.onReset();
                            case 'copy':
                              _copy(context);
                            case 'share':
                              _share();
                            case 'delete':
                              widget.onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          if (widget.allowEditMoveDelete) ...[
                            _menuItem(
                                Icons.edit_outlined, 'تعديل', 'edit', theme),
                            _menuItem(Icons.drive_file_move_outline, 'نقل',
                                'move', theme),
                          ],
                          _menuItem(
                              Icons.refresh, 'إعادة العداد', 'reset', theme),
                          _menuItem(Icons.copy_rounded, 'نسخ', 'copy', theme),
                          _menuItem(Icons.share_rounded, 'مشاركة', 'share', theme),
                          if (widget.allowEditMoveDelete)
                            _menuItem(Icons.delete_outline, 'حذف', 'delete',
                                theme, isDestructive: true),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: zekr.progress,
                            ),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 8,
                                color: accent,
                                backgroundColor: isDark
                                    ? colorScheme.surfaceContainerHighest
                                    : softBg,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? accent.withValues(alpha: 0.2)
                              : (isDark
                                  ? accent.withValues(alpha: 0.3)
                                  : softBg),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCompleted)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: accent,
                                ),
                              ),
                            Text(
                              isCompleted
                                  ? 'تم'
                                  : '${zekr.remaining} / ${zekr.repeat}',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isCompleted
                                    ? accent
                                    : theme.colorScheme.primary,
                              ),
                            ),
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

  PopupMenuItem<String> _menuItem(
    IconData icon,
    String label,
    String value,
    ThemeData theme, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDestructive
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.cairo()),
        ],
      ),
    );
  }
}
