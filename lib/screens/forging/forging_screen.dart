import 'package:boundless_immortality/models/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';
import '../../models/weapon.dart';
import '../../models/material.dart';
import '../../common/constants.dart';

class PlayForgingScreen extends StatefulWidget {
  // const PlayKungfuScreen({Key? key}) : super(key: key);
  const PlayForgingScreen({super.key});

  @override
  PlayForgingState createState() => PlayForgingState();
}

class PlayForgingState extends State<PlayForgingScreen> {
  int myLevel = 0;
  bool _canCreateNew = true;
  bool _loading = false;
  int? _selectedWeapon;
  Map<int, WeaponItem> _weaponsItems = {};
  Map<int, bool> _disabledWeapons = {};

  Map<int, int> selectedMaterialsNum = {};
  List<int> selectedMaterialsIds = [];
  Map<int, int> tmpMaterialsNum = {};

  @override
  Widget build(BuildContext context) {
    final mm = context.watch<MaterialModel>();
    final materials = mm.weaponItems;
    final forgings = context.watch<WeaponModel>();
    if (tmpMaterialsNum.isEmpty && materials.isNotEmpty) {
      materials.forEach((k, v) {
        tmpMaterialsNum[k] = v.number;
      });
    }
    myLevel = context.watch<UserModel>().level;
    final availableTimes = forgings.availableForCreate(myLevel);
    _canCreateNew = _selectedWeapon != null || availableTimes > 0;
    _weaponsItems = forgings.items;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecipeSelection(materials),
            _buildAlchemyGrid(materials),
            Divider(),
            _buildMaterialsSelection(materials.values.toList()),
            SizedBox(height: 20),
          ],
        ),
        rectangularMenuArea: FilledButton(
          onPressed:
              selectedMaterialsIds.isEmpty || _loading || !_canCreateNew
                  ? null
                  : () {
                    _selectedWeapon != null
                        ? _startAlchemy(context, forgings, mm)
                        : showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return CreateCharacterDialog(
                              selectedMaterialsNum,
                              successCallback,
                            );
                          },
                        );
                  },
          child: Text(
            _loading ? '炼制中' : "炼器 (${levels[myLevel]}剩 $availableTimes 次)",
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeSelection(Map<int, MaterialItem> items) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity,
        child: DropdownButton<int>(
          isExpanded: true,
          hint: Text("选择图纸"),
          value: _selectedWeapon,
          onChanged: _selectWeapon,
          items:
              _weaponsItems.values.map((item) {
                final id = item.id;
                bool avaiable = true;
                final itemMaterials = item.materials();
                final pos = itemMaterials.remove(0) ?? 0;
                if (itemMaterials.length > myLevel) {
                  avaiable = false;
                  _disabledWeapons[id] = false;
                } else {
                  itemMaterials.forEach((k, v) {
                    final n = items[k]?.number ?? 0;
                    if (n > myLevel || n < v) {
                      avaiable = false;
                      _disabledWeapons[k] = false;
                    }
                  });
                }
                return DropdownMenuItem<int>(
                  enabled: avaiable,
                  value: id,
                  child: Text(
                    "${item.name} (${weaponPos[pos]})",
                    style: TextStyle(
                      color: avaiable ? Colors.black : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlchemyGrid(Map<int, MaterialItem> items) {
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
          bool islocked = index > myLevel - 1;
          int id = 0;
          String name = islocked ? '/' : '可放置';
          int attribute = 0;
          int number = 0;
          if (index < selectedMaterialsIds.length) {
            id = selectedMaterialsIds[index];
            name = items[id]?.name ?? '';
            attribute = items[id]?.attribute ?? 0;
            number = selectedMaterialsNum[id] ?? 0;
          }

          return MaterialItemWidget(
            id,
            name,
            attribute,
            number,
            _removeItem,
            islocked,
          );
        },
      ),
    );
  }

  Widget _buildMaterialsSelection(List<MaterialItem> items) {
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
          itemCount: items.length,
          itemBuilder: (context, index) {
            final id = items[index].materialId;
            return MaterialItemWidget(
              id,
              items[index].name,
              items[index].attribute,
              tmpMaterialsNum[id] ?? 0,
              _addItem,
              false,
            );
          },
        ),
      ),
    );
  }

  void _selectWeapon(int? index) {
    if (_disabledWeapons.containsKey(index)) {
      return;
    }

    _selectedWeapon = index;

    if (_weaponsItems[index] != null) {
      // clear old
      if (selectedMaterialsNum.isNotEmpty) {
        List<int> needRemoved = [];
        selectedMaterialsNum.forEach((k, n) {
          final tn = tmpMaterialsNum[k] ?? 0;
          tmpMaterialsNum[k] = tn + n;
          needRemoved.add(k);
        });
        for (var k in needRemoved) {
          selectedMaterialsNum.remove(k);
          selectedMaterialsIds.remove(k);
        }
      }

      // add new
      final itemMaterials = _weaponsItems[index]?.materials() ?? {};
      itemMaterials.forEach((k, n) {
        final tn = tmpMaterialsNum[k] ?? 0;
        if (tn < n) {
          return;
        }
        tmpMaterialsNum[k] = tn - n;
        selectedMaterialsNum[k] = n;
        selectedMaterialsIds.add(k);
      });
    }

    setState(() {});
  }

  void _removeItem(int index) {
    final n = selectedMaterialsNum[index];
    if (n == null) {
      return;
    }

    final tn = tmpMaterialsNum[index] ?? 0;
    tmpMaterialsNum[index] = tn + 1;

    if (n < 2) {
      selectedMaterialsNum.remove(index);
      selectedMaterialsIds.remove(index);
    } else {
      selectedMaterialsNum[index] = n - 1;
    }
    setState(() {
      _selectedWeapon = null;
    });
  }

  void _addItem(int index) {
    final tn = tmpMaterialsNum[index] ?? 0;
    if (tn < 1) {
      return;
    }
    tmpMaterialsNum[index] = tn - 1;

    final n = selectedMaterialsNum[index] ?? 0;
    if (n >= myLevel) {
      return;
    }

    if (n == 0) {
      selectedMaterialsNum[index] = 1;
      selectedMaterialsIds.add(index);
    } else {
      selectedMaterialsNum[index] = n + 1;
    }

    // check level
    if (selectedMaterialsIds.length > myLevel) {
      final fid = selectedMaterialsIds.removeAt(0);
      final fsn = selectedMaterialsNum.remove(fid) ?? 0;
      final ftn = tmpMaterialsNum[fid] ?? 0;
      tmpMaterialsNum[fid] = ftn + fsn;
    }

    setState(() {
      _selectedWeapon = null;
    });
  }

  void _startAlchemy(
    BuildContext context,
    WeaponModel weapon,
    MaterialModel mm,
  ) async {
    setState(() {
      _loading = true;
    });
    final name = _weaponsItems[_selectedWeapon]?.name ?? '';
    final pos = _weaponsItems[_selectedWeapon]?.pos ?? 1;

    final res = await weapon.create(selectedMaterialsNum, name, pos, mm);

    _loading = false;
    if (res) {
      successCallback();
      // success
    }
  }

  void successCallback() {
    setState(() {
      selectedMaterialsNum.clear();
      selectedMaterialsIds.clear();
    });
  }
}

