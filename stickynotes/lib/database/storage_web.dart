// lib/database/storage_web.dart  (Web — shared_preferences JSON store)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import 'note_storage.dart';

// Factory function called via conditional import
NoteStorage createStorage() => _WebStorage();

class _WebStorage implements NoteStorage {
  static const _key = 'sticky_notes_v1';

  Future<List<Note>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Note.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _save(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(notes.map((n) => n.toMap()).toList()));
  }

  int _nextId(List<Note> notes) {
    if (notes.isEmpty) return 1;
    return notes.map((n) => n.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  Future<int> insert(Note note) async {
    final notes = await _load();
    final id = _nextId(notes);
    notes.insert(
      0,
      Note(
        id: id,
        title: note.title,
        content: note.content,
        color: note.color,
        createdAt: note.createdAt,
        isProtected: note.isProtected,
        pinCode: note.pinCode,
        useBiometric: note.useBiometric,
      ),
    );
    await _save(notes);
    return id;
  }

  @override
  Future<List<Note>> getAll() => _load();

  @override
  Future<List<Note>> search(String query) async {
    final q = query.toLowerCase();
    return (await _load())
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<int> update(Note note) async {
    final notes = await _load();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx == -1) return 0;
    notes[idx] = note;
    await _save(notes);
    return 1;
  }

  @override
  Future<int> delete(int id) async {
    final notes = await _load();
    final updated = notes.where((n) => n.id != id).toList();
    await _save(updated);
    return notes.length - updated.length;
  }

  @override
  Future<void> close() async {}
}
