import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/transaction.dart';

class KakeiboDb {
  static final KakeiboDb instance = KakeiboDb._();
  KakeiboDb._();

  static const _dbName = 'kakeibo.db';
  static const _dbVersion = 1;

  Database? _db;

  // ===============================
  // DB取得
  // ===============================
  Future<Database> get database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
      CREATE TABLE transactions (
        date TEXT,
        type INTEGER,
        amount INTEGER,
        category TEXT,
        note TEXT,
        detail TEXT,
        created_at INTEGER PRIMARY KEY
      )
    ''');
        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 → v2 のときに detail カラムを追加
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE transactions ADD COLUMN detail TEXT');
        }
      },
    );

    return _db!;
  }

  // ===============================
  // 追加
  // ===============================
  Future<int> insertTransaction(Map<String, Object?> row) async {
    final db = await database;
    return db.insert('transactions', row);
  }

  // ===============================
  // 日別取得
  // ===============================
  Future<List<Map<String, Object?>>> fetchByDate(String dateKey) async {
    final db = await database;
    return db.query(
      'transactions',
      where: 'date = ?',
      whereArgs: [dateKey],
      orderBy: 'created_at DESC',
    );
  }

  // ===============================
  // 月別取得（カレンダー用）
  // ===============================
  Future<List<Map<String, dynamic>>> fetchByMonth(int year, int month) async {
    final db = await database;

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    return db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [_dateKey(start), _dateKey(end)],
    );
  }

  // ===============================
  // 期間取得（集計・グラフ用）
  // ===============================
  Future<List<Tx>> getTransactionsByRange(DateTime start, DateTime end) async {
    final db = await database;

    final result = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [_dateKey(start), _dateKey(end)],
      orderBy: 'date ASC',
    );

    return result.map((row) => Tx.fromRow(row)).toList();
  }

  // ===============================
  // 削除（ID）
  // ===============================
  Future<int> deleteById(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ===============================
  // ⭐ 削除（created_at）
  // Calendar / Swipe 削除用
  // ===============================
  Future<int> deleteByCreatedAt(int createdAt) async {
    final db = await database;
    return db.delete(
      'transactions',
      where: 'created_at = ?',
      whereArgs: [createdAt],
    );
  }

  // ===============================
  // 日付キー整形
  // ===============================
  String _dateKey(DateTime d) => d.toIso8601String().substring(0, 10);
}
