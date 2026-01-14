enum TxType { expense, income }

class Tx {
  final int? id;
  final String date;
  final TxType type;
  final int amount;
  final String category;
  final String? note;
  final int createdAt;

  const Tx({
    this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.createdAt,
  });

  Map<String, Object?> toRow() => {
    'id': id,
    'date': date,
    'type': type == TxType.expense ? 0 : 1,
    'amount': amount,
    'category': category,
    'note': note,
    'created_at': createdAt,
  };

  static Tx fromRow(Map<String, Object?> row) {
    return Tx(
      id: row['id'] as int?,
      date: row['date'] as String,
      type: (row['type'] as int) == 0 ? TxType.expense : TxType.income,
      amount: row['amount'] as int,
      category: row['category'] as String,
      note: row['note'] as String?,
      createdAt: row['created_at'] as int,
    );
  }
}
