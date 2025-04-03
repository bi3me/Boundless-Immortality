import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';
import '../style/responsive_screen.dart';
import '../../models/travel.dart';
import '../../models/material.dart';

class PlayTravelScreen extends StatefulWidget {
  const PlayTravelScreen({super.key});

  @override
  PlayTravelState createState() => PlayTravelState();
}

class PlayTravelState extends State<PlayTravelScreen> {
  int _selectedIndex = 0;
  bool _traveling = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final travel = context.watch<TravelModel>();
    final history = travel.history.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('游历')),
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('历史足迹')),
                    ButtonSegment(value: 1, label: Text('我的洞府')),
                  ],
                  selected: {_selectedIndex},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedIndex = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final name = history[index].name;
                  final realname = history[index].ttype == 1 ? "$name 的洞府" : name;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    color:
                        history[index].material
                            ? Colors.green[200]
                            : Colors.grey[200],
                    child: ListTile(
                      title: Text(realname),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () {
                          //
                        },
                        child: Text('闯入'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed:
              _traveling || !travel.avaiable()
                  ? null
                  : () => startTravel(context, travel),
          child: const Text('随机游历'),
        ),
      ),
    );
  }

  void startTravel(BuildContext context, TravelModel travel) async {
    setState(() {
      _traveling = true;
    });
    final (item, material) = await travel.random();
    _traveling = false;
    if (item != null) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return CreateTravelDialog(item, material);
        },
      );
    }
  }
}

class CreateTravelDialog extends StatefulWidget {
  final TravelItem item;
  final MaterialItem? material;
  const CreateTravelDialog(this.item, this.material, {super.key});

  @override
  CreateTravelDialogState createState() => CreateTravelDialogState();
}

class CreateTravelDialogState extends State<CreateTravelDialog> {
  String _info = '';
  bool _loading = false;

  void _submitData(BuildContext context) async {
    setState(() {
      _loading = true;
    });

    final mm = context.read<MaterialModel>();
    final res = await context.read<TravelModel>().solve(widget.item.id, mm);

    _loading = false;
    if (res) {
      setState(() {
        _info = '成功放入背包！';
      });
    } else {
      setState(() {
        _loading = false;
        _info = '打斗失败！';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mname = widget.material?.name ?? '无';
    return AlertDialog(
      title: Text('神秘之地'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.item.name),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                widget.item.content,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            Text("发现了: $mname"),
            const SizedBox(height: 10),
            Text(_info),
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
          child: Text(_loading ? '进行中' : '拿下'),
        ),
      ],
    );
  }
}
