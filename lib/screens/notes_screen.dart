import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final saved = await LocalStorageService.loadNotes();
      setState(() {
        _notes = saved.map((e) => Note.fromJson(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to load notes: $e')),
        );
      }
    }
  }

  Future<void> _saveNotes() async {
    await LocalStorageService.saveNotes(
        _notes.map((e) => e.toJson()).toList());
  }

  void _addNote() {
    String title = '';
    String content = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Note',
              style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              style: const TextStyle(color: AppTheme.white),
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (v) => title = v,
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: AppTheme.white),
              decoration: const InputDecoration(labelText: 'Note Content'),
              maxLines: 3,
              onChanged: (v) => content = v,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (title.isEmpty) return;

                  final note = Note(
                    id: 'N-${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    content: content,
                    createdAt: DateTime.now(),
                  );

                  Navigator.pop(ctx);

                  try {
                    setState(() => _notes.add(note));
                    await _saveNotes();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Note saved!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ Failed to save note: $e')),
                      );
                    }
                  }
                },
                child: const Text('SAVE NOTE'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote(int index) async {
    try {
      setState(() => _notes.removeAt(index));
      await _saveNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Note deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to delete note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('My Notes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? _emptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return GestureDetector(
                      onLongPress: () async {
                        // Confirm before deleting
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.surfaceElevated,
                            title: const Text(
                              'Delete Note?',
                              style: TextStyle(color: AppTheme.white),
                            ),
                            content: Text(
                              'Delete "${note.title}"?',
                              style: const TextStyle(
                                  color: AppTheme.whiteSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  'Delete',
                                  style:
                                      TextStyle(color: AppTheme.danger),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) _deleteNote(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                note.content,
                                style: const TextStyle(
                                    color: AppTheme.whiteSecondary,
                                    fontSize: 13),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                              style: const TextStyle(
                                  color: AppTheme.whiteTertiary,
                                  fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.sticky_note_2_rounded, color: Colors.white),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_alt_rounded,
                size: 80, color: AppTheme.surfaceElevated),
            const SizedBox(height: 16),
            const Text('No notes yet',
                style: TextStyle(color: AppTheme.white, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Long-press a note to delete it.',
                style: TextStyle(color: AppTheme.whiteTertiary)),
          ],
        ),
      );
}
