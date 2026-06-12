// lib/database/database_helper.dart
//
// Uses conditional imports so sqflite is NEVER compiled into the web bundle.
// On native → storage_native.dart (sqflite)
// On web    → storage_web.dart    (shared_preferences JSON)

import '../models/note_model.dart';
import 'note_storage.dart';
import 'storage_native.dart'
    if (dart.library.js_interop) 'storage_web.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  factory DatabaseHelper() => instance;

  final NoteStorage _storage = createStorage();

  Future<int> insertNote(Note note) => _storage.insert(note);
  Future<List<Note>> getAllNotes() => _storage.getAll();
  Future<List<Note>> searchNotes(String query) => _storage.search(query);
  Future<int> updateNote(Note note) => _storage.update(note);
  Future<int> deleteNote(int id) => _storage.delete(id);
  Future<void> close() => _storage.close();
}