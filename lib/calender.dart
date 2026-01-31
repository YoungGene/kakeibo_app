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
  DateTime? _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  /// 通常の金額表示（12,345）
  final NumberFormat _yenFormat = NumberFormat('#,###');

  String _key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  List<Tx> _items = [];
  int _monthlyBalance = 0;

  /// 日別合計（内部は int のまま）
  final Map<String, int> _dailyBalanceMap = {};

  // =====================================================
  // 金額省略（カレンダー専用）
  // 例: 12345 → 1.2万
  // =====================================================
  String compactYen(int value) {
    final v = value.abs();
    if (v >= 100000000) {
      return '${(v / 100000000).toStringAsFixed(1)}億';
    } else if (v >= 10000) {
      return '${(v / 10000).toStringAsFixed(1)}万';
    }
    return v.toString();
  }

  // =====================================================
  // 日別データ読み込み
  // =====================================================
  Future<void> _loadForSelectedDay(DateTime day) async {
    final rows = await KakeiboDb.instance.fetchByDate(_key(day));
    setState(() {
      _items = rows.map(Tx.fromRow).toList();
    });
  }

  // =====================================================
  // 月別集計
  // =====================================================
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

      if (tx.type == TxType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    setState(() {
      _monthlyBalance = income - expense;
    });
  }

  // =====================================================
  // 月全体の一覧
  // =====================================================
  Future<void> _loadForMonth() async {
    final rows = await KakeiboDb.instance.fetchByMonth(
      _focusedDay.year,
      _focusedDay.month,
    );

    setState(() {
      _items = rows.map(Tx.fromRow).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadForMonth(); // ← まずは月一覧
    _loadMonthlyBalance(); // ← 月合計＆日別合計
  }

  // =====================================================
  // 追加画面へ
  // =====================================================
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
      _loadForSelectedDay(day); // ← 引数付き版
      _loadMonthlyBalance();
    }
  }

  // =====================================================
  // 削除
  // =====================================================
  Future<void> _deleteTx(Tx tx) async {
    await KakeiboDb.instance.deleteByCreatedAt(tx.createdAt);

    if (_selectedDay != null) {
      _loadForSelectedDay(_selectedDay!);
    } else {
      _loadForMonth();
    }
    _loadMonthlyBalance();
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day, {
    required bool isSelected,
  }) {
    final key = _key(day);
    final bal = _dailyBalanceMap[key];
    final has = bal != null && bal != 0;
    final plus = has && bal! > 0;

    // 選択時の背景色（薄め）
    final selectedBg = Theme.of(context).colorScheme.primary.withOpacity(0.15);

    // 通常時の背景色（収支による色）
    final normalBg =
        has
            ? (plus
                ? Colors.green.withOpacity(0.15)
                : Colors.red.withOpacity(0.15))
            : Colors.transparent;

    return SizedBox.expand(
      // ★ セル全体を必ず同じサイズにする
      child: Container(
        // margin は外側のサイズが変わるので消して、
        // 内側に余白をつける
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : normalBg, // ★ 選択時は全体を薄く塗る
          borderRadius: BorderRadius.circular(10),
          border:
              isSelected
                  ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                  : null,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("カレンダー"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(
                /// ★ 月計はフル表示
                "月計 ${_yenFormat.format(_monthlyBalance)}円",
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
          // =================================================
          // カレンダー（縦幅を広く確保）
          // =================================================
          SizedBox(
            height: 440, // ★ カレンダーの縦幅を拡大
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                locale: 'ja_JP',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,

                availableCalendarFormats: const {CalendarFormat.month: '月'},
                calendarFormat: _format,

                rowHeight: 56, // ★ 6週でもオーバーフローしない

                selectedDayPredicate:
                    (d) => _selectedDay != null && isSameDay(_selectedDay, d),

                onDaySelected: (s, f) {
                  setState(() {
                    if (_selectedDay != null && isSameDay(_selectedDay, s)) {
                      _selectedDay = null;
                    } else {
                      _selectedDay = s;
                    }
                    _focusedDay = f;
                  });

                  if (_selectedDay == null) {
                    _loadForMonth();
                  } else {
                    _loadForSelectedDay(_selectedDay!);
                  }
                },

                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _loadMonthlyBalance();
                  if (_selectedDay == null) {
                    _loadForMonth();
                  }
                },

                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, _) {
                    return GestureDetector(
                      onDoubleTap: () => _openInsert(day),
                      child: _buildDayCell(
                        context,
                        day,
                        isSelected:
                            _selectedDay != null &&
                            isSameDay(_selectedDay, day),
                      ),
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return GestureDetector(
                      onDoubleTap: () => _openInsert(day),
                      child: _buildDayCell(context, day, isSelected: true),
                    );
                  },
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // =================================================
          // 日別明細（下に追いやる）
          // =================================================
          Expanded(
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
                    subtitle:
                        (tx.detail != null && tx.detail!.isNotEmpty)
                            ? Text(tx.detail!)
                            : (tx.note != null && tx.note!.isNotEmpty
                                ? Text(tx.note!)
                                : null),
                    trailing: Text(
                      "${plus ? "+" : "-"}${_yenFormat.format(tx.amount)}円",
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
