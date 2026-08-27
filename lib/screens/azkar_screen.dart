import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/section.dart';
import '../models/zekr.dart';
import '../services/stats_service.dart';
import '../services/storage_service.dart';
import '../services/trash_service.dart';
import '../widgets/add_zekr_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/move_zekr_sheet.dart';
import '../widgets/zekr_card.dart';

class AzkarScreen extends StatefulWidget {
  final String sectionId;
  final AppSettings settings;

  const AzkarScreen({
    super.key,
    required this.sectionId,
    required this.settings,
  });

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen> {
  final _storage = StorageService.instance;
  final _trash = TrashService.instance;
  final _searchController = TextEditingController();
  Section? _section;
  List<Section> _allSections = [];
  bool _isLoading = true;
  bool _isReorderMode = false;
  bool _isSearching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final section = await _storage.getSectionById(widget.sectionId);
    final sections = await _storage.loadSections();
    if (!mounted) return;
    setState(() {
      _section = section;
      _allSections = sections;
      _isLoading = false;
    });
  }

  List<Zekr> get _displayAzkar {
    if (_section == null) return [];
    var azkar = _section!.azkar;

    if (!_isReorderMode && widget.settings.hideCompleted && _query.isEmpty) {
      azkar = azkar.where((z) => z.remaining > 0).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      azkar = azkar
          .where((z) =>
              z.title.toLowerCase().contains(q) ||
              z.text.toLowerCase().contains(q))
          .toList();
    }

    return azkar;
  }

  Future<void> _persistSection() async {
    if (_section == null) return;
    await _storage.updateSection(_section!);
  }

  Future<void> _addZekr() async {
    final result = await showZekrSheet(context: context);
    if (result == null || _section == null) return;

    final zekr = Zekr(
      id: StorageService.generateId(),
      title: result.title,
      text: result.text,
      repeat: result.repeat,
    );

    setState(() {
      _section!.azkar.add(zekr);
      _section!.touch();
    });
    await _persistSection();
  }

  Future<void> _editZekr(Zekr zekr) async {
    final result = await showZekrSheet(
      context: context,
      title: 'تعديل الذكر',
      initialTitle: zekr.title,
      initialText: zekr.text,
      initialRepeat: zekr.repeat,
      confirmLabel: 'حفظ',
      showRepeatField: true,
    );
    if (result == null || _section == null) return;

    setState(() {
      zekr.title = result.title;
      zekr.text = result.text;
      final completed = zekr.repeat - zekr.remaining;
      zekr.repeat = result.repeat;
      zekr.remaining = (result.repeat - completed).clamp(0, result.repeat);
      zekr.touch();
      _section!.touch();
    });
    await _persistSection();
  }

