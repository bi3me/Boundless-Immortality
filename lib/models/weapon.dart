import 'package:flutter/foundation.dart';

import 'user.dart';
import 'material.dart';
import '../common/auth_http.dart';

const int weaponEveryLevelMax = 20;

class WeaponItem {
  final int id;
  final String name;
  final int attribute;
  final int level;
  final int pos;
  final int powerHp;
  final int powerAttack;
  final int powerDefense;
  final int powerHit;
  final int powerDodge;
  final String material;
  int number;
  bool working;
  bool locking;

  WeaponItem(
    this.id,
    this.name,
    this.attribute,
    this.level,
    this.pos,
    this.powerHp,
    this.powerAttack,
    this.powerDefense,
    this.powerHit,
    this.powerDodge,
    this.material,
    this.number,
    this.working,
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

class WeaponModel extends ChangeNotifier {
  Map<int, WeaponItem> items = {};
  Map<int, List<int>> poses = {};

  Map<int, int> countByLevel = {};

  void clear() {
    items.clear();
    poses.clear();
    countByLevel.clear();
  }

  int availableForCreate(int level) {
    final already = countByLevel[level] ?? 0;
    int times = 0;
    if (already < weaponEveryLevelMax) {
      times = weaponEveryLevelMax - already;
    }
    return times;
  }

  List<(int, String)> availableForSale() {
    List<(int, String)> list = [];
    items.forEach((_, v) {
      if (!v.locking && (v.working && v.number > 1) ||
          (!v.working && v.number > 0)) {
        list.add((v.id, v.name));
      }
    });

    return list;
  }

  Future<void> change(int pos, int id, UserModel user) async {
    if (items[id]?.pos != pos) {
      return;
    }

    // send to service
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/weapons-wear/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      // none
    } else {
      items[poses[pos]?[0]]?.working = false;
      items[id]?.working = true;

      poses[pos]?.remove(id);
      poses[pos]?.insert(0, id);

      user.update(data); // update user
      notifyListeners();
    }
  }

  Future<void> unlock(int id, UserModel user) async {
    // send to service
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/weapons-unlock/$id"),
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
    int pos,
    MaterialModel mm,
  ) async {
    final materialsZip = WeaponItem.materialsZip(materials);
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri('users/weapons'),
      body: AuthHttpClient.form({
        'name': name,
        'pos': pos,
        'materials_zip': materialsZip,
      }),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      return false;
    } else {
      fromNetwork(data);
      mm.weaponUsed(materials);
      notifyListeners();
      return true;
    }
  }

  static WeaponItem parseNetwork(Map<String, dynamic> item) {
    final id = item['id'];
    final name = item['name'];
    final attribute = item['attribute'];
    final level = item['level'];
    final pos = item['pos'];
    final powerHp = item['power_hp'];
    final powerAttack = item['power_attack'];
    final powerDefense = item['power_defense'];
    final powerHit = item['power_hit'];
    final powerDodge = item['power_dodge'];
    final material = item['materials'];
    final number = item['num'];
    final working = item['working'];
    final locking = item['locking'];

    return WeaponItem(
      id,
      name,
      attribute,
      level,
      pos,
      powerHp,
      powerAttack,
      powerDefense,
      powerHit,
      powerDodge,
      material,
      number,
      working,
      locking,
    );
  }

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> data) {
    final item = parseNetwork(data);
    items[item.id] = item;

    final has = poses[item.pos]?.contains(item.id) ?? false;
    if (!has) {
      if (poses[item.pos] == null) {
        poses[item.pos] = [item.id];
      } else {
        poses[item.pos]?.add(item.id);
      }
    }

    final count = countByLevel[item.level] ?? 0;
    if (count == 0) {
      countByLevel[item.level] = 1;
    } else {
      countByLevel[item.level] = count + 1;
    }
  }

  /// Loading kungfus
  Future<void> load(bool force) async {
    if (force || items.isEmpty) {
      final response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/weapons'),
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
