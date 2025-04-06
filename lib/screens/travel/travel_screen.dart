import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    final travel = context.watch<TravelModel>();
    final history = travel.history.values.toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                ),
              ),
            ),
            Expanded(
              child:
                  _selectedIndex == 1
                      ? Column(
                        children: [
                          GestureDetector(
                            onTap:
                                () => showDialog(
                                  context: context,
                                  builder: (BuildContext dialogContext) {
                                    return CreateMineDialog(
                                      travel.mine?.content ?? '',
                                    );
                                  },
                                ),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4.0),
                              width: double.infinity,
                              height: 80,
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                color: Color(0xBFADA595),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                travel.mine?.content ?? '无',
                                style: const TextStyle(fontSize: 16),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                      : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final name = history[index].name;
                          final realname =
                              history[index].ttype == 1 ? "$name 的洞府" : name;
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(realname),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      history[index].material ? '有发现' : '',
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    onPressed: () async {
                                      final (t, m) = await travel.show(
                                        history[index].travelId,
                                      );
                                      if (t == null) return;
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext dialogContext) {
                                          return CreateTravelDialog(t, m);
                                        },
                                      );
                                    },
                                    child: Text('闯入'),
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
          onPressed:
              _traveling || !travel.avaiable()
                  ? null
                  : () => startTravel(context, travel),
                  child: Text(travel.avaiable() ? '随机游历' : '今日次数已用完'),
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

class CreateMineDialog extends StatefulWidget {
  final String old;
  const CreateMineDialog(this.old, {super.key});

  @override
  CreateMineDialogState createState() => CreateMineDialogState();
}

class CreateMineDialogState extends State<CreateMineDialog> {
  final TextEditingController _mineController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    _mineController.text = widget.old;
    super.initState();
  }

  void _submitData(BuildContext context) async {
    setState(() {
      _loading = true;
    });

    final content = _mineController.text;

    if (content.length > 100) {
      setState(() {
        _error = '最多 100 个字';
      });
    }

    final res = await context.read<TravelModel>().create(content);

    _loading = false;
    if (res) {
      if (context.mounted) Navigator.of(context).pop();
    } else {
      setState(() {
        _error = '更新失败，稍后再试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('我的洞府'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            maxLines: 3,
            minLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '输入新文字 (100 字以内)',
            ),
            controller: _mineController,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(_error ?? ''),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : () => _submitData(context),
          child: Text(_loading ? '进行中' : '更新'),
        ),
      ],
    );
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
      Future.delayed(Duration(seconds: 1), () {
        if (context.mounted) Navigator.of(context).pop();
      });
    } else {
      setState(() {
        _loading = false;
        _info = '打斗失败或已被领取！';
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
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text("发现了: $mname"),
            const SizedBox(height: 4.0),
            Text("对方战力: ${widget.item.power}"),
            const SizedBox(height: 10.0),
            Text(_info, style: TextStyle(color: Colors.blue)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _loading || widget.material == null ? null : () => _submitData(context),
          child: Text(_loading ? '进行中' : '拿下'),
        ),
      ],
    );
  }
}
