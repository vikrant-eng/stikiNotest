// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/note_model.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar_widget.dart';
import 'add_edit_note_screen.dart';
import 'locked_note_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper.instance;

  List<Note> _allNotes = [];
  List<Note> _filtered = [];
  String _searchQuery = '';
  bool _loading = true;

  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _loadNotes();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  Future<void> _loadNotes() async {
    setState(() => _loading = true);
    final notes = await _db.getAllNotes();
    if (mounted) {
      setState(() {
        _allNotes = notes;
        _applySearch(_searchQuery);
        _loading = false;
      });
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filtered = List.from(_allNotes);
      } else {
        final q = query.toLowerCase();
        _filtered = _allNotes.where((n) {
          return n.title.toLowerCase().contains(q) ||
              n.content.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _openNote(Note note) async {
    if (note.isProtected) {
      await Navigator.of(context).push(
        _slideRoute(LockedNoteScreen(note: note)),
      );
    } else {
      await Navigator.of(context).push(
        _slideRoute(
            AddEditNoteScreen(note: note, dbHelper: _db)),
      );
    }
    _loadNotes();
  }

  Future<void> _createNote() async {
    _fabController.reset();
    await Navigator.of(context).push(
      _slideRoute(AddEditNoteScreen(dbHelper: _db)),
    );
    _fabController.forward();
    _loadNotes();
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Delete Note?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete'
          ' "${note.title.isEmpty ? 'this note' : note.title}"?'
          '\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && note.id != null) {
      await _db.deleteNote(note.id!);
      _loadNotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Note deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    }
  }

  // ── Grid column count based on width ──────────────────────────────────────

  int _columnCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    if (width >= 400) return 2;
    return 2;
  }

  // ── Route helper ─────────────────────────────────────────────────────────

  PageRouteBuilder<void> _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, anim, _) => page,
      transitionsBuilder: (_, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.sticky_note_2_rounded, color: cs.primary),
            const SizedBox(width: 10),
            const Text(
              'Sticky Notes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: false,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            tooltip: widget.isDark ? 'Light mode' : 'Dark mode',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  RotationTransition(
                turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                widget.isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                key: ValueKey(widget.isDark),
              ),
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotes,
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────────────────
            SearchBarWidget(
              onChanged: _applySearch,
              onClear: () => _applySearch(''),
            ),
            // ── Note grid ─────────────────────────────────────────────
            Expanded(child: _buildBody(cs)),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          onPressed: _createNote,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Note'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allNotes.isEmpty) {
      return _emptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'No notes yet',
        subtitle: 'Tap the button below to create your first note!',
        cs: cs,
      );
    }

    if (_filtered.isEmpty && _searchQuery.isNotEmpty) {
      return _emptyState(
        icon: Icons.search_off_rounded,
        title: 'No notes found',
        subtitle: 'Try a different search term.',
        cs: cs,
      );
    }

    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = _columnCount(constraints.maxWidth);
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final note = _filtered[i];
          return NoteCard(
            key: ValueKey(note.id),
            note: note,
            onTap: () => _openNote(note),
            onDelete: () => _deleteNote(note),
          );
        },
      );
    });
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme cs,
  }) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 60, color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}