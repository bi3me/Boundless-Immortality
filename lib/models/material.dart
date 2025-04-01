import 'package:flutter/foundation.dart';

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

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> item) {
    final materialId = item['material_id'];
    final number = item['num'];
    final name = item['name'];
    final mtype = item['mtype'];
    final attribute = item['attribute'];
    final levelAdd = item['level_add'];
    final powersZip = item['powers'];
    final mitem = MaterialItem(
      materialId,
      number,
      name,
      mtype,
      attribute,
      levelAdd,
      powersZip,
    );

    switch (mtype) {
      case 1:
        elixirsItems[materialId] = mitem;
        break;
      case 2:
        weaponItems[materialId] = mitem;
        break;
      default:
        break;
    }
  }

  /// Loading kungfus
  Future<void> load() async {
    if (elixirsItems.isEmpty && weaponItems.isEmpty) {
      var response = await AuthHttpClient().get(
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
