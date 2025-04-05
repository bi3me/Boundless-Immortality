import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';
import '../../models/duel.dart';
import '../../models/user.dart';
import '../../common/constants.dart';

class PlayDuelScreen extends StatefulWidget {
  const PlayDuelScreen({super.key});

  @override
  PlayDuelState createState() => PlayDuelState();
}

class PlayDuelState extends State<PlayDuelScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final duel = context.watch<DuelModel>();
    final user = context.read<UserModel>();
    List<ActivedDuelItem> items = [];
    bool hasMy = false;
    duel.mine.forEach((key, value) {
      hasMy = value.player == user.id;
      items.add(value);
    });
    duel.actives.forEach((key, value) {
      if (!duel.mine.containsKey(key)) {
        items.add(value);
      }
    });

    final widgets = [
      _showActivedDuel(items, duel, user),
      _showHistoryDuel(duel.history.values.toList(), user.attribute),
    ];

    return CustomScaffold(
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('擂台')),
                    ButtonSegment(value: 1, label: Text('战绩')),
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
            Expanded(child: widgets[_selectedIndex]),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: hasMy ? null : () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return CreateDuelDialog();
              },
            );
          },
          child: const Text('摆擂'),
        ),
      ),
    );
  }

  Widget _showActivedDuel(
    List<ActivedDuelItem> items,
    DuelModel duel,
    UserModel user,
  ) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final id = items[index].id;
        final isMe = items[index].isMe;
        final isMy = items[index].player == user.id;
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          color: isMe ? attributeColors[user.attribute] : Color(0xBFCCCCD6),
          child: ListTile(
            title: Text(isMy ? '我的擂台' : items[index].name),
            subtitle: Text(
              "${levels[items[index].level]}, 战力: ${items[index].power}",
              style: TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("${items[index].coin} 灵石"),
                ),
                SizedBox(width: 8),
                if (!isMy)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => duel.accept(id, user),
                    child: Text('挑战'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _showHistoryDuel(List<DuelItem> items, int attribute) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final bool win = items[index].win ?? false;
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          color: win ? attributeColors[attribute] : Color(0xBFCCCCD6),
          child: ListTile(
            title: Text(win ? '胜利' : '失败'),
            trailing: Text("${items[index].coin} 灵石"),
          ),
        );
      },
    );
  }
}

class CreateDuelDialog extends StatefulWidget {
  const CreateDuelDialog({super.key});

  @override
  CreateDuelDialogState createState() => CreateDuelDialogState();
}

class CreateDuelDialogState extends State<CreateDuelDialog> {
  final TextEditingController _coinController = TextEditingController();
  int _dtype = 1;
  String? _error;
  bool _loading = false;
  final Map<int, String> _descriptions = {
    1: '这是选项1的描述文字，详细说明了选择此选项的含义。',
    2: '这是选项2的描述文字，可能包含不同的信息和说明。',
  };

  void _submitData(BuildContext context) async {
    setState(() {
      _error = null;
    });

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

    final res = await context.read<DuelModel>().create(_dtype, coin, null);

    _loading = false;
    if (res) {
      if (context.mounted) Navigator.of(context).pop();
    } else {
      setState(() {
        _error = "Failure";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('擂台'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('单次模式'),
              value: 1,
              groupValue: _dtype,
              onChanged: (int? value) {
                setState(() {
                  _dtype = value ?? 1;
                });
              },
            ),
            RadioListTile<int>(
              title: const Text('无限模式'),
              value: 2,
              groupValue: _dtype,
              onChanged: (int? value) {
                setState(() {
                  _dtype = value ?? 1;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                _descriptions[_dtype] ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
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
          child: Text(_loading ? '开始中' : '开始'),
        ),
      ],
    );
  }
}
