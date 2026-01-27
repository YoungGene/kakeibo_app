import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _categoryCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  int selectedIndex = 0; // 0: 支出, 1: 収入
  int selectedCategoryIndex = 0;

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
    _categoryCtrl.dispose();
    _detailCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ===============================
  // 日付選択
  // ===============================
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

  // ===============================
  // 保存処理
  // ===============================
  Future<void> _save() async {
    final amount = int.tryParse(_amountCtrl.text);
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('金額を正しく入力してください')));
      return;
    }

    final date =
        _dateCtrl.text.isEmpty
            ? DateFormat('yyyy-MM-dd').format(DateTime.now())
            : _dateCtrl.text;

    final tx = Tx(
      date: date,
      type: selectedIndex == 0 ? TxType.expense : TxType.income,
      amount: amount,
      category: currentCategories[selectedCategoryIndex],
      note: _categoryCtrl.text,
      detail: _detailCtrl.text.isEmpty ? null : _detailCtrl.text,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await KakeiboDb.instance.insertTransaction(tx.toRow());

    if (!mounted) return;

    // ★ ここが重要
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is DateTime && _dateCtrl.text.isEmpty) {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(arg);
    }
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
            /// 支出 / 収入
            ToggleButtons(
              isSelected: selected,
              onPressed: (i) {
                setState(() {
                  selectedIndex = i;
                  selectedCategoryIndex = 0;
                  _categoryCtrl.clear();
                });
              },
              children: const [
                Padding(padding: EdgeInsets.all(8), child: Text('支出')),
                Padding(padding: EdgeInsets.all(8), child: Text('収入')),
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

            /// カテゴリ表示
            TextField(
              controller: _categoryCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// 詳細
            TextField(
              controller: _detailCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '詳細（任意）',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// 金額
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                final isSelected = selectedCategoryIndex == index;

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedCategoryIndex = index;
                      _categoryCtrl.text = label;
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
                        color: isSelected ? baseColor : Colors.grey,
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
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
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
