import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/movie_entry.dart';
import '../../services/movie_metadata_provider.dart';
import '../../widgets/poster_thumbnail.dart';
import 'tmdb_search_screen.dart';

/// Add/edit movie flow. Works fully offline (Phase 1); Phase 2 layers a
/// TMDB search-to-autofill step on top of the same form.
///
/// Pass [existingEntry] to edit an entry in place instead of creating a
/// new one — the form pre-fills and Save updates rather than inserts.
class AddMovieScreen extends ConsumerStatefulWidget {
  const AddMovieScreen({super.key, this.existingEntry});

  final MovieEntry? existingEntry;

  bool get isEditing => existingEntry != null;

  @override
  ConsumerState<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends ConsumerState<AddMovieScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _myTakeController;
  late final TextEditingController _wtfController;
  late DateTime _watchedAt;
  late double _rating;

  String? _titleError;
  bool _isSaving = false;
  bool _isFetchingDetails = false;

  // TMDB-derived metadata, set by _searchTmdb(). Kept separate from the
  // controllers because these fields (genres, cast, etc.) don't have
  // their own inputs yet — they just ride along to the saved entry.
  int? _tmdbId;
  DateTime? _releaseDate;
  int? _runtimeMinutes;
  String? _overview;
  String? _posterPath;
  List<String> _posterChoices = [];
  List<String> _genres = [];
  String? _director;
  List<String> _cast = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEntry;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _myTakeController = TextEditingController(text: existing?.myTake ?? '');
    _wtfController = TextEditingController(text: existing?.wtfMoment ?? '');
    _watchedAt = existing?.watchedAt ?? DateTime.now();
    _rating = existing?.rating ?? 7.5;

