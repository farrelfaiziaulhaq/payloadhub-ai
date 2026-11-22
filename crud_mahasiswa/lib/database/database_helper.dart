import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/mahasiswa.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final opened = await openDatabase(
      join(dbPath, 'mahasiswa.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE mahasiswa (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nim TEXT NOT NULL UNIQUE,
            nama TEXT NOT NULL,
            prodi TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_mahasiswa_nama ON mahasiswa(nama)');
      },
    );
    _database = opened;
    return opened;
  }

  Future<int> insertMahasiswa(Mahasiswa mahasiswa) async {
    final db = await database;
    return db.insert('mahasiswa', mahasiswa.toMap());
  }

  Future<List<Mahasiswa>> getMahasiswa() async {
    final db = await database;
    final rows = await db.query('mahasiswa', orderBy: 'id DESC');
    return rows.map(Mahasiswa.fromMap).toList(growable: false);
  }

  Future<int> updateMahasiswa(Mahasiswa mahasiswa) async {
    final id = mahasiswa.id;
    if (id == null) {
      throw ArgumentError('Mahasiswa.id wajib ada untuk update.');
    }
    final db = await database;
    return db.update(
      'mahasiswa',
      mahasiswa.toMap(),
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<int> deleteMahasiswa(int id) async {
    final db = await database;
    return db.delete('mahasiswa', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }
}
