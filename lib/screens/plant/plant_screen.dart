import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';
import '../../models/user.dart';
import '../../models/plant.dart';
import '../../models/material.dart';
import '../../common/constants.dart';

class PlayPlantScreen extends StatefulWidget {
  // const PlayKungfuScreen({Key? key}) : super(key: key);
  const PlayPlantScreen({super.key});

  @override
  PlayPlantState createState() => PlayPlantState();
}

class PlayPlantState extends State<PlayPlantScreen> {
  Map<int, SeedMaterial> materials = {};
  Map<int, PlantItem> plants = {};
  Map<int, SeedItem> seeds = {};

  @override
  Widget build(BuildContext context) {
    final plant = context.watch<PlantModel>();
    materials = plant.materials;
    plants = plant.plants;
    seeds = plant.seeds;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlchemyGrid(),
            Divider(),
            _buildMaterialsSelection(),
            SizedBox(height: 20),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed:
              () => showDialog(
                context: context,
                builder: (BuildContext dialogContext) {
                  return CreateBuyDialog(materials.values.toList());
                },
              ),
          child: Text('购买种子'),
        ),
      ),
    );
  }

  Widget _buildAlchemyGrid() {
    final myplants = plants.values.toList();
    final now = DateTime.now().toUtc();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 100,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          bool lock = index < myplants.length;
          int id = 0;
          String name = '可种植';
          int attribute = 0;
          int number = 0;
          String endedAt = '';
          bool collectable = false;

          if (lock) {
            id = myplants[index].id;
            name = materials[myplants[index].materialId]?.name ?? '';
            attribute = materials[myplants[index].materialId]?.attribute ?? 0;
            number = 1;
            final end = myplants[index].endedAt.toUtc();
            if (now.compareTo(end) > 0) {
              collectable = true;
            } else {
              Duration diff = end.difference(now).abs();
              int hours = diff.inHours % 24;
              int minutes = diff.inMinutes % 60;
              endedAt = "$hours h $minutes m";
            }
          }

          return GestureDetector(
            onTap: collectable ? () => _collect(id) : null,
            child: Container(
              decoration: BoxDecoration(
                color:
                    collectable || number == 0
                        ? Colors.white
                        : Color(0xBFADA595),
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                          Text(endedAt),
                        ],
                      ),
                    ),
                  ),
                  if (collectable)
                    Positioned(
                      left: 2,
                      bottom: 2,
                      child: Container(
                        height: 20,
                        width: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: Text(
                          '熟',
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ),
                    ),
                  if (attribute != 0)
                    Positioned(
                      left: 2,
                      top: 2,
                      child: Container(
                        height: 20,
                        width: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: Text(
                          attributes[attribute],
                          style: TextStyle(
                            color: attributeColors[attribute],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  if (number != 0)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        height: 20,
                        width: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(100),
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: Text(
                          "$number",
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialsSelection() {
    final myseeds = seeds.values.toList();
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 100,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: myseeds.length,
          itemBuilder: (context, index) {
            final seed = myseeds[index];
            return MaterialItemWidget(
              seed.id,
              materials[seed.materialId]?.name ?? '',
              materials[seed.materialId]?.attribute ?? 0,
              seed.number,
              _plant,
              false,
            );
          },
        ),
      ),
    );
  }

  void _collect(int id) {
    if (plants[id] == null) {
      return;
    }
    final end = plants[id]?.endedAt.toUtc();
    final now = DateTime.now().toUtc();
    if (end == null || now.compareTo(end) < 0) {
      return;
    }

    final m = context.read<MaterialModel>();
    context.read<PlantModel>().collect(id, m);
  }

  void _plant(int id) {
    if (plants.length >= 8 || (seeds[id]?.number ?? 0) < 1) {
      return;
    }

    context.read<PlantModel>().plant(id);
  }
}

class CreateBuyDialog extends StatefulWidget {
  final List<SeedMaterial> materials;

  const CreateBuyDialog(this.materials, {super.key});

  @override
  CreateBuyDialogState createState() => CreateBuyDialogState();
}

class CreateBuyDialogState extends State<CreateBuyDialog> {
  String? _error;
  bool _loading = false;

  void _buy(int id, BuildContext context) async {
    setState(() {
      _error = null;
    });

    setState(() {
      _loading = true;
    });

    final u = context.read<UserModel>();
    final res = await context.read<PlantModel>().buy(id, u);

    _loading = false;
    if (res) {
      setState(() {
        _error = '成功放入背包！';
      });
      Future.delayed(Duration(seconds: 1), () {
        if (context.mounted) Navigator.of(context).pop();
      });
    } else {
      setState(() {
        _error = "购买失败！";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('灵药种子'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.materials.length, (index) {
            final item = widget.materials[index];
            final (h1, h2, h3, h4, h5) = item.powers();
            return Card(
              margin: EdgeInsets.symmetric(vertical: 4),
              color: Color(0xFFADA595),
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(
                  "命:$h1 攻:$h2 防:$h3 暴:$h4 闪$h5, 修: ${item.levelAdd}",
                  style: TextStyle(fontSize: 10),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("${item.coin} 灵石"),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: _loading ? null : () => _buy(item.id, context),
                      child: Text(_loading ? '购买中' : '购买'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
      actions: [
        if (_error != null) Text(_error ?? ''),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
      ],
    );
  }
}
