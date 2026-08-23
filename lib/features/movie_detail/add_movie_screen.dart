import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../models/movie_entry.dart';

/// Manual add-movie flow (Phase 1: works without TMDB). Phase 2 will add
/// search-to-autofill on top of this same form.
class AddMovieScreen extends ConsumerStatefulWidget {
  const AddMovieScreen({super.key});

  @override
  ConsumerState<AddMovieScreen> createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends ConsumerState<AddMovieScreen> {
  final _titleController = TextEditingController();
  final _myTakeController = TextEditingController();
  final _wtfController = TextEditingController();
  DateTime _watchedAt = DateTime.now();
  double _rating = 7.5;

  @override
  void dispose() {
    _titleController.dispose();
    _myTakeController.dispose();
    _wtfController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    final now = DateTime.now();
    final entry = MovieEntry(
      title: _titleController.text.trim(),
      myTake: _myTakeController.text.trim().isEmpty ? null : _myTakeController.text.trim(),
      wtfMoment: _wtfController.text.trim().isEmpty ? null : _wtfController.text.trim(),
      rating: _rating,
      watchedAt: _watchedAt,
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(movieRepositoryProvider).addEntry(entry);
    ref.invalidate(movieEntriesProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title'),
            const SizedBox(height: 6),
            TextField(controller: _titleController),
            const SizedBox(height: 16),
            const Text('Rating'),
            Slider(
              value: _rating,
              min: 0,
              max: 10,
              divisions: 20,
              label: _rating.toStringAsFixed(1),
              activeColor: AppColors.accent,
              onChanged: (v) => setState(() => _rating = v),
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
