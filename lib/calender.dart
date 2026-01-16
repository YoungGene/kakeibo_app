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

  String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  List<Tx> _items = [];
  int _monthlyBalance = 0;

  final Map<String, int> _dailyBalanceMap = {};

  // ---------- 金額省略 ----------
  String compactYen(int value) {
    final v = value.abs();
    if (v >= 100000000) {
      final n = v / 100000000;
      return '${n.toStringAsFixed(1)}億';
    } else if (v >= 10000) {
      final n = v / 10000;
      return '${n.toStringAsFixed(1)}万';
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
      final key = tx.date;
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

  /// ---------- insertへ ----------
  Future<void> _openInsert(DateTime day) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const MyHomePage(title: "追加"),
        settings: RouteSettings(arguments: day),
      ),
    );

    if (saved == true) {
      _selectedDay = day;
      _focusedDay = day;
      _loadForSelectedDay();
      _loadMonthlyBalance();
    }
  }

  /// ---------- 削除 ----------
  Future<void> _deleteTx(Tx tx) async {
    await KakeiboDb.instance.deleteByCreatedAt(tx.createdAt);
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
            child: Chip(
              label: Text(
                "月計 ${compactYen(_monthlyBalance)}円",
                style: TextStyle(
                  color: _monthlyBalance >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// ---------- カレンダー ----------
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
                onDaySelected: (s, f) {
                  _selectedDay = s;
                  _focusedDay = f;
                  _loadForSelectedDay();
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    final key = _key(day);
                    final bal = _dailyBalanceMap[key];
                    final has = bal != null && bal != 0;
                    final plus = has && bal! > 0;

                    return GestureDetector(
                      onTap: () {
                        _selectedDay = day;
                        _focusedDay = day;
                        _loadForSelectedDay();
                      },
                      onDoubleTap: () => _openInsert(day),
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
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${day.day}'),
                            if (has)
                              Text(
                                '${plus ? "+" : "-"}${compactYen(bal!)}',
                                style: TextStyle(
                                  fontSize: 11,
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

          /// ---------- 日別 ----------
          Expanded(
            flex: 5,
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final tx = _items[i];
                final plus = tx.type == TxType.income;

                return Dismissible(
                  key: ValueKey(tx.createdAt),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteTx(tx),
                  child: ListTile(
                    leading: Icon(
                      plus ? Icons.add : Icons.remove,
                      color: plus ? Colors.green : Colors.red,
                    ),
                    title: Text(tx.category),
                    trailing: Text(
                      "${plus ? "+" : "-"}${compactYen(tx.amount)}円",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: plus ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
