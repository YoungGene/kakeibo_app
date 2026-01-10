import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← ★これを追加
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
  final _dateCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  int selectedIndex = 0; // 0:支出, 1:収入
  int selectedIndexC = 0;

  /// 支出カテゴリ
  final List<String> expenseCategories = const [
    "食費",
    "家賃",
    "交通",
    "娯楽",
    "医療",
    "教育",
    "その他",
  ];

  /// 収入カテゴリ
  final List<String> incomeCategories = const [
    "給料",
    "副収入",
    "投資",
    "臨時収入",
    "その他",
  ];

  final Map<String, IconData> categoryIcons = const {
    "食費": Icons.fastfood,
    "家賃": Icons.home,
    "交通": Icons.directions_train,
    "娯楽": Icons.sports_esports,
    "医療": Icons.local_hospital,
    "教育": Icons.school,
    "給料": Icons.payments,
    "副収入": Icons.work,
    "投資": Icons.trending_up,
    "臨時収入": Icons.card_giftcard,
    "その他": Icons.category,
  };

  List<String> get currentCategories =>
      selectedIndex == 0 ? expenseCategories : incomeCategories;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _memoCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _save() async {
    final type = (selectedIndex == 0) ? TxType.expense : TxType.income;

    final dateKey =
        _dateCtrl.text.isEmpty
            ? DateFormat('yyyy-MM-dd').format(DateTime.now())
            : _dateCtrl.text;

    final amount = int.tryParse(_amountCtrl.text);
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('金額を正しく入力してください')));
      return;
    }

    final category = currentCategories[selectedIndexC];
    final note = _memoCtrl.text.trim();

    final tx = Tx(
      date: dateKey,
      type: type,
      amount: amount,
      category: category,
      note: note.isEmpty ? null : note,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await KakeiboDb.instance.insertTransaction(tx.toRow());

    _amountCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('保存しました')));
  }

  @override
  Widget build(BuildContext context) {
    final selected = [selectedIndex == 0, selectedIndex == 1];
    final baseColor = selectedIndex == 0 ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 支出 / 収入 トグル
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: selected,
                  children: const [Text("支出"), Text("収入")],
                  onPressed: (int index) {
                    setState(() {
                      selectedIndex = index;
                      selectedIndexC = 0;
                      _memoCtrl.clear();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 日付
            TextField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: '日付',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),

            const SizedBox(height: 12),

            /// 選択カテゴリ
            TextField(
              controller: _memoCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: '選択したカテゴリ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// 💰 金額（数字のみ）
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // ← ここが重要
              ],
              decoration: const InputDecoration(
                labelText: '金額',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            /// カテゴリグリッド
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: List.generate(currentCategories.length, (index) {
                final label = currentCategories[index];
                final isSelected = selectedIndexC == index;

                return AspectRatio(
                  aspectRatio: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        selectedIndexC = index;
                        _memoCtrl.text = label;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? baseColor.withOpacity(0.85)
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? baseColor : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            categoryIcons[label],
                            size: 36,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
