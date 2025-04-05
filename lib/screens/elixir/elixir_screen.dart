import 'package:boundless_immortality/models/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../style/responsive_screen.dart';
import '../../models/elixir.dart';
import '../../models/material.dart';
import '../../common/constants.dart';

class PlayElixirScreen extends StatefulWidget {
  // const PlayKungfuScreen({Key? key}) : super(key: key);
  const PlayElixirScreen({super.key});

  @override
  PlayElixirState createState() => PlayElixirState();
}

class PlayElixirState extends State<PlayElixirScreen> {
  int myLevel = 0;
  bool _canCreateNew = true;
  bool _loading = false;
  int? _selectedElixir;

  Map<int, int> selectedMaterialsNum = {};
  List<int> selectedMaterialsIds = [];
  Map<int, int> tmpMaterialsNum = {};

  @override
  Widget build(BuildContext context) {
    final materials = context.watch<MaterialModel>().elixirsItems;
    final elixirs = context.watch<ElixirModel>();
    if (tmpMaterialsNum.isEmpty && materials.isNotEmpty) {
      materials.forEach((k, v) {
        tmpMaterialsNum[k] = v.number;
      });
    }
    myLevel = context.watch<UserModel>().level;
    final availableTimes = elixirs.availableForCreate(myLevel);
    _canCreateNew = _selectedElixir != null || availableTimes > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ResponsiveScreen(
        squarishMainArea: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecipeSelection(elixirs.items),
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
                    _selectedElixir != null
                        ? _startAlchemy(context, elixirs)
                        : showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return CreateCharacterDialog(selectedMaterialsNum);
                          },
                        );
                  },
          child: Text(_loading ? '炼丹中' : "炼丹 (剩 $availableTimes 次)"),
        ),
      ),
    );
  }

  Widget _buildRecipeSelection(Map<int, ElixirItem> items) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: double.infinity,
        child: DropdownButton<int>(
          isExpanded: true,
          hint: Text("选择丹方"),
          value: _selectedElixir,
          onChanged: (newRecipe) {
            setState(() {
              _selectedElixir = newRecipe;
              // TODO check materials
              // selectedIngredients = List.from(recipes[newRecipe!] ?? []);
            });
          },
          items:
              items.values.map((item) {
                return DropdownMenuItem<int>(
                  value: item.elixirId,
                  child: Text(item.name),
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
    setState(() {});
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

    setState(() {});
  }

  void _startAlchemy(BuildContext context, ElixirModel elixirs) async {
    setState(() {
      _loading = true;
    });

    final res = await elixirs.create(selectedMaterialsNum, "");

    _loading = false;
    if (res) {
      // success
    }
  }
}

class CreateCharacterDialog extends StatefulWidget {
  final Map<int, int> materials;

  const CreateCharacterDialog(this.materials, {super.key});

  @override
  CreateCharacterDialogState createState() => CreateCharacterDialogState();
}

class CreateCharacterDialogState extends State<CreateCharacterDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _error;
  bool _loading = false;

  void _submitData(BuildContext context) async {
    setState(() {
      _error = null;
    });

    final name = _nameController.text;
    if (name.isEmpty || name.length > 20) {
      setState(() {
        _error = "Empty or too long";
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    final res = await context.read<ElixirModel>().create(
      widget.materials,
      name,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('全新丹药'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("木属性，战力总和 100, 修为增加 100"),
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
