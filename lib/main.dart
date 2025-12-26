import 'package:flutter/material.dart';
import 'insert.dart';
import 'calender.dart';
import 'menu.dart';
import 'report.dart';

void main() {
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
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MyHomePage(title: 'Flutter Demo Home Page'),
    SecondPage(),
    ThirdPage(),
    ForthPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // ← 4つ以上は必須
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "ホーム"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "履歴"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "分析"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "設定"),
        ],
      ),
    );
  }
}
