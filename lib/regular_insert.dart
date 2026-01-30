import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

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

  int selectedIndex = 0; // 0: 支出, 1: 収入
  int selectedCategoryIndex = 0;

  int? startYear;
  int? startMonth;
  int? endYear;
  int? endMonth;

  final List<int> yearList = List.generate(11, (i) => 2020 + i);
  final List<int> monthList = List.generate(12, (i) => i + 1);

  final List<String> expenseCategories = const [
    "食費",
    "家賃",
    "交通費",
    "娯楽",
    "医療",
    "教育",
    "その他",
  ];

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = [selectedIndex == 0, selectedIndex == 1];
    final baseColor = selectedIndex == 0 ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(title: const Text('定期支出・収入設定')),

      floatingActionButton: FloatingActionButton(
        child: const Text('保存'),
        onPressed: () {
          final amount = int.tryParse(_amountCtrl.text);
          final day = int.tryParse(_dayCtrl.text);

          if (amount == null || amount <= 0) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('金額が不正です')));
            return;
          }

          if (day == null || day < 1 || day > 31) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('日（1〜31）を正しく入力してください')),
            );
            return;
          }

          if (startYear == null || startMonth == null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('開始年月を選択してください')));
            return;
          }

          Navigator.pop(context, true);
        },
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            /// 日・開始年・開始月・終了年・終了月（割合指定）
            LayoutBuilder(
              builder: (context, constraints) {
                final yearWidth = constraints.maxWidth * 0.22;
                final monthWidth = constraints.maxWidth * 0.20;

                return Row(
                  children: [
                    /// 日（固定）
                    SizedBox(
                      width: 48,
                      child: TextField(
                        controller: _dayCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: const InputDecoration(
                          labelText: '日',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    /// 開始年
                    SizedBox(
                      width: yearWidth,
                      child: DropdownButtonFormField<int>(
                        value: startYear,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: '開始年',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            yearList
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text('$y'),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => startYear = v),
                      ),
                    ),
                    const SizedBox(width: 4),

                    /// 開始月
                    SizedBox(
                      width: monthWidth,
                      child: DropdownButtonFormField<int>(
                        value: startMonth,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: '月',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            monthList
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text('$m'),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => startMonth = v),
                      ),
                    ),
                    const SizedBox(width: 4),

                    /// 終了年
                    SizedBox(
                      width: yearWidth,
                      child: DropdownButtonFormField<int>(
                        value: endYear,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: '終了年',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            yearList
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text('$y'),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => endYear = v),
                      ),
                    ),
                    const SizedBox(width: 4),

                    /// 終了月
                    SizedBox(
                      width: monthWidth,
                      child: DropdownButtonFormField<int>(
                        value: endMonth,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: '月',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            monthList
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text('$m'),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => endMonth = v),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _categoryCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _detailCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '詳細（任意）',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

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

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainPage(initialIndex: index)),
            (_) => false,
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "ホーム"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "カレンダー",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "レポート"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "メニュー"),
        ],
      ),
    );
  }
}
