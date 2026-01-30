import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'insert.dart';
import 'calender.dart';
import 'menu.dart';
import 'report.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 日本語ロケールを初期化
  await initializeDateFormatting('ja_JP', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MainPage());
  }
}

class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({super.key, this.initialIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    MyHomePage(title: 'Flutter Demo Home Page'),
    CalendarPage(),
    ReportPage(),
    ForthPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
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