    _tmdbId = existing?.tmdbId;
    _releaseDate = existing?.releaseDate;
    _runtimeMinutes = existing?.runtimeMinutes;
    _overview = existing?.overview;
    _posterPath = existing?.posterPath;
    _genres = existing?.genres ?? [];
    _director = existing?.director;
    _cast = existing?.cast ?? [];
  }

  Future<void> _searchTmdb() async {
    final result = await Navigator.of(context).push<MovieSearchResult>(
      MaterialPageRoute(builder: (_) => const TmdbSearchScreen()),
    );
    if (result == null || !mounted) return;

    setState(() => _isFetchingDetails = true);
    try {
      final details =
          await ref.read(movieDetailsProvider(result.externalId).future);
      if (!mounted) return;
      setState(() {
        _titleController.text = details.title;
        _tmdbId = details.externalId;
        _releaseDate = details.releaseDate;
        _runtimeMinutes = details.runtimeMinutes;
        _overview = details.overview;
        _genres = details.genres;
        _director = details.director;
        _cast = details.cast;
        _posterChoices = details.posterPaths.take(8).toList();
        _posterPath = _posterChoices.isNotEmpty
            ? _posterChoices.first
            : result.posterPath;
        _titleError = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch details: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingDetails = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _myTakeController.dispose();
    _wtfController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _watchedAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.accent,
                surface: AppColors.surfaceElevated,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _watchedAt = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title is required');
      return;
    }
    setState(() {
      _titleError = null;
      _isSaving = true;
    });

    final now = DateTime.now();
    final existing = widget.existingEntry;

    // In add mode, _posterPath is a raw TMDB-relative path (needed to
    // build thumbnail URLs at multiple sizes for the picker above) — it
    // must become a full URL before it's persisted, since every other
    // screen treats MovieEntry.posterPath as a ready-to-render URL. In
    // edit mode _posterPath already came from the stored full URL and
    // is left untouched (poster editing isn't wired up here yet).
    final posterPathToSave = widget.isEditing || _posterPath == null
        ? _posterPath
        : ref.read(movieMetadataProvider).imageUrl(_posterPath!, size: 'w500');

    try {
      final entry = (existing ??
              MovieEntry(
                title: title,
                watchedAt: _watchedAt,
                createdAt: now,
                updatedAt: now,
              ))
          .copyWith(
        title: title,
        myTake: _myTakeController.text.trim().isEmpty
            ? null
            : _myTakeController.text.trim(),
        wtfMoment: _wtfController.text.trim().isEmpty
            ? null
            : _wtfController.text.trim(),
        rating: _rating,
        watchedAt: _watchedAt,
        updatedAt: now,
        tmdbId: _tmdbId,
        releaseDate: _releaseDate,
        runtimeMinutes: _runtimeMinutes,
        overview: _overview,
        posterPath: posterPathToSave,
        genres: _genres,
        director: _director,
        cast: _cast,
      );

      final repo = ref.read(movieRepositoryProvider);
      if (widget.isEditing) {
        await repo.updateEntry(entry);
        ref.invalidate(movieEntryProvider(entry.id!));
      } else {
        await repo.addEntry(entry);
      }
      ref.invalidate(movieEntriesProvider);
      ref.invalidate(entriesByWeekProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final entry = widget.existingEntry;
    if (entry?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete this entry?'),
        content: Text(
            'This removes "${entry!.title}" from your diary. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(movieRepositoryProvider).deleteEntry(entry!.id!);
      ref.invalidate(movieEntriesProvider);
      ref.invalidate(entriesByWeekProvider);
      if (mounted) {
        Navigator.of(context).pop(); // close the edit screen
        // If we were pushed on top of the detail screen, pop once more
        // so the (now-deleted) detail screen isn't left showing.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Movie' : 'Add Movie'),
        leading: const CloseButton(),
        actions: [
          if (!widget.isEditing)
            IconButton(
              icon: _isFetchingDetails
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.search),
              tooltip: 'Search TMDB',
              onPressed: _isFetchingDetails ? null : _searchTmdb,
            ),
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _isSaving ? null : _confirmDelete,
            ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isEditing && _posterPath == null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isFetchingDetails ? null : _searchTmdb,
                icon: const Icon(Icons.search),
                label: const Text('Search TMDB to autofill'),
              ),
              const SizedBox(height: 16),
            ],
            if (_posterPath != null) ...[
              const SizedBox(height: 12),
              Center(
                child: PosterThumbnail(
                  imageUrl: widget.isEditing
                      ? widget.existingEntry!.effectivePosterPath
                      : ref.read(movieMetadataProvider).imageUrl(_posterPath!),
                  width: 100,
                  height: 145,
                  borderRadius: 10,
                ),
              ),
              if (_posterChoices.length > 1) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _posterChoices.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final path = _posterChoices[index];
                      final selected = path == _posterPath;
                      return GestureDetector(
                        onTap: () => setState(() => _posterPath = path),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? AppColors.accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: PosterThumbnail(
                            imageUrl: ref
                                .read(movieMetadataProvider)
                                .imageUrl(path, size: 'w185'),
                            width: 44,
                            height: 60,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
            const Text('Title'),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(errorText: _titleError),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: 16),
            const Text('Date Watched'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceInput,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(_watchedAt)),
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rating'),
            const SizedBox(height: 6),
            Row(
              children: [
                RatingBar.builder(
                  initialRating: _rating / 2,
                  minRating: 0,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 32,
                  glowColor: AppColors.accent,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                  itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: AppColors.star),
                  unratedColor: AppColors.starEmpty,
                  onRatingUpdate: (value) =>
                      setState(() => _rating = value * 2),
                ),
                const SizedBox(width: 12),
                Text('${_rating.toStringAsFixed(1)}/10',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('What I took from it'),
            const SizedBox(height: 6),
            TextField(controller: _myTakeController, maxLines: 3),
            const SizedBox(height: 16),
            const Text('One memorable WTF moment'),
            const SizedBox(height: 6),
            TextField(controller: _wtfController, maxLines: 3),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
