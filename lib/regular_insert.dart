import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';
import 'database/syuusi_db.dart';
import 'models/transaction.dart';

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
  // yyyy-MM-dd 形式の文字列を作るヘルパー
  String _formatDate(int year, int month, int day) {
    // その月の最終日より大きい日付が来たら、月末に丸める
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final d = day > lastDayOfMonth ? lastDayOfMonth : day;

    final mm = month.toString().padLeft(2, '0');
    final dd = d.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }

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

  // ===============================
  // 定期支出・収入の保存処理
  // ===============================
  Future<void> _saveRegular() async {
    // 文字列 → int に変換
    final amountRaw = int.tryParse(_amountCtrl.text);
    final dayRaw = int.tryParse(_dayCtrl.text);

    // 金額チェック
    if (amountRaw == null || amountRaw <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('金額が不正です')));
      return;
    }

    // 日付チェック（1〜31）
    if (dayRaw == null || dayRaw < 1 || dayRaw > 31) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('日（1〜31）を正しく入力してください')));
      return;
    }

    // 開始年月チェック
    if (startYear == null || startMonth == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('開始年月を選択してください')));
      return;
    }

    // ここから下では non-null な変数として使う
    final int amount = amountRaw;
    final int day = dayRaw;

    // 開始・終了の年月を決定（終了が未入力なら開始と同じ月だけ登録）
    final sy = startYear!;
    final sm = startMonth!;
    var ey = endYear ?? sy;
    var em = endMonth ?? sm;

    // 終了が開始より前になっていた場合は、開始と同じに揃える
    if (ey < sy || (ey == sy && em < sm)) {
      ey = sy;
      em = sm;
    }

    // created_at 用のベース時間
    final baseTime = DateTime.now().millisecondsSinceEpoch;
    var seq = 0;

    var y = sy;
    var m = sm;

    // sy-sm 〜 ey-em まで、1ヶ月ずつ進めながら insert
    while (true) {
      final dateStr = _formatDate(y, m, day);

      final tx = Tx(
        date: dateStr,
        type: selectedIndex == 0 ? TxType.expense : TxType.income,
        amount: amount,
        category: currentCategories[selectedCategoryIndex],
        note: _categoryCtrl.text,
        detail: _detailCtrl.text.isEmpty ? null : _detailCtrl.text,
        // created_at は PRIMARY KEY なので、重複しないように +seq しておく
        createdAt: baseTime + seq,
      );

      await KakeiboDb.instance.insertTransaction(tx.toRow());
      print('これでじっこうできてるはずなんだけどなあ... ${tx.date} / ${tx.amount}');
      seq++;

      // 終了年月に到達したら終了
      if (y == ey && m == em) break;

      // 月を1つ進める
      m++;
      if (m == 13) {
        m = 1;
        y++;
      }
    }

    if (!mounted) return;

    // insert.dart と同じように true を返して画面を閉じる
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final selected = [selectedIndex == 0, selectedIndex == 1];
    final baseColor = selectedIndex == 0 ? Colors.red : Colors.green;

    const densePadding = EdgeInsets.symmetric(vertical: 12, horizontal: 8);

    return Scaffold(
      appBar: AppBar(title: const Text('定期支出・収入設定')),

      floatingActionButton: FloatingActionButton(
        child: const Text('保存'),
        onPressed: _saveRegular,
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

            /// 日・開始年・開始月・終了年・終了月
            LayoutBuilder(
              builder: (context, constraints) {
                final yearWidth = constraints.maxWidth * 0.22;
                final monthWidth = constraints.maxWidth * 0.20;

                return Row(
                  children: [
                    /// 日（高さ調整済み）
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
                          contentPadding: densePadding,
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
                          contentPadding: densePadding,
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
                          contentPadding: densePadding,
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
                          contentPadding: densePadding,
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
                          contentPadding: densePadding,
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
