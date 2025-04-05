import 'package:boundless_immortality/models/elixir.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';
import '../../models/material.dart';
import '../../models/user.dart';
import '../../common/constants.dart';

class PlayBagScreen extends StatefulWidget {
  const PlayBagScreen({super.key});

  @override
  PlayBagState createState() => PlayBagState();
}

class PlayBagState extends State<PlayBagScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final materials = context.watch<MaterialModel>();
    final elixirs = context.watch<ElixirModel>();
    final all = [
      _showMaterialItem(context, materials.elixirsItems.values.toList()),
      _showMaterialItem(context, materials.weaponItems.values.toList()),
      _showElixirItem(context, elixirs.items.values.toList()),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('灵药')),
                  ButtonSegment(value: 1, label: Text('材料')),
                  ButtonSegment(value: 2, label: Text('丹药')),
                ],
                selected: {_selectedIndex},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedIndex = newSelection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: all[_selectedIndex]),
          ],
        ),
      ),
    );
  }

  Widget _showMaterialItem(BuildContext context, List<MaterialItem> items) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 100,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final id = items[index].materialId;
        final name = items[index].name;
        final attribute = items[index].attribute;
        final number = items[index].number;
        final levelAdd = items[index].levelAdd;
        final (hp, attack, defense, hit, dodge) = items[index].powers();
        return MaterialItemWidget(
          id,
          name,
          attribute,
          number,
          (i) => _showItemDescription(
            context,
            name,
            id,
            attribute,
            number,
            levelAdd,
            hp,
            attack,
            defense,
            hit,
            dodge,
            "回收",
            _recycle,
          ),
          false,
        );
      },
    );
  }

  Widget _showElixirItem(BuildContext context, List<ElixirItem> items) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final id = items[index].elixirId;
        final name = items[index].name;
        final attribute = items[index].attribute;
        final number = items[index].number;
        final levelAdd = items[index].levelAdd;

        return MaterialItemWidget(
          id,
          name,
          attribute,
          number,
          (i) => _showItemDescription(
            context,
            name,
            id,
            attribute,
            number,
            levelAdd,
            items[index].powerHp,
            items[index].powerAttack,
            items[index].powerDefense,
            items[index].powerHit,
            items[index].powerDodge,
            "服下",
            _eat,
          ),
          false,
        );
      },
    );
  }

  void _showItemDescription(
    BuildContext context,
    String name,
    int id,
    int attribute,
    int number,
    int levelAdd,
    int hp,
    int attack,
    int defense,
    int hit,
    int dodge,
    String btn,
    Function(BuildContext, int) callback,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${attributes[attribute]} 属性，总 $number 个"),
              const SizedBox(height: 10),
              Text("修为: $levelAdd"),
              Text("生命: $hp"),
              Text("攻击: $attack"),
              Text("防御: $defense"),
              Text("暴击: $hit"),
              Text("闪避: $dodge"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => callback(context, id),
              child: Text(btn, style: TextStyle(color: Colors.red)),
            ),
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

  void _eat(BuildContext context, int id) {
    final user = context.read<UserModel>();
    context.read<ElixirModel>().eat(id, user);
    Navigator.of(context).pop();
  }

  void _recycle(BuildContext context, int id) {
    context.read<MaterialModel>().recycle(id);
    Navigator.of(context).pop();
  }
}
