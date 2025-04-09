import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';
import '../../common/constants.dart';
import '../../models/travel.dart';
import '../../models/material.dart';

class PlayTravelScreen extends StatefulWidget {
  const PlayTravelScreen({super.key});

  @override
  PlayTravelState createState() => PlayTravelState();
}

class PlayTravelState extends State<PlayTravelScreen>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _fogController;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _fogAnimation;
  double _width = 0;
  double _height = 0;

  int _selectedIndex = 0;
  bool _traveling = false;

  Map<int, Offset> _baseOffsets = {
    0: const Offset(0, 0),
    1: const Offset(20, -70),
    2: const Offset(-60, 20),
    3: const Offset(90, 20),
    4: const Offset(20, 90),
    5: const Offset(0, -150),
    6: const Offset(-150, 0),
    7: const Offset(150, 0),
    8: const Offset(0, 150),
  };

  late Map<int, Offset> _positions;
  int _currentPosition = 0;
  int _targetPosition = 0;
  bool _showFog = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _positions = Map.from(_baseOffsets);

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fogAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fogController, curve: Curves.easeInOut));

    _moveAnimation =
        Tween<Offset>(
            begin: _positions[_currentPosition]!,
            end: _positions[_targetPosition]!,
          ).animate(
            CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
          )
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) async {
            if (status == AnimationStatus.completed) {
              setState(() => _showFog = true);
              await _fogController.forward(from: 0);
              _currentPosition = _targetPosition;
              // _recenterPositions();
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 1000));
              setState(() {
                _showFog = false;
                _currentPosition = 0;
                _moveController.reverse();
              });
            }
          });
  }

  @override
  void dispose() {
    _moveController.dispose();
    _fogController.dispose();
    super.dispose();
  }

  void _moveTo(int direction, TravelModel travel) {
    if (_currentPosition == direction || !_positions.containsKey(direction)) {
      return;
    }
    final id = travel.neighbors[direction]?.id ?? 0;

    // do travel
    startTravel(context, travel, id);

    setState(() {
      _targetPosition = direction;
      _moveAnimation = Tween<Offset>(
        begin: _positions[_currentPosition]!,
        end: _positions[_targetPosition]!,
      ).animate(
        CurvedAnimation(parent: _moveController, curve: Curves.easeInOut),
      );
      _moveController.forward(from: 0);
    });
  }

  Widget _buildLocation(int pos, Offset offset, TravelModel travel) {
    final n = travel.neighbors[pos];
    final small =
        pos < 5 && travel.neighbors[pos]?.id == travel.neighbors[pos + 4]?.id;
    if ((n?.id ?? 0) == 0 || small) {
      return SizedBox.shrink();
    }

    final ttype = n?.ttype ?? 0;
    final showName = ttype == 0 || pos == 0;
    final name = "${n?.id ?? 0} ${n?.name ?? ''}";
    final isMain = pos == 0 && travel.main.id != 0;
    final iconColor =
        isMain ? Colors.red : (ttype == 1 ? Colors.white : Colors.green);
    return Positioned(
      left: _width / 2 + offset.dx - 40,
      top: _height / 2 + offset.dy - 80,
      child: Column(
        children: [
          ttype == 1
              ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(0xBFADA595),
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: Icon(Icons.castle, color: iconColor),
              )
              : Icon(Icons.terrain, color: iconColor),
          GestureDetector(
            onTap:
                isMain
                    ? () => showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return CreateTravelDialog(travel.main);
                      },
                    )
                    : null,
            child:
                showName
                    ? Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xBFADA595),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                    : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _height = MediaQuery.of(context).size.height;
    if (screenWidth > 760) {
      _width = screenWidth - 350; // home page
    } else {
      _width = screenWidth;
    }

    final travel = context.watch<TravelModel>();
    final history = travel.history.values.toList();
    final avaiable = travel.avaiable();
    final up =
        travel.neighbors[1] != null ? 1 : (travel.neighbors[5] != null ? 5 : 0);
    final left =
        travel.neighbors[2] != null ? 2 : (travel.neighbors[6] != null ? 6 : 0);
    final right =
        travel.neighbors[3] != null ? 3 : (travel.neighbors[7] != null ? 7 : 0);
    final down =
        travel.neighbors[4] != null ? 4 : (travel.neighbors[8] != null ? 8 : 0);

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
                    ButtonSegment(value: 0, label: Text('地图模式')),
                    ButtonSegment(value: 1, label: Text('历史足迹')),
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
            SizedBox(
              width: _width,
              height: _height - 140,
              child:
                  _selectedIndex == 0
                      ? Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: '请输入地址 ID',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () {
                                    final show =
                                        int.parse(_searchController.text);
                                    if (show > 0) {
                                      startTravel(context, travel, show);
                                    }
                                  },
                                ),
                              ),
                              onSubmitted: (value) {
                                final show = int.parse(_searchController.text);
                                if (show > 0) {
                                  startTravel(context, travel, show);
                                }
                              },
                            ),
                          ),

                          // Location markers
                          ..._positions.entries.map(
                            (e) => _buildLocation(e.key, e.value, travel),
                          ),

                          // Character on sword with image
                          Positioned(
                            left: _width / 2 + _moveAnimation.value.dx - 20,
                            top: _height / 2 + _moveAnimation.value.dy - 120,
                            child: Image.asset(
                              'assets/images/flying.png',
                              width: 50,
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                          ),

                          // Cloud transition effect using semi-transparent overlay and text
                          if (_showFog)
                            FadeTransition(
                              opacity: _fogAnimation,
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Color(0xBFADA595),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: const Text(
                                  '飞行中……',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          // Control buttons
                          Positioned(
                            right: 20,
                            bottom: 20,
                            child: Column(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: CircleBorder(),
                                  ),
                                  onPressed:
                                      up != 0 && avaiable
                                          ? () => _moveTo(up, travel)
                                          : null,
                                  child: Icon(Icons.arrow_upward),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(),
                                      ),
                                      onPressed:
                                          left != 0 && avaiable
                                              ? () => _moveTo(left, travel)
                                              : null,
                                      child: Icon(Icons.arrow_back),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        shape: CircleBorder(),
                                      ),
                                      onPressed:
                                          right != 0 && avaiable
                                              ? () => _moveTo(right, travel)
                                              : null,
                                      child: Icon(Icons.arrow_forward),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: CircleBorder(),
                                  ),
                                  onPressed:
                                      down != 0 && avaiable
                                          ? () => _moveTo(down, travel)
                                          : null,
                                  child: Icon(Icons.arrow_downward),
                                ),
                              ],
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
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                                onPressed: () async {
                                  final t = await travel.show(
                                    history[index].travelId,
                                  );
                                  if (!context.mounted || !t) return;
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext dialogContext) {
                                      return CreateTravelDialog(travel.main);
                                    },
                                  );
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
        rectangularMenuArea: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Color(0xFF5A5646)),
                foregroundColor: WidgetStateProperty.all(Colors.white),
              ),
              onPressed:
                  travel.main.id == travel.mine?.id || travel.main.id == 0
                      ? null
                      : () => showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return CreateMineDialog(
                            travel.mine,
                            travel.neighbors,
                          );
                        },
                      ),
              child: Text(travel.mine == null ? '修建洞府' : '转移洞府'),
            ),
            FilledButton(
              onPressed:
                  _traveling || !avaiable
                      ? null
                      : () => startTravel(context, travel, 0),
              child: Text(avaiable ? '随机游历' : '今日已用完'),
            ),
          ],
        ),
      ),
    );
  }

  void startTravel(BuildContext context, TravelModel travel, int show) async {
    setState(() {
      _traveling = true;
    });

    bool res;
    if (show == 0) {
      res = await travel.random();
    } else {
      res = await travel.show(show);
    }

    _traveling = false;
    if (context.mounted && res) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return CreateTravelDialog(travel.main);
        },
      );
    }
  }
}

