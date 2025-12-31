import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'insert.dart';
import '../database/syuusi_db.dart';
import '../models/transaction.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _KakeiboCalendarPageState();
}

class _KakeiboCalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  List<Tx> _items = [];

  Future<void> _loadForSelectedDay() async {
    final rows = await KakeiboDb.instance.fetchByDate(_key(_selectedDay));
    setState(() {
      _items = rows.map(Tx.fromRow).toList();
    });
  }

  int get _incomeSum => _items
      .where((e) => e.type == TxType.income)
      .fold(0, (sum, e) => sum + e.amount);

  int get _expenseSum => _items
      .where((e) => e.type == TxType.expense)
      .fold(0, (sum, e) => sum + e.amount);

  @override
  void initState() {
    super.initState();
    _loadForSelectedDay();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy/MM/dd').format(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text("カレンダー"),
      ),
      body: Column(
        children: [
          // 上半分：カレンダー
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TableCalendar(
                locale: 'ja_JP',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _format,
                onFormatChanged: (f) => setState(() => _format = f),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  _loadForSelectedDay();
                },

                // ✅ 簡易：選択中の日だけ「イベントあり」にする（マーカー表示用）
                // 本格的にやるなら「月単位でDBからまとめて取得」する必要あり
                eventLoader: (day) {
                  if (isSameDay(day, _selectedDay) && _items.isNotEmpty) {
                    return _items; // List<Object> として扱われる
                  }
                  return const [];
                },
              ),
            ),
          ),

          const Divider(height: 1),

          // 下半分：その日の収支履歴
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // 日付＋サマリー
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _SummaryChip(label: "収入", value: _incomeSum),
                      const SizedBox(width: 8),
                      _SummaryChip(label: "支出", value: _expenseSum),
                    ],
                  ),
                ),

                Expanded(
                  child: _items.isEmpty
                      ? const Center(child: Text("この日の履歴はありません"))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final tx = _items[i];
                            final isIncome = tx.type == TxType.income;
                            final sign = isIncome ? "+" : "-";

                            // 表示名：DBの note があれば note、なければ category
                            final title = (tx.note != null && tx.note!.trim().isNotEmpty)
                                ? tx.note!.trim()
                                : tx.category;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(title),
                              subtitle: Text(tx.category),
                              leading: Icon(
                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              ),
                              trailing: Text(
                                "$sign${tx.amount}円",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => MyHomePage(title: "追加"), // あなたの追加画面に合わせて
            ),
          );

          if (saved == true) {
            await _loadForSelectedDay(); // ✅ DBから再取得
            setState(() {}); // 念のため
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text("$label: $value円"),
    );
  }
}