  Future<void> _deleteZekr(Zekr zekr) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'حذف الذكر',
      message: 'هل أنت متأكد من حذف "${zekr.title}"؟',
    );

    if (confirmed != true || _section == null) return;

    final trashId = await _trash.trashZekr(
      sectionId: _section!.id,
      sectionName: _section!.name,
      zekr: zekr,
    );

    setState(() {
      _section!.azkar.removeWhere((z) => z.id == zekr.id);
      _section!.touch();
    });
    await _persistSection();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف "${zekr.title}"'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () => _undoDeleteZekr(trashId),
        ),
      ),
    );
  }

  Future<void> _undoDeleteZekr(String trashId) async {
    final restored = await _trash.restoreZekr(trashId);
    if (restored == null || !mounted) return;
    await _storage.restoreZekrIntoSection(
      sectionId: restored.sectionId,
      sectionName: restored.sectionName,
      zekr: restored.zekr,
    );
    await _loadData();
  }

  Future<void> _resetZekrCounter(Zekr zekr) async {
    setState(() => zekr.resetCounter());
    await _persistSection();
  }

  Future<void> _toggleFavorite(Zekr zekr) async {
    setState(() => zekr.toggleFavorite());
    await _persistSection();
  }

  Future<void> _resetAllCounters() async {
    if (_section == null) return;

    final confirmed = await showConfirmDialog(
      context: context,
      title: 'إعادة تعيين العدادات',
      message: 'هل تريد إعادة جميع العدادات في هذا القسم؟',
      confirmLabel: 'إعادة التعيين',
      confirmColor: Theme.of(context).colorScheme.primary,
    );

    if (confirmed != true) return;

    setState(() {
      for (final zekr in _section!.azkar) {
        zekr.resetCounter();
      }
      _section!.touch();
    });
    await _persistSection();
  }

  Future<void> _decrementZekr(Zekr zekr) async {
    if (zekr.isCompleted) return;
    setState(() => zekr.decrement());
    await _persistSection();
    if (_section != null) {
      await StatsService.instance.recordCompletion(
        sectionId: _section!.id,
        sectionName: _section!.name,
        zekrId: zekr.id,
        zekrTitle: zekr.title,
      );
    }
  }

  Future<void> _incrementZekr(Zekr zekr) async {
    if (zekr.remaining >= zekr.repeat) return;
    HapticFeedback.mediumImpact();
    setState(() => zekr.increment());
    await _persistSection();
  }

  Future<void> _moveZekr(Zekr zekr) async {
    final targetSectionId = await showMoveZekrSheet(
      context: context,
      sections: _allSections,
      currentSectionId: widget.sectionId,
      zekrTitle: zekr.title,
    );

    if (targetSectionId == null || !mounted) return;

    final moved = await _storage.moveZekr(
      fromSectionId: widget.sectionId,
      toSectionId: targetSectionId,
      zekrId: zekr.id,
    );

    if (!moved || !mounted) return;

    final targetName = _allSections
        .firstWhere((s) => s.id == targetSectionId)
        .name;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم نقل "${zekr.title}" إلى $targetName')),
    );

    await _loadData();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_section == null) return;

    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _section!.azkar.removeAt(oldIndex);
      _section!.azkar.insert(newIndex, item);
    });
  }

  Future<void> _finishReorder() async {
    setState(() => _isReorderMode = false);
    _section?.touch();
    await _persistSection();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  Widget _buildZekrCard(
    Zekr zekr, {
    bool showDragHandle = false,
    int? dragIndex,
  }) {
    return ZekrCard(
      zekr: zekr,
      fontSize: widget.settings.fontSize,
      textAlign: widget.settings.textAlign,
      showDragHandle: showDragHandle,
      dragIndex: dragIndex,
      onTap: () => _decrementZekr(zekr),
      onLongPress: () => _incrementZekr(zekr),
      onEdit: () => _editZekr(zekr),
      onDelete: () => _deleteZekr(zekr),
      onReset: () => _resetZekrCounter(zekr),
      onMove: () => _moveZekr(zekr),
      onToggleFavorite: () => _toggleFavorite(zekr),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_section == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('غير موجود')),
        body: const Center(child: Text('القسم غير موجود')),
      );
    }

    final section = _section!;
    final displayAzkar = _displayAzkar;
    final hiddenCount = widget.settings.hideCompleted && _query.isEmpty
        ? section.azkar.where((z) => z.remaining <= 0).length
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'بحث في الأذكار...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : Text(section.name),
        actions: [
          if (!_isReorderMode)
            IconButton(
              tooltip: _isSearching ? 'إغلاق البحث' : 'بحث',
              onPressed: _toggleSearch,
              icon: Icon(_isSearching ? Icons.close : Icons.search),
            ),
          if (!_isSearching && section.azkar.length > 1)
            IconButton(
              tooltip: _isReorderMode ? 'إنهاء الترتيب' : 'ترتيب الأذكار',
              onPressed: () {
                if (_isReorderMode) {
                  _finishReorder();
                } else {
                  setState(() => _isReorderMode = true);
                }
              },
              icon: Icon(
                _isReorderMode ? Icons.check : Icons.reorder,
              ),
            ),
          if (!_isSearching && section.azkar.isNotEmpty && !_isReorderMode)
            IconButton(
              tooltip: 'إعادة تعيين العدادات',
              onPressed: _resetAllCounters,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      floatingActionButton: _isReorderMode || _isSearching
          ? null
          : FloatingActionButton.extended(
              onPressed: _addZekr,
              icon: const Icon(Icons.add),
              label: const Text('ذكر جديد'),
            ),
      body: section.azkar.isEmpty
          ? EmptyState(
              icon: Icons.auto_stories_outlined,
              title: 'لا توجد أذكار',
              subtitle: 'أضف أذكاراً لهذا القسم وابدأ الذكر',
              actionLabel: 'إضافة ذكر',
              onAction: _addZekr,
            )
          : displayAzkar.isEmpty
              ? (_query.isNotEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'لا توجد نتائج',
                      subtitle: 'جرّب كلمة بحث أخرى',
                    )
                  : EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'أكملت جميع الأذكار',
                      subtitle:
                          'يمكنك إعادة العدادات أو إيقاف الإخفاء من الإعدادات',
                      actionLabel: 'إعادة العدادات',
                      onAction: _resetAllCounters,
                    ))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      if (_isReorderMode)
                        MaterialBanner(
                          content: const Text('اسحب الأذكار لإعادة ترتيبها'),
                          leading: const Icon(Icons.drag_handle),
                          actions: [
                            TextButton(
                              onPressed: _finishReorder,
                              child: const Text('تم'),
                            ),
                          ],
                        ),
                      if (hiddenCount > 0 && !_isReorderMode)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Chip(
                              avatar: const Icon(Icons.visibility_off, size: 16),
                              label: Text('$hiddenCount ذكر مخفي'),
                            ),
                          ),
                        ),
                      Expanded(
                        child: _isReorderMode
                            ? ReorderableListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 32),
                                itemCount: section.azkar.length,
                                onReorder: _onReorder,
                                proxyDecorator: (child, index, animation) {
                                  return AnimatedBuilder(
                                    animation: animation,
                                    builder: (context, child) {
                                      final scale = 1.0 +
                                          (animation.value * 0.03);
                                      return Transform.scale(
                                        scale: scale,
                                        child: Material(
                                          elevation: 6,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: child,
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final zekr = section.azkar[index];
                                  return Padding(
                                    key: ValueKey(zekr.id),
                                    padding:
                                        const EdgeInsets.only(bottom: 14),
                                    child: _buildZekrCard(
                                      zekr,
                                      showDragHandle: true,
                                      dragIndex: index,
                                    ),
                                  );
                                },
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 100),
                                itemCount: displayAzkar.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final zekr = displayAzkar[index];
                                  return _buildZekrCard(zekr);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
