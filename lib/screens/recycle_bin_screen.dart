import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/storage_service.dart';
import '../services/trash_service.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen>
    with SingleTickerProviderStateMixin {
  final _trash = TrashService.instance;
  final _storage = StorageService.instance;

  late TabController _tabController;
  List<TrashedSection> _sections = [];
  List<TrashedZekr> _azkar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sections = await _trash.loadTrashedSections();
    final azkar = await _trash.loadTrashedAzkar();
    if (!mounted) return;
    setState(() {
      _sections = sections;
      _azkar = azkar;
      _isLoading = false;
    });
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  Future<void> _restoreSection(TrashedSection entry) async {
    final section = await _trash.restoreSection(entry.trashId);
    if (section == null || !mounted) return;
    await _storage.addSection(section);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت استعادة "${section.name}"')),
    );
  }

  Future<void> _restoreZekr(TrashedZekr entry) async {
    final restored = await _trash.restoreZekr(entry.trashId);
    if (restored == null || !mounted) return;
    await _storage.restoreZekrIntoSection(
      sectionId: restored.sectionId,
      sectionName: restored.sectionName,
      zekr: restored.zekr,
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمت استعادة "${restored.zekr.title}"')),
    );
  }

  Future<void> _deleteSectionForever(TrashedSection entry) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'حذف نهائي',
      message: 'سيتم حذف "${entry.section.name}" نهائياً ولا يمكن التراجع.',
      confirmLabel: 'حذف نهائياً',
    );
    if (confirmed != true) return;
    await _trash.permanentlyDeleteSection(entry.trashId);
    await _load();
  }

  Future<void> _deleteZekrForever(TrashedZekr entry) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'حذف نهائي',
      message: 'سيتم حذف "${entry.zekr.title}" نهائياً ولا يمكن التراجع.',
      confirmLabel: 'حذف نهائياً',
    );
    if (confirmed != true) return;
    await _trash.permanentlyDeleteZekr(entry.trashId);
    await _load();
  }

  Future<void> _emptyTrash() async {
    if (_sections.isEmpty && _azkar.isEmpty) return;
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'إفراغ السلة',
      message: 'سيتم حذف جميع العناصر في السلة نهائياً ولا يمكن التراجع.',
      confirmLabel: 'إفراغ السلة',
    );
    if (confirmed != true) return;
    await _trash.emptyTrash();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة المحذوفات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'أقسام (${_sections.length})'),
            Tab(text: 'أذكار (${_azkar.length})'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'إفراغ السلة',
            onPressed: _emptyTrash,
            icon: const Icon(Icons.delete_forever_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _sections.isEmpty
                    ? const EmptyState(
                        icon: Icons.folder_delete_outlined,
                        title: 'لا توجد أقسام محذوفة',
                        subtitle: 'الأقسام المحذوفة تظهر هنا لمدة ٣٠ يوماً',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _sections.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final entry = _sections[index];
                          return _TrashCard(
                            title: entry.section.name,
                            subtitle:
                                '${entry.section.azkar.length} ذكر • ${_relativeTime(entry.deletedAt)}',
                            onRestore: () => _restoreSection(entry),
                            onDeleteForever: () => _deleteSectionForever(entry),
                          );
                        },
                      ),
                _azkar.isEmpty
                    ? const EmptyState(
                        icon: Icons.delete_outline,
                        title: 'لا توجد أذكار محذوفة',
                        subtitle: 'الأذكار المحذوفة تظهر هنا لمدة ٣٠ يوماً',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _azkar.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final entry = _azkar[index];
                          return _TrashCard(
                            title: entry.zekr.title,
                            subtitle:
                                'من "${entry.sectionName}" • ${_relativeTime(entry.deletedAt)}',
                            onRestore: () => _restoreZekr(entry),
                            onDeleteForever: () => _deleteZekrForever(entry),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}

class _TrashCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  const _TrashCard({
    required this.title,
    required this.subtitle,
    required this.onRestore,
    required this.onDeleteForever,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDeleteForever,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    icon: const Icon(Icons.delete_forever_outlined, size: 18),
                    label: const Text('حذف نهائي'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('استعادة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
