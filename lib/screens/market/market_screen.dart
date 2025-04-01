import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';
import '../style/responsive_screen.dart';

class PlayMarketScreen extends StatefulWidget {
  const PlayMarketScreen({super.key});

  @override
  PlayMarketState createState() => PlayMarketState();
}

class PlayMarketState extends State<PlayMarketScreen> {
  // 模拟的商品数据
  List<Map<String, dynamic>> items = [
    {'name': '青锋剑', 'price': 100, 'seller': '张三'},
    {'name': '玄铁盾', 'price': 150, 'seller': '李四'},
    {'name': '灵丹', 'price': 80, 'seller': '王五'},
  ];

  // 可供选择的物品列表
  final List<String> availableItems = ['青锋剑', '玄铁盾', '灵丹', '火云袍', '风行靴'];

  // 控制出售对话框的输入
  String? _selectedItem; // 用于存储选择框选中的物品
  final TextEditingController _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();

    return Scaffold(
      appBar: AppBar(title: const Text('坊市')),
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(items[index]['name']),
                      subtitle: Text('卖家: ${items[index]['seller']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${items[index]['price']} 灵石'),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _showBuyDialog(items[index]),
                            child: Text('购买'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: _showSellDialog,
          child: const Text('出售商品'),
        ),
      ),
    );
  }

  // 添加购买确认对话框
  void _showBuyDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('确认购买'),
          content: Text(
            '确定要花费 ${item['price']} 灵石购买 ${item['name']} 吗？\n卖家: ${item['seller']}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // 这里可以添加购买逻辑，比如扣除灵石、更新库存等
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('成功购买 ${item['name']}')));
              },
              child: Text('确认购买'),
            ),
          ],
        );
      },
    );
  }

  void _showSellDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('出售物品'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedItem,
                    decoration: InputDecoration(labelText: '物品名称'),
                    items: availableItems.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedItem = newValue;
                      });
                    },
                  ),
                  TextField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: '价格(灵石)'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    if (_selectedItem != null && 
                        _priceController.text.isNotEmpty) {
                      setState(() {
                        items.add({
                          'name': _selectedItem!,
                          'price': int.parse(_priceController.text),
                          'seller': '我'
                        });
                      });
                      _selectedItem = null;
                      _priceController.clear();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('物品已上架')),
                      );
                    }
                  },
                  child: Text('出售'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
