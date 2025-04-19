import 'package:flutter/foundation.dart';

import 'user.dart';
import 'material.dart';
import '../common/auth_http.dart';

const elixirEveryLevelMax = 20;

class ElixirItem {
  final int id;
  final String name;
  final int attribute;
  final int level;
  final int levelAdd;
  final int powerHp;
  final int powerAttack;
  final int powerDefense;
  final int powerHit;
  final int powerDodge;
  final String material;
  int number;
  bool locking;

  ElixirItem(
    this.id,
    this.name,
    this.attribute,
    this.level,
    this.levelAdd,
    this.powerHp,
    this.powerAttack,
    this.powerDefense,
    this.powerHit,
    this.powerDodge,
    this.material,
    this.number,
    this.locking,
  );

  Map<int, int> materials() {
    return Map.fromEntries(
      material.split('_').map((pair) {
        var keyValue = pair.split('-');
        return MapEntry(int.parse(keyValue[0]), int.parse(keyValue[1]));
      }),
    );
  }

  static String materialsZip(Map<int, int> map) {
    List<String> zip = [];
    map.forEach((k, v) {
      zip.add("$k-$v");
    });

    return zip.join('_');
  }
}

class ElixirModel extends ChangeNotifier {
  Map<int, ElixirItem> items = {};
  Map<int, int> countByLevel = {};

  void clear() {
    items.clear();
    countByLevel.clear();
  }

  int availableForCreate(int level) {
    final already = countByLevel[level] ?? 0;
    int times = 0;
    if (already < elixirEveryLevelMax) {
      times = elixirEveryLevelMax - already;
    }
    return times;
  }

  List<(int, String)> availableForSale() {
    List<(int, String)> list = [];
    items.forEach((_, v) {
      if (!v.locking) {
        list.add((v.id, v.name));
      }
    });

    return list;
  }

  void eat(int id, UserModel user) async {
    if ((items[id]?.number ?? 0) < 1) {
      return;
    }

    // send to service
    var response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/elixirs-eat/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      // none
    } else {
      items[id]?.number -= 1;
      if (items[id]?.number == 0) {
        items.remove(id);
      }

      user.update(data); // update user
      notifyListeners();
    }
  }

  Future<void> unlock(int id, UserModel user) async {
    // send to service
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/elixirs-unlock/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      items[id]?.locking = false;
      user.settle();
      notifyListeners();
    }
  }

  Future<bool> create(
    Map<int, int> materials,
    String name,
    MaterialModel mm,
  ) async {
    final materialsZip = ElixirItem.materialsZip(materials);
    var response = await AuthHttpClient().post(
      AuthHttpClient.uri('users/elixirs'),
      body: AuthHttpClient.form({'name': name, 'materials_zip': materialsZip}),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      return false;
    } else {
      fromNetwork(data);
      mm.elixirUsed(materials);
      notifyListeners();
      return true;
    }
  }

  static ElixirItem parseNetwork(Map<String, dynamic> item) {
    final id = item['id'];
    final name = item['name'];
    final attribute = item['attribute'];
    final level = item['level'];
    final levelAdd = item['level_add'];
    final powerHp = item['power_hp'];
    final powerAttack = item['power_attack'];
    final powerDefense = item['power_defense'];
    final powerHit = item['power_hit'];
    final powerDodge = item['power_dodge'];
    final material = item['materials'];
    final number = item['num'];
    final locking = item['locking'];

    return ElixirItem(
      id,
      name,
      attribute,
      level,
      levelAdd,
      powerHp,
      powerAttack,
      powerDefense,
      powerHit,
      powerDodge,
      material,
      number,
      locking,
    );
  }

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> data) {
    final item = parseNetwork(data);
    items[item.id] = item;

    final count = countByLevel[item.level] ?? 0;
    if (count == 0) {
      countByLevel[item.level] = 1;
    } else {
      countByLevel[item.level] = count + 1;
    }
  }

  /// Loading elixirs
  Future<void> load(bool force) async {
    if (force || items.isEmpty) {
      final response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/elixirs'),
      );

      final data = AuthHttpClient.res(response);
      if (data != null) {
        clear();
        for (var item in data['data']) {
          fromNetwork(item);
        }

        notifyListeners();
      }
    }
  }
}
