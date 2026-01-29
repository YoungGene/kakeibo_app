import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum RegularCycle { weekly, monthly, yearly }

class RegularInsertPage extends StatefulWidget {
  const RegularInsertPage({super.key});

  @override
  State<RegularInsertPage> createState() => _RegularInsertPageState();
}

class _RegularInsertPageState extends State<RegularInsertPage> {
  final _categoryCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dayCtrl = TextEditingController();
  final _startYmCtrl = TextEditingController();
  final _endYmCtrl = TextEditingController();

  int selectedIndex = 0; // 0: 支出, 1: 収入
  int selectedCategoryIndex = 0;
  RegularCycle cycle = RegularCycle.monthly;

  /// 支出カテゴリ
  final List<String> expenseCategories = const [
    "食費",
    "家賃",
    "交通費",
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
    "交通費": Icons.directions_train,
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
    _categoryCtrl.dispose();
    _detailCtrl.dispose();
    _amountCtrl.dispose();
    _dayCtrl.dispose();
    _startYmCtrl.dispose();
    _endYmCtrl.dispose();
    super.dispose();
  }

  /// 年月選択
  Future<void> _pickYearMonth(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '年月を選択',
    );

    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
    }
  }

  String get dayLabel {
    switch (cycle) {
      case RegularCycle.weekly:
        return '曜日（1=月〜7=日）';
      case RegularCycle.yearly:
        return '月（1〜12）';
      case RegularCycle.monthly:
      default:
        return '日（1〜31）';
    }
  }

  int get dayMax {
    switch (cycle) {
      case RegularCycle.weekly:
        return 7;
      case RegularCycle.yearly:
        return 12;
      case RegularCycle.monthly:
      default:
        return 31;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = [selectedIndex == 0, selectedIndex == 1];
    final baseColor = selectedIndex == 0 ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(title: const Text('定期支出・収入設定')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final amount = int.tryParse(_amountCtrl.text);
          final day = int.tryParse(_dayCtrl.text);

          if (amount == null || amount <= 0) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('金額が不正です')));
            return;
          }

          if (day == null || day < 1 || day > dayMax) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$dayLabel を正しく入力してください')));
            return;
          }

          if (_startYmCtrl.text.isEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('開始年月を入力してください')));
            return;
          }

          // TODO: 定期DB保存
          // cycle, type, category, detail, amount, day, startYm, endYm

          Navigator.pop(context, true);
        },
        child: const Text('保存'),
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
                  _categoryCtrl.text = currentCategories[0];
                });
              },
              children: const [
                Padding(padding: EdgeInsets.all(8), child: Text('支出')),
                Padding(padding: EdgeInsets.all(8), child: Text('収入')),
              ],
            ),

            const SizedBox(height: 16),

            /// 周期トグル
            ToggleButtons(
              isSelected: [
                cycle == RegularCycle.weekly,
                cycle == RegularCycle.monthly,
                cycle == RegularCycle.yearly,
              ],
              onPressed: (i) {
                setState(() {
                  cycle = RegularCycle.values[i];
                  _dayCtrl.clear();
                });
              },
              children: const [
                Padding(padding: EdgeInsets.all(8), child: Text('週次')),
                Padding(padding: EdgeInsets.all(8), child: Text('月次')),
                Padding(padding: EdgeInsets.all(8), child: Text('年次')),
              ],
            ),

            const SizedBox(height: 16),

            /// 日付・開始・終了（横並び）
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dayCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      labelText: dayLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _startYmCtrl,
                    readOnly: true,
                    onTap: () => _pickYearMonth(_startYmCtrl),
                    decoration: const InputDecoration(
                      labelText: '開始年月',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _endYmCtrl,
                    readOnly: true,
                    onTap: () => _pickYearMonth(_endYmCtrl),
                    decoration: const InputDecoration(
                      labelText: '終了年月',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// カテゴリ
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
