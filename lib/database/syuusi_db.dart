import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class KakeiboDb {
  static final KakeiboDb instance = KakeiboDb._();
  KakeiboDb._();

  static const _dbName = 'kakeibo.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,              -- yyyy-MM-dd
            type INTEGER NOT NULL,           -- 0: expense, 1: income
            amount INTEGER NOT NULL,
            category TEXT NOT NULL,
            note TEXT,
            created_at INTEGER NOT NULL      -- unix ms
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date)',
        );
      },
    );

    return _db!;
  }

  Future<int> insertTransaction(Map<String, Object?> row) async {
    final db = await database;
    return db.insert('transactions', row);
  }

  Future<List<Map<String, Object?>>> fetchByDate(String dateKey) async {
    final db = await database;
    return db.query(
      'transactions',
      where: 'date = ?',
      whereArgs: [dateKey],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> deleteById(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> fetchByMonth(int year, int month) async {
    final db = await instance.database;

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    return await db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        start.toIso8601String().substring(0, 10),
        end.toIso8601String().substring(0, 10),
      ],
    );
  }
}
