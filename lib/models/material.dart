import 'package:boundless_immortality/common/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common/auth_http.dart';

class MaterialItem {
  final int materialId;
  final String name;
  final int mtype;
  final int attribute;
  final int levelAdd;
  final int powersZip;
  int number;

  MaterialItem(
    this.materialId,
    this.number,
    this.name,
    this.mtype,
    this.attribute,
    this.levelAdd,
    this.powersZip,
  );

  (int, int, int, int, int) powers() {
    final (d1, r1) = (powersZip ~/ 100000000, powersZip % 100000000);
    final (d2, r2) = (r1 ~/ 1000000, r1 % 1000000);
    final (d3, r3) = (r2 ~/ 10000, r2 % 10000);
    final (d4, d5) = (r3 ~/ 100, r3 % 100);

    return (d5, d4, d3, d2, d1);
  }
}

class MaterialModel extends ChangeNotifier {
  Map<int, MaterialItem> elixirsItems = {};
  Map<int, MaterialItem> weaponItems = {};

  List<MaterialItem> get items => [
    ...elixirsItems.values,
    ...weaponItems.values,
  ];

  void clear() {
    elixirsItems.clear();
    weaponItems.clear();
  }

  List<(int, String)> availableForSale() {
    List<(int, String)> list = [];
    elixirsItems.forEach((_, v) {
      if (v.number > 0) {
        list.add((v.materialId, v.name));
      }
    });
    weaponItems.forEach((_, v) {
      if (v.number > 0) {
        list.add((v.materialId, v.name));
      }
    });

    return list;
  }

  void elixirUsed(Map<int, int> items) {
    items.forEach((k, v) {
      elixirsItems[k]?.number -= v;
    });

    notifyListeners();
  }

  void weaponUsed(Map<int, int> items) {
    items.forEach((k, v) {
      weaponItems[k]?.number -= v;
    });

    notifyListeners();
  }

  void recycle(int id) async {
    //
  }

  static MaterialItem parseNetwork(Map<String, dynamic> item) {
    final materialId = item['material_id'];
    final number = item['num'];
    final name = item['name'];
    final mtype = item['mtype'];
    final attribute = item['attribute'];
    final levelAdd = item['level_add'];
    final powersZip = item['powers'];
    return MaterialItem(
      materialId,
      number,
      name,
      mtype,
      attribute,
      levelAdd,
      powersZip,
    );
  }

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> item) {
    final mitem = parseNetwork(item);

    switch (mitem.mtype) {
      case 1:
        elixirsItems[mitem.materialId] = mitem;
        break;
      case 2:
        weaponItems[mitem.materialId] = mitem;
        break;
      default:
        break;
    }
  }

  /// Loading kungfus
  Future<void> load() async {
    if (elixirsItems.isEmpty && weaponItems.isEmpty) {
      final response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/materials'),
      );

      final data = AuthHttpClient.res(response);
      if (data != null) {
        for (var item in data['data']) {
          fromNetwork(item);
        }

        notifyListeners();
      }
    }
  }
}

class MaterialItemWidget extends StatelessWidget {
  final int id;
  final String name;
  final int attribute;
  final int number;
  final bool lock;
  final Function(int) onClick;

  const MaterialItemWidget(
    this.id,
    this.name,
    this.attribute,
    this.number,
    this.onClick,
    this.lock, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !lock && number != 0 ? () => onClick(id) : null,
      child: Container(
        decoration: BoxDecoration(
          color:
              lock
                  ? Color(0x40CCCCD6)
                  : (attribute != 0
                      ? (number == 0 ? Color(0x40CCCCD6) : Color(0xBFADA595))
                      : Colors.white),
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Text(
                  name,
                  style: TextStyle(fontSize: 14, color: Colors.black),
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
  }
}