const posName = ['中', '上', '左', '右', '下'];

class CreateMineDialog extends StatefulWidget {
  final TravelItem? old;
  final Map<int, TravelNeighbor?> neighbors;
  const CreateMineDialog(this.old, this.neighbors, {super.key});

  @override
  CreateMineDialogState createState() => CreateMineDialogState();
}

class CreateMineDialogState extends State<CreateMineDialog> {
  final TextEditingController _mineController = TextEditingController();
  int _dtype = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    _mineController.text = widget.old?.content ?? '';
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

    final neighbor = widget.neighbors[0]?.id ?? 0;
    final arrow = _dtype - 1;
    if (neighbor == 0 || arrow < 0 || arrow > 3) {
      return;
    }

    final res = await context.read<TravelModel>().create(
      content,
      neighbor,
      arrow,
    );

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
    var lines = [];
    final startName = widget.neighbors[0]?.name ?? '';
    widget.neighbors.forEach((k, v) {
      if (k > 4) {
        lines.add(
          RadioListTile<int>(
            title: Text("$startName <-> ${v?.name ?? '空'} (${posName[k - 4]})"),
            value: k - 4,
            groupValue: _dtype,
            onChanged: (int? value) {
              setState(() {
                _dtype = value ?? 1;
              });
            },
          ),
        );
      }
    });

    return AlertDialog(
      title: Text('我的洞府'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...lines,
          TextField(
            maxLines: 3,
            minLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '打个招呼！输入新文字 (100 字以内)',
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
  const CreateTravelDialog(this.item, {super.key});

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
    final mname = widget.item.material?.name ?? '无';
    final power = widget.item.ttype == 1 ? '不详' : levels[widget.item.power];
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
            Text("对方等级: $power"),
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
          onPressed:
              _loading || widget.item.material == null
                  ? null
                  : () => _submitData(context),
          child: Text(_loading ? '进行中' : '拿下'),
        ),
      ],
    );
  }
}
