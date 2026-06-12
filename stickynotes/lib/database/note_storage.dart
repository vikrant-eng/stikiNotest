// lib/database/note_storage.dart
import '../models/note_model.dart';

abstract class NoteStorage {
  Future<int> insert(Note note);
  Future<List<Note>> getAll();
  Future<List<Note>> search(String query);
  Future<int> update(Note note);
  Future<int> delete(int id);
  Future<void> close();
}
