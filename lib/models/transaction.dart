enum TxType { expense, income }

class Tx {
  final int? id;
  final String date; // yyyy-MM-dd
  final TxType type; // 支出 / 収入
  final int amount; // 金額（int）
  final String category; // カテゴリ
  final String? note; // カテゴリ表示用 or メモ
  final String? detail; // ★ 詳細（自由記述）
  final int createdAt; // 作成日時（epoch ms）

  const Tx({
    this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    this.detail, // ★ 追加
    required this.createdAt,
  });

  /// DB保存用
  Map<String, Object?> toRow() => {
    'id': id,
    'date': date,
    'type': type == TxType.expense ? 0 : 1,
    'amount': amount,
    'category': category,
    'note': note,
    'detail': detail, // ★ 追加
    'created_at': createdAt,
  };

  /// DB取得用
  static Tx fromRow(Map<String, Object?> row) {
    return Tx(
      id: row['id'] as int?,
      date: row['date'] as String,
      type: (row['type'] as int) == 0 ? TxType.expense : TxType.income,
      amount: row['amount'] as int,
      category: row['category'] as String,
      note: row['note'] as String?,
      detail: row['detail'] as String?, // ★ 追加
      createdAt: row['created_at'] as int,
    );
  }
}
