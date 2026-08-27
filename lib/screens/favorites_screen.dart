import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/section.dart';
import '../models/zekr.dart';
import '../services/stats_service.dart';
import '../services/storage_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/zekr_card.dart';

class FavoritesScreen extends StatefulWidget {
  final AppSettings settings;

  const FavoritesScreen({super.key, required this.settings});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _storage = StorageService.instance;
  List<({Section section, Zekr zekr})> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favorites = await _storage.loadFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite(Section section, Zekr zekr) async {
    await _storage.toggleFavorite(sectionId: section.id, zekrId: zekr.id);
    await _load();
  }

  Future<void> _decrement(Section section, Zekr zekr) async {
    if (zekr.isCompleted) return;
    zekr.decrement();
    await _storage.updateZekr(sectionId: section.id, zekr: zekr);
    await StatsService.instance.recordCompletion(
      sectionId: section.id,
      sectionName: section.name,
      zekrId: zekr.id,
      zekrTitle: zekr.title,
    );
    if (mounted) setState(() {});
  }

  Future<void> _increment(Section section, Zekr zekr) async {
    if (zekr.remaining >= zekr.repeat) return;
    zekr.increment();
    await _storage.updateZekr(sectionId: section.id, zekr: zekr);
    if (mounted) setState(() {});
  }

  Future<void> _resetCounter(Section section, Zekr zekr) async {
    zekr.resetCounter();
    await _storage.updateZekr(sectionId: section.id, zekr: zekr);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const EmptyState(
                  icon: Icons.star_outline_rounded,
                  title: 'لا توجد أذكار مفضلة',
                  subtitle: 'اضغط على أيقونة النجمة داخل أي ذكر لإضافته هنا',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    itemCount: _favorites.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final entry = _favorites[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 4, bottom: 6),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                entry.section.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                              ),
                            ),
                          ),
                          ZekrCard(
                            zekr: entry.zekr,
                            fontSize: widget.settings.fontSize,
                            textAlign: widget.settings.textAlign,
                            onTap: () => _decrement(entry.section, entry.zekr),
                            onLongPress: () =>
                                _increment(entry.section, entry.zekr),
                            onEdit: () {},
                            onDelete: () {},
                            onReset: () => _resetCounter(
                                entry.section, entry.zekr),
                            onMove: () {},
                            onToggleFavorite: () =>
                                _toggleFavorite(entry.section, entry.zekr),
                            allowEditMoveDelete: false,
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}
