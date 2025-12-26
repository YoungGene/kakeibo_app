import 'package:flutter/material.dart';
import 'calender.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedIndex = 0;
  int selectedIndexC = 0;

  @override
  Widget build(BuildContext context) {
    final List<bool> selected = [false, false];
    final List<bool> selectedC = [
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ];

    final List<String> buttonLabels = [
      "食費",
      "家賃",
      "交通",
      "娯楽",
      "医療",
      "教育",
      "貯金",
      "投資",
      "その他",
    ];
    selected[selectedIndex] = true;
    selectedC[selectedIndexC] = true;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // トグルボタン行
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToggleButtons(
                isSelected: selected,
                children: const [Text("支出"), Text("収入")],
                onPressed: (int index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // テキストボックス行
          TextField(
            decoration: const InputDecoration(
              labelText: '日付',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),

          TextField(
            decoration: const InputDecoration(
              labelText: 'メモ',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),

          TextField(
            decoration: const InputDecoration(
              labelText: '金額',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 48),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width, // 画面幅
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: List.generate(9, (index) {
                  return ToggleButtons(
                    isSelected: [selectedC[index]],
                    onPressed: (int _) {
                      setState(() {
                        selectedIndexC = index;
                      });
                    },

                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(buttonLabels[index]),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecondPage()),
          );
        },
        tooltip: 'Next Page',
        child: const Icon(Icons.arrow_forward),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
