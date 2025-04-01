import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';
import '../style/responsive_screen.dart';

class PlayBagScreen extends StatefulWidget {
  const PlayBagScreen({super.key});

  @override
  PlayBagState createState() => PlayBagState();
}

class PlayBagState extends State<PlayBagScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final List<String> items = List.generate(50, (index) => "物品 ${index + 1}");

    return Scaffold(
      appBar: AppBar(title: const Text('储物袋')),
      body: ResponsiveScreen(
        squarishMainArea: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _showItemDescription(context, items[index]);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(items[index], style: TextStyle(fontSize: 16)),
                ),
              );
            },
          ),
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () {
            GoRouter.of(context).go('/play');
          },
          child: const Text('Action'),
        ),
      ),
    );
  }

  void _showItemDescription(BuildContext context, String itemName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("物品详情"),
          content: Text("$itemName 的说明文字。"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("关闭"),
            ),
          ],
        );
      },
    );
  }
}
