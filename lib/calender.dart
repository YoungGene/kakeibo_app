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

  final NumberFormat _yenFormat = NumberFormat('#,###');
  static const int highlightThreshold = 1000;

  String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  List<Tx> _items = [];
  int _monthlyBalance = 0;

  /// 日別収支
  final Map<String, int> _dailyBalanceMap = {};

  // ---------- カレンダー用金額短縮 ----------
  String formatCompactYen(int value) {
    final v = value.abs();
    if (v >= 100000000) {
      final n = v / 100000000;
      return n % 1 == 0 ? '${n.toInt()}億' : '${n.toStringAsFixed(1)}億';
    } else if (v >= 10000) {
      final n = v / 10000;
      return n % 1 == 0 ? '${n.toInt()}万' : '${n.toStringAsFixed(1)}万';
    }
    return v.toString();
  }

  // ---------- 日別 ----------
  Future<void> _loadForSelectedDay() async {
    final rows = await KakeiboDb.instance.fetchByDate(_key(_selectedDay));
    setState(() {
      _items = rows.map(Tx.fromRow).toList();
    });
  }

  int get _incomeSum => _items
      .where((e) => e.type == TxType.income)
      .fold(0, (s, e) => s + e.amount);

  int get _expenseSum => _items
      .where((e) => e.type == TxType.expense)
      .fold(0, (s, e) => s + e.amount);

  // ---------- 月別 ----------
  Future<void> _loadMonthlyBalance() async {
    final rows = await KakeiboDb.instance.fetchByMonth(
      _focusedDay.year,
      _focusedDay.month,
    );

    _dailyBalanceMap.clear();
    int income = 0;
    int expense = 0;

    for (final tx in rows.map(Tx.fromRow)) {
      final date = DateTime.parse(tx.date);
      final key = _key(date);

      _dailyBalanceMap[key] =
          (_dailyBalanceMap[key] ?? 0) +
          (tx.type == TxType.income ? tx.amount : -tx.amount);

      tx.type == TxType.income ? income += tx.amount : expense += tx.amount;
    }

    setState(() {
      _monthlyBalance = income - expense;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadForSelectedDay();
    _loadMonthlyBalance();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy/MM/dd').format(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text("カレンダー"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _MonthBalanceChip(
              value: _monthlyBalance,
              formatter: _yenFormat,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---------- カレンダー ----------
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                locale: 'ja_JP',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _format,
                selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                onFormatChanged: (f) => setState(() => _format = f),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  _loadForSelectedDay();
                  _loadMonthlyBalance();
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    final key = _key(day);
                    final balance = _dailyBalanceMap[key];
                    final has = balance != null && balance != 0;
                    final plus = has && balance! > 0;
                    final big = has && balance!.abs() >= highlightThreshold;
                    final selected = isSameDay(day, _selectedDay);

                    return AnimatedScale(
                      scale: selected ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              has
                                  ? (plus
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.15))
                                  : null,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              selected
                                  ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  )
                                  : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: big ? 16 : 14,
                                fontWeight:
                                    big || selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            if (has)
                              Text(
                                '${plus ? "+" : "-"}${formatCompactYen(balance!)}',
                                style: TextStyle(
                                  fontSize: big ? 13 : 11,
                                  fontWeight:
                                      big ? FontWeight.bold : FontWeight.normal,
                                  color: plus ? Colors.green : Colors.red,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const Divider(),

          // ---------- 日別履歴 ----------
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _SummaryChip(
                        label: "収支",
                        value: _incomeSum - _expenseSum,
                        formatter: _yenFormat,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _items.isEmpty
                          ? const Center(child: Text("この日の履歴はありません"))
                          : ListView.separated(
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (_, i) {
                              final tx = _items[i];
                              final plus = tx.type == TxType.income;
                              return ListTile(
                                leading: Icon(
                                  plus ? Icons.add : Icons.remove,
                                  color: plus ? Colors.green : Colors.red,
                                ),
                                title: Text(
                                  tx.note?.trim().isNotEmpty == true
                                      ? tx.note!
                                      : tx.category,
                                ),
                                subtitle: Text(tx.category),
                                trailing: Text(
                                  "${plus ? "+" : "-"}${_yenFormat.format(tx.amount)}円",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: plus ? Colors.green : Colors.red,
                                  ),
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
        child: const Icon(Icons.add),
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => MyHomePage(title: "追加")),
          );
          if (saved == true) {
            _loadForSelectedDay();
            _loadMonthlyBalance();
          }
        },
      ),
    );
  }
}

// ---------- 日別サマリー ----------
class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final NumberFormat formatter;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final plus = value >= 0;
    final big = value.abs() >= 1000;
    final color = plus ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "$label: ${plus ? "+" : "-"}${formatter.format(value.abs())}円",
        style: TextStyle(
          fontWeight: big ? FontWeight.bold : FontWeight.normal,
          fontSize: big ? 18 : 14,
          color: color,
        ),
      ),
    );
  }
}

// ---------- 月収支 ----------
class _MonthBalanceChip extends StatelessWidget {
  final int value;
  final NumberFormat formatter;

  const _MonthBalanceChip({required this.value, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final plus = value >= 0;
    final color = plus ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "${plus ? "+" : "-"}${formatter.format(value.abs())}円",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
