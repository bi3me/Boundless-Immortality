import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';
import '../../common/constants.dart';
import '../../models/market.dart';
import '../../models/material.dart';
import '../../models/kungfu.dart';
import '../../models/elixir.dart';
import '../../models/weapon.dart';

class PlayMarketScreen extends StatefulWidget {
  const PlayMarketScreen({super.key});

  @override
  PlayMarketState createState() => PlayMarketState();
}

class PlayMarketState extends State<PlayMarketScreen> {
  int _selectedIndex = 0;
  Map<int, Map<String, dynamic>> cache = {};

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketModel>();
    final all = [
      _showItems(market.materials.values.toList(), market),
      _showItems(market.kungfus.values.toList(), market),
      _showItems(market.elixirs.values.toList(), market),
      _showItems(market.weapons.values.toList(), market),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('灵材')),
                  ButtonSegment(value: 1, label: Text('功法')),
                  ButtonSegment(value: 2, label: Text('丹药')),
                  ButtonSegment(value: 3, label: Text('武器')),
                ],
                selected: {_selectedIndex},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _selectedIndex = newSelection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 4.0),
            Expanded(child: all[_selectedIndex]),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return CreateMarketDialog();
              },
            );
          },
          child: const Text('出售商品'),
        ),
      ),
    );
  }

  Widget _showItems(List<MarketItem> items, MarketModel market) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: GestureDetector(
              onTap: () async {
                final info = cache[item.id] ?? await market.fetchItem(item.id);
                if (info != null && context.mounted) {
                  cache[item.id] = info;
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return CreateItemDialog(item, info['data']);
                    },
                  );
                }
              },
              child: Text(item.itemName),
            ),
            subtitle: Text(
              "${attributes[item.itemAttribute]} 属性",
              style: TextStyle(fontSize: 10),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("${item.coin} 灵石"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _showBuyDialog(context, item, market),
                  child: Text('购买'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // buy confirm
  void _showBuyDialog(
    BuildContext context,
    MarketItem item,
    MarketModel market,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('确认购买'),
          content: Text("确定要花费 ${item.coin} 灵石购买 ${item.itemName} 吗？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await market.buy(item.mtype, item.id, context);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('确认购买'),
            ),
          ],
        );
      },
    );
  }
}

class CreateMarketDialog extends StatefulWidget {
  const CreateMarketDialog({super.key});

  @override
  CreateMarketDialogState createState() => CreateMarketDialogState();
}

class CreateMarketDialogState extends State<CreateMarketDialog> {
  final TextEditingController _coinController = TextEditingController();
  int? _mtype;
  int? _item;
  List<(int, String)> _items = [];

  String? _error;
  bool _loading = false;

