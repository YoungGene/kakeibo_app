import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/syuusi_db.dart';
import 'models/transaction.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _dateCtrl = TextEditingController(); // 例: 2025-12-31
  final _memoCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  int selectedIndex = 0; // 0:支出, 1:収入
  int selectedIndexC = 0; // カテゴリindex

  // build内ローカルだと_saveから参照できないのでフィールドにする
  final List<String> buttonLabels = const [
    "食費",
    "家賃",
    "交通",
    "娯楽",
    "医療",
    "教育",
    "貯金",
    "投資",
    "その他",
  ];

  @override
  void dispose() {
    _dateCtrl.dispose();
    _memoCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // 収支タイプ
    final type = (selectedIndex == 0) ? TxType.expense : TxType.income;

    // 日付
    final dateText = _dateCtrl.text.trim();
    final dateKey = dateText.isEmpty
        ? DateFormat('yyyy-MM-dd').format(DateTime.now())
        : dateText; // yyyy-MM-dd を手入力する想定

    // 金額
    final amount = int.tryParse(_amountCtrl.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('金額を正しく入力してください')),
      );
      return;
    }

    // カテゴリ（ボタンから）
    final category = buttonLabels[selectedIndexC];

    // メモ
    final memo = _memoCtrl.text.trim();
    final note = memo.isEmpty ? null : memo;

    final tx = Tx(
      date: dateKey,
      type: type,
      amount: amount,
      category: category,
      note: note,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await KakeiboDb.instance.insertTransaction(tx.toRow());

    // 入力欄クリア（好みで）
    _memoCtrl.clear();
    _amountCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('保存しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = [selectedIndex == 0, selectedIndex == 1];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      // Scaffoldのプロパティとして置く（Columnの中はNG）
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // トグルボタン行
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: selected,
                  children: const [Text("支出"), Text("収入")],
                  onPressed: (int index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _dateCtrl,
              decoration: const InputDecoration(
                labelText: '日付（yyyy-MM-dd）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _memoCtrl,
              decoration: const InputDecoration(
                labelText: 'メモ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: '金額',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),

            // 3x3カテゴリ（ToggleButtonsを1個ずつ置くより、見た目を保ったまま単純にする）
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: List.generate(buttonLabels.length, (index) {
                final isOn = selectedIndexC == index;
                return ToggleButtons(
                  isSelected: [isOn],
                  onPressed: (_) {
                    setState(() {
                      selectedIndexC = index;
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Center(child: Text(buttonLabels[index])),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
