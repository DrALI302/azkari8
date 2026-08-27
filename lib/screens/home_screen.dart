import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/section.dart';
import '../services/storage_service.dart';
import '../services/trash_service.dart';
import '../widgets/add_section_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_card.dart';
import 'azkar_screen.dart';
import 'favorites_screen.dart';
import 'recycle_bin_screen.dart';
import 'salawat_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'tasbeeh_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  const HomeScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = StorageService.instance;
  final _trash = TrashService.instance;
  final _searchController = TextEditingController();
  List<Section> _sections = [];
  bool _isLoading = true;
  bool _isReorderMode = false;
  bool _isSearching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadSections();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSections() async {
    final sections = await _storage.loadSections();
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _isLoading = false;
    });
  }

  /// Sections matching the search query, either by their own name or by
  /// containing a zekr whose title/text matches.
  List<Section> get _filteredSections {
    if (_query.isEmpty) return _sections;
    final q = _query.toLowerCase();
    return _sections.where((s) {
      if (s.name.toLowerCase().contains(q)) return true;
      return s.azkar.any((z) =>
          z.title.toLowerCase().contains(q) || z.text.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _openSettings() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          settings: widget.settings,
          onSettingsChanged: widget.onSettingsChanged,
        ),
      ),
    );
  }

  Future<void> _openFavorites() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => FavoritesScreen(settings: widget.settings),
      ),
    );
    if (mounted) await _loadSections();
  }

  Future<void> _openStats() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const StatsScreen()),
    );
  }

  Future<void> _openTasbeeh() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const TasbeehScreen()),
    );
  }

  Future<void> _openSalawat() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const SalawatScreen()),
    );
  }

  Future<void> _openRecycleBin() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const RecycleBinScreen()),
    );
    if (mounted) await _loadSections();
  }

  Future<void> _addSection() async {
    final name = await showSectionSheet(context: context);
    if (name == null || !mounted) return;

    if (_sections.any((s) => s.name == name)) {
      _showSnackBar('القسم موجود بالفعل');
      return;
    }

    final section = Section(
      id: StorageService.generateId(),
      name: name,
      azkar: [],
    );

    await _storage.addSection(section);
    await _loadSections();
  }

  Future<void> _editSection(Section section) async {
    final name = await showSectionSheet(
      context: context,
      title: 'تعديل القسم',
      initialName: section.name,
      confirmLabel: 'حفظ',
    );
    if (name == null || !mounted) return;

    if (_sections.any((s) => s.id != section.id && s.name == name)) {
      _showSnackBar('القسم موجود بالفعل');
      return;
    }

    section.name = name;
    section.touch();
    await _storage.updateSection(section);
    await _loadSections();
  }

  Future<void> _deleteSection(Section section) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'حذف القسم',
      message: 'هل أنت متأكد من حذف "${section.name}" وجميع أذكاره؟',
    );

    if (confirmed != true || !mounted) return;

    final trashId = await _trash.trashSection(section);
    await _storage.deleteSection(section.id);
    await _loadSections();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف "${section.name}"'),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () => _undoDeleteSection(trashId),
        ),
      ),
    );
  }

  Future<void> _undoDeleteSection(String trashId) async {
    final restored = await _trash.restoreSection(trashId);
    if (restored == null || !mounted) return;
    await _storage.addSection(restored);
    await _loadSections();
  }

  Future<void> _openSection(Section section) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AzkarScreen(
          sectionId: section.id,
          settings: widget.settings,
        ),
      ),
    );

    if (mounted) await _loadSections();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, item);
    });
  }

  Future<void> _finishReorder() async {
    setState(() => _isReorderMode = false);
    await _storage.saveSections(_sections);
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _filteredSections;

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
                  hintText: 'بحث في الأقسام والأذكار...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('أذكاري'),
        actions: [
          if (!_isReorderMode)
            IconButton(
              tooltip: _isSearching ? 'إغلاق البحث' : 'بحث',
              onPressed: _toggleSearch,
              icon: Icon(_isSearching ? Icons.close : Icons.search),
            ),
          if (!_isSearching && _sections.length > 1)
            IconButton(
              tooltip: _isReorderMode ? 'إنهاء الترتيب' : 'ترتيب الأقسام',
              onPressed: () {
                if (_isReorderMode) {
                  _finishReorder();
                } else {
                  setState(() => _isReorderMode = true);
                }
              },
              icon: Icon(_isReorderMode ? Icons.check : Icons.reorder),
            ),
          if (!_isSearching && !_isReorderMode)
            PopupMenuButton<String>(
              tooltip: 'المزيد',
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'favorites':
                    _openFavorites();
                  case 'stats':
                    _openStats();
                  case 'tasbeeh':
                    _openTasbeeh();
                  case 'salawat':
                    _openSalawat();
                  case 'trash':
                    _openRecycleBin();
                  case 'settings':
                    _openSettings();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'favorites',
                  child: ListTile(
                    leading: Icon(Icons.star_outline_rounded),
                    title: Text('المفضلة'),
                  ),
                ),
                PopupMenuItem(
                  value: 'stats',
                  child: ListTile(
                    leading: Icon(Icons.bar_chart_rounded),
                    title: Text('الإحصائيات'),
                  ),
                ),
                PopupMenuItem(
                  value: 'tasbeeh',
                  child: ListTile(
                    leading: Icon(Icons.fingerprint_rounded),
                    title: Text('المسبحة الإلكترونية'),
                  ),
                ),
                PopupMenuItem(
                  value: 'salawat',
                  child: ListTile(
                    leading: Icon(Icons.favorite_border_rounded),
                    title: Text('عداد الصلاة على النبي'),
                  ),
                ),
                PopupMenuItem(
                  value: 'trash',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('سلة المحذوفات'),
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings_outlined),
                    title: Text('الإعدادات'),
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: _isReorderMode || _isSearching
          ? null
          : FloatingActionButton.extended(
              onPressed: _addSection,
              icon: const Icon(Icons.add),
              label: const Text('قسم جديد'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sections.isEmpty
              ? EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'لا توجد أقسام',
                  subtitle: 'ابدأ بإضافة قسم جديد لتنظيم أذكارك',
                  actionLabel: 'إضافة قسم',
                  onAction: _addSection,
                )
              : sections.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'لا توجد نتائج',
                      subtitle: 'جرّب كلمة بحث أخرى',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSections,
                      child: _isReorderMode
                          ? ReorderableListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 20, 100),
                              itemCount: _sections.length,
                              onReorder: _onReorder,
                              proxyDecorator: (child, index, animation) {
                                return AnimatedBuilder(
                                  animation: animation,
                                  builder: (context, child) {
                                    final scale =
                                        1.0 + (animation.value * 0.03);
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
                                final section = _sections[index];
                                return Padding(
                                  key: ValueKey(section.id),
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: SectionCard(
                                    section: section,
                                    hideCompleted:
                                        widget.settings.hideCompleted,
                                    showDragHandle: true,
                                    dragIndex: index,
                                    onTap: () {},
                                    onEdit: () => _editSection(section),
                                    onDelete: () => _deleteSection(section),
                                  ),
                                );
                              },
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 20, 100),
                              itemCount: sections.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final section = sections[index];
                                return SectionCard(
                                  key: ValueKey(section.id),
                                  section: section,
                                  hideCompleted: widget.settings.hideCompleted,
                                  onTap: () => _openSection(section),
                                  onEdit: () => _editSection(section),
                                  onDelete: () => _deleteSection(section),
                                );
                              },
                            ),
                    ),
    );
  }
}
