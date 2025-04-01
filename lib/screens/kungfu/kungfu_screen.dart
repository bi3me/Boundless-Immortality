import 'package:boundless_immortality/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../style/palette.dart';
import '../style/responsive_screen.dart';
import '../../models/kungfu.dart';
import '../../common/constants.dart';

class PlayKungfuScreen extends StatefulWidget {
  const PlayKungfuScreen({super.key});

  @override
  PlayKungfuState createState() => PlayKungfuState();
}

class PlayKungfuState extends State<PlayKungfuScreen> {
  @override
  Widget build(BuildContext context) {
    final palette = context.watch<Palette>();
    final kungfu = context.watch<KungfuModel>();
    final user = context.watch<UserModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('功法')),
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "修炼功法",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            kungfu.working != null
                ? ExpansionTile(
                  title: Text(kungfu.working?.name ?? ''),
                  children: <Widget>[
                    Text(
                      "${attributes[kungfu.working?.myattribute ?? 0]} 属性，最高可修炼至 ${levels[kungfu.working?.level ?? 0]} 境界",
                    ),
                  ],
                )
                : ListTile(title: Text('无')),
            SizedBox(height: 40),
            _buildOtherSkills(kungfu, user),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed: () => _showCreateDialog(context, user.level, user.attribute),
          child: const Text('创建功法'),
        ),
      ),
    );
  }

  Widget _buildOtherSkills(KungfuModel kungfu, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "所有功法",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Column(
          spacing: 10,
          children:
              kungfu.items.values.map((item) {
                return ExpansionTile(
                  title: Text(item.name),
                  trailing:
                      item.working
                          ? null
                          : ElevatedButton(
                            onPressed: () async {
                              await kungfu.change(item.kungfuId, user);
                            },
                            child: Text(item.working ? "修炼中" : "改修"),
                          ),
                  children: <Widget>[
                    Text(
                      "${attributes[item.myattribute]} 属性，最高可修炼至 ${levels[item.level]} 境界",
                    ),
                  ],
                );
              }).toList(),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, int level, int attribute) {
    final total = KungfuModel.powersSum(level);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CreateCharacterDialog(level, total, attribute);
      },
    );
  }
}

class CreateCharacterDialog extends StatefulWidget {
  final int total;
  final int level;
  final int attribute;

  const CreateCharacterDialog(this.level, this.total, this.attribute, {super.key});

  @override
  CreateCharacterDialogState createState() => CreateCharacterDialogState();
}

class CreateCharacterDialogState extends State<CreateCharacterDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _attackController = TextEditingController();
  final TextEditingController _defenseController = TextEditingController();
  final TextEditingController _hitController = TextEditingController();
  final TextEditingController _dodgeController = TextEditingController();
  String? _error;
  bool _loading = false;

  // 验证属性值在 0-100 之间
  String? _validateStat(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName cannot be empty';
    }
    final intValue = int.tryParse(value);
    if (intValue == null || intValue < 0 || intValue > widget.total) {
      return '$fieldName must be between 0 and ${widget.total}';
    }
    return null;
  }

  void _submitData(BuildContext context) async {
    setState(() {
      _error = null;
    });

    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final hp = int.parse(_hpController.text);
      final attack = int.parse(_attackController.text);
      final defense = int.parse(_defenseController.text);
      final hit = int.parse(_hitController.text);
      final dodge = int.parse(_dodgeController.text);

      if (hp + attack + defense + hit + dodge != widget.total) {
        setState(() {
          _error = "Not equal ${widget.total}";
        });
        return;
      }

      setState(() {
        _loading = true;
      });

      final res = await context.read<KungfuModel>().create(
        name,
        hp,
        attack,
        defense,
        hit,
        dodge,
      );

      _loading = false;
      if (res) {
        if (context.mounted) Navigator.of(context).pop();
      } else {
        setState(() {
          _error = "Failure";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("创建功法 (${levels[widget.level]})"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${attributes[widget.attribute]} 属性，战力增强总和 ${widget.total}%"),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '名称'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Name cannot be empty'
                            : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _hpController,
                decoration: InputDecoration(
                  labelText: '生命增强 (0-${widget.total})',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => _validateStat(value, 'HP'),
              ),
              TextFormField(
                controller: _attackController,
                decoration: InputDecoration(
                  labelText: '攻击增强 (0-${widget.total})',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => _validateStat(value, 'Attack'),
              ),
              TextFormField(
                controller: _defenseController,
                decoration: InputDecoration(
                  labelText: '防御增强 (0-${widget.total})',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => _validateStat(value, 'Defense'),
              ),
              TextFormField(
                controller: _hitController,
                decoration: InputDecoration(
                  labelText: '暴击增强 (0-${widget.total})',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => _validateStat(value, 'Hit'),
              ),
              TextFormField(
                controller: _dodgeController,
                decoration: InputDecoration(
                  labelText: '闪避增强 (0-${widget.total})',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => _validateStat(value, 'Dodge'),
              ),
              if (_error != null) Text(_error ?? ''),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : () => _submitData(context),
          child: Text(_loading ? '创建中' : '创建'),
        ),
      ],
    );
  }
}
