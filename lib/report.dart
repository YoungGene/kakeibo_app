import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'database/syuusi_db.dart';
import 'models/transaction.dart';

/// 月別収支を集計して表示する Report 画面
class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  DateTime _selectedMonth = DateTime.now();
  final NumberFormat _yenFormat = NumberFormat('#,###');

  /// ===== 支出 / 収入 トグル =====
  TxType _selectedType = TxType.expense;

  /// ===== カテゴリ別カラー定義 =====
  final Map<String, Color> _categoryColors = {
    '食費': Colors.orange,
    '交通費': Colors.blue,
    '日用品': Colors.green,
    '娯楽': Colors.purple,
    '家賃': Colors.brown,
    '光熱費': Colors.red,
    '通信費': Colors.cyan,
    '医療費': Colors.pink,
    '給料': Colors.teal,
    '副収入': Colors.indigo,
  };

  Color _getCategoryColor(String category, int index) {
    return _categoryColors[category] ?? Colors.grey[(index % 4 + 5) * 100]!;
  }

  /// 指定月の取引を取得
  Future<List<Tx>> _fetchMonthlyTransactions() async {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    return await KakeiboDb.instance.getTransactionsByRange(firstDay, lastDay);
  }

  /// 収入・支出・収支を計算
  Map<String, int> _calcSummary(List<Tx> list) {
    int income = 0;
    int expense = 0;

    for (final t in list) {
      t.type == TxType.income ? income += t.amount : expense += t.amount;
    }

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  /// カテゴリ別合計
  Map<String, int> _sumByCategory(TxType type, List<Tx> list) {
    final Map<String, int> map = {};
    for (final tx in list.where((e) => e.type == type)) {
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    return map;
  }

  /// 月変更
  void _changeMonth(int diff) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + diff,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('レポート')),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildToggle(),
          Expanded(
            child: FutureBuilder<List<Tx>>(
              future: _fetchMonthlyTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('データがありません'));
                }

                final list = snapshot.data!;
                final summary = _calcSummary(list);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard('収入', summary['income']!, Colors.blue),
                    _buildSummaryCard('支出', summary['expense']!, Colors.red),
                    _buildSummaryCard(
                      '収支',
                      summary['balance']!,
                      summary['balance']! >= 0 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 24),

                    /// ===== 選択中タイプの円グラフ =====
                    _buildPieChart(
                      title:
                          _selectedType == TxType.expense
                              ? '支出（カテゴリ別）'
                              : '収入（カテゴリ別）',
                      data: _sumByCategory(_selectedType, list),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ===== 支出 / 収入 トグル =====
  Widget _buildToggle() {
    final selected = [
      _selectedType == TxType.expense,
      _selectedType == TxType.income,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ToggleButtons(
        isSelected: selected,
        onPressed: (index) {
          setState(() {
            _selectedType = index == 0 ? TxType.expense : TxType.income;
          });
        },
        borderRadius: BorderRadius.circular(12),
        selectedColor: Colors.white,
        fillColor: _selectedType == TxType.expense ? Colors.red : Colors.green,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('支出'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('収入'),
          ),
        ],
      ),
    );
  }

  /// 月選択UI
  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            '${_selectedMonth.year}年 ${_selectedMonth.month}月',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  /// 集計カード
  Widget _buildSummaryCard(String title, int value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          '¥${_yenFormat.format(value)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 円グラフ
  Widget _buildPieChart({
    required String title,
    required Map<String, int> data,
  }) {
    if (data.isEmpty) {
      return const Text('データがありません');
    }

    final total = data.values.fold<int>(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              sections:
                  data.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final e = entry.value;
                    final percent = e.value / total * 100;

                    return PieChartSectionData(
                      value: e.value.toDouble(),
                      radius: 75,
                      color: _getCategoryColor(e.key, index),
                      title: '${e.key}\n${percent.toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children:
              data.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final e = entry.value;

                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: _getCategoryColor(e.key, index),
                    radius: 6,
                  ),
                  label: Text('${e.key}：${_yenFormat.format(e.value)}円'),
                );
              }).toList(),
        ),
      ],
    );
  }
}