  void _submitData(BuildContext context) async {
    setState(() {
      _error = null;
    });
    final mtype = _mtype ?? 0;
    final item = _item ?? 0;
    if (mtype < 1 || item < 1) {
      setState(() {
        _error = "No coin";
      });
      return;
    }

    final coin = int.parse(_coinController.text);
    if (coin < 1) {
      setState(() {
        _error = "No coin";
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    final res = await context.read<MarketModel>().create(mtype, item, coin);

    if (context.mounted) {
      switch (mtype) {
        case 1:
          final material = context.read<MaterialModel>();
          material.elixirsItems[item]?.number -= 1;
          material.weaponItems[item]?.number -= 1;
          break;
        case 2:
          // kungfu not reduce
          break;
        case 3:
          context.read<ElixirModel>().items[item]?.number -= 1;
          break;
        case 4:
          context.read<WeaponModel>().items[item]?.number -= 1;
          break;
        default:
          break;
      }
    }

    _loading = false;
    if (res) {
      if (context.mounted) Navigator.of(context).pop();
    } else {
      setState(() {
        _error = "Failure";
      });
    }
  }

  void changeMtype(BuildContext context, int? value) {
    if (value == null) {
      return;
    }

    switch (value) {
      case 1:
        _items = context.read<MaterialModel>().availableForSale();
        break;
      case 2:
        _items = context.read<KungfuModel>().availableForSale();
        break;
      case 3:
        _items = context.read<ElixirModel>().availableForSale();
        break;
      case 4:
        _items = context.read<WeaponModel>().availableForSale();
        break;
      default:
        break;
    }

    setState(() {
      _mtype = value;
      _item = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('出售'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_mtype != null && _mtype != 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('只有解锁的物品，才可以进行出售'),
              ),
            SizedBox(
              width: double.infinity,
              child: DropdownButton<int>(
                isExpanded: true,
                hint: Text("选择类型"),
                value: _mtype,
                onChanged: (i) => changeMtype(context, i),
                items: [
                  DropdownMenuItem<int>(value: 1, child: Text('灵材')),
                  DropdownMenuItem<int>(value: 2, child: Text('功法')),
                  DropdownMenuItem<int>(value: 3, child: Text('丹药')),
                  DropdownMenuItem<int>(value: 4, child: Text('武器')),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: DropdownButton<int>(
                isExpanded: true,
                hint: Text("选择物品"),
                value: _item,
                onChanged: (newRecipe) {
                  setState(() {
                    _item = newRecipe;
                  });
                },
                items:
                    _items.map((i) {
                      final (k, v) = i;
                      return DropdownMenuItem<int>(value: k, child: Text(v));
                    }).toList(),
              ),
            ),
            TextFormField(
              controller: _coinController,
              decoration: InputDecoration(labelText: '灵石'),
            ),
            const SizedBox(height: 10),
            if (_error != null) Text(_error ?? ''),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : () => _submitData(context),
          child: Text(_loading ? '出售中' : '出售'),
        ),
      ],
    );
  }
}

class CreateItemDialog extends StatefulWidget {
  final MarketItem item;
  final Map<String, dynamic> info;
  const CreateItemDialog(this.item, this.info, {super.key});

  @override
  CreateItemDialogState createState() => CreateItemDialogState();
}

class CreateItemDialogState extends State<CreateItemDialog> {
  @override
  Widget build(BuildContext context) {
    var level = '无';
    var h0 = 0;
    var h1 = 0;
    var h2 = 0;
    var h3 = 0;
    var h4 = 0;
    var h5 = 0;

    switch (widget.item.mtype) {
      case 1:
        final i = MaterialModel.parseNetwork(widget.info);
        final (h11, h22, h33, h44, h55) = i.powers();
        h0 = i.levelAdd;
        h1 = h11;
        h2 = h22;
        h3 = h33;
        h4 = h44;
        h5 = h55;
        break;
      case 2:
        final i = KungfuModel.parseNetwork(widget.info);
        final (h11, h22, h33, h44, h55) = i.getPowers();
        level = levels[i.level];
        h1 = h11;
        h2 = h22;
        h3 = h33;
        h4 = h44;
        h5 = h55;
        break;
      case 3:
        final i = ElixirModel.parseNetwork(widget.info);
        level = levels[i.level];
        h0 = i.levelAdd;
        h1 = i.powerHp;
        h2 = i.powerAttack;
        h3 = i.powerDefense;
        h4 = i.powerHit;
        h5 = i.powerDodge;
        break;
      case 4:
        final i = WeaponModel.parseNetwork(widget.info);
        level = levels[i.level];
        h1 = i.powerHp;
        h2 = i.powerAttack;
        h3 = i.powerDefense;
        h4 = i.powerHit;
        h5 = i.powerDodge;
        break;
      default:
        break;
    }
    return AlertDialog(
      title: Text(widget.item.itemName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("属性：${attributes[widget.item.itemAttribute]}"),
            Text("等级：$level"),
            Text("修为：$h0"),
            Text("生命：$h1"),
            Text("攻击：$h2"),
            Text("防御：$h3"),
            Text("暴击：$h4"),
            Text("闪避：$h5"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            await context.read<MarketModel>().buy(
              widget.item.mtype,
              widget.item.id,
              context,
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: Text('购买'),
        ),
      ],
    );
  }
}