class CreateCharacterDialog extends StatefulWidget {
  final Map<int, int> materials;
  final Function callback;

  const CreateCharacterDialog(this.materials, this.callback, {super.key});

  @override
  CreateCharacterDialogState createState() => CreateCharacterDialogState();
}

class CreateCharacterDialogState extends State<CreateCharacterDialog> {
  final TextEditingController _nameController = TextEditingController();
  int? _pos;
  String? _error;
  bool _loading = false;

  void _submitData(BuildContext context) async {
    setState(() {
      _error = null;
    });

    final name = _nameController.text;
    if (name.isEmpty || name.length > 20) {
      setState(() {
        _error = "Name empty or too long";
      });
      return;
    }
    final pos = _pos ?? 0;

    if (pos < 1 || pos > 8) {
      setState(() {
        _error = "Need position";
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    final mm = context.read<MaterialModel>();
    final res = await context.read<WeaponModel>().create(
      widget.materials,
      name,
      pos,
      mm,
    );

    _loading = false;
    if (res) {
      setState(() {
        _error = '成功放入背包！';
      });
      widget.callback();
      Future.delayed(Duration(seconds: 1), () {
        if (context.mounted) Navigator.of(context).pop();
      });
    } else {
      setState(() {
        _error = "Failure";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('全新武器'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("木属性，战力总和 100, 修为增加 100"),
            SizedBox(
              width: double.infinity,
              child: DropdownButton<int>(
                isExpanded: true,
                hint: Text("选择部位"),
                value: _pos,
                onChanged: (newPos) {
                  setState(() {
                    _pos = newPos;
                  });
                },
                items: List.generate(
                  8,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(weaponPos[index + 1]),
                  ),
                ),
              ),
            ),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '赐名'),
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
          child: Text(_loading ? '炼制中' : '炼制'),
        ),
      ],
    );
  }
}
