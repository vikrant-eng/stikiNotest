// lib/database/storage_native.dart  (Android / iOS / Desktop — sqflite)
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';
import 'note_storage.dart';

// Factory function called via conditional import
NoteStorage createStorage() => _SqliteStorage();

class _SqliteStorage implements NoteStorage {
  static const _dbName = 'sticky_notes.db';
  static const _dbVersion = 2;
  static const _table = 'notes';

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE $_table (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          title        TEXT,
          content      TEXT,
          color        INTEGER,
          createdAt    TEXT,
          isProtected  INTEGER,
          pinCode      TEXT,
          useBiometric INTEGER DEFAULT 0
        )
      '''),
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          await db.execute(
              'ALTER TABLE $_table ADD COLUMN useBiometric INTEGER DEFAULT 0');
        }
      },
    );
  }

  @override
  Future<int> insert(Note note) async {
    final db = await _database;
    return db.insert(_table, note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<Note>> getAll() async {
    final db = await _database;
    final maps = await db.query(_table, orderBy: 'id DESC');
    return maps.map(Note.fromMap).toList();
  }

  @override
  Future<List<Note>> search(String query) async {
    final db = await _database;
    final maps = await db.query(
      _table,
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'id DESC',
    );
    return maps.map(Note.fromMap).toList();
  }

  @override
  Future<int> update(Note note) async {
    final db = await _database;
    return db.update(_table, note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
  }

  @override
  Future<int> delete(int id) async {
    final db = await _database;
    return db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
