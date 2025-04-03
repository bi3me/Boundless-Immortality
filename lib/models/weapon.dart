import 'package:flutter/foundation.dart';

import 'user.dart';
import '../common/auth_http.dart';

class WeaponItem {
  final int weaponId;
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
  final int? nftOwner;
  final String? nftName;
  int number;
  bool working;

  WeaponItem(
    this.weaponId,
    this.name,
    this.working,
    this.number,
    this.attribute,
    this.level,
    this.pos,
    this.powerHp,
    this.powerAttack,
    this.powerDefense,
    this.powerHit,
    this.powerDodge,
    this.material,
    this.nftOwner,
    this.nftName,
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

  List<(int, String)> availableForSale() {
    List<(int, String)> list = [];
    items.forEach((_, v) {
      if (v.nftOwner != null &&
          ((v.number > 1 && v.working) || (v.number > 0 && !v.working))) {
        list.add((v.weaponId, v.nftName ?? v.name));
      }
    });

    return list;
  }

  Future<void> change(int pos, int weaponId, UserModel user) async {
    if (items[weaponId]?.pos != pos) {
      return;
    }

    items[weaponId]?.working = true;
    items[poses[pos]?[0]]?.working = false;

    poses[pos]?.remove(weaponId);
    poses[pos]?.insert(0, weaponId);

    // send to service
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/weapons-wear/$weaponId"),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      // none
    } else {
      user.fromNetwork(data); // update user
      notifyListeners();
    }
  }

  Future<bool> create(Map<int, int> materials, String name, int pos) async {
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
      notifyListeners();
      return true;
    }
  }

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> item) {
    final weaponId = item['weapon_id'];
    final name = item['name'];
    final working = item['working'];
    final number = item['num'];
    final attribute = item['attribute'];
    final level = item['level'];
    final pos = item['pos'];
    final powerHp = item['power_hp'];
    final powerAttack = item['power_attack'];
    final powerDefense = item['power_defense'];
    final powerHit = item['power_hit'];
    final powerDodge = item['power_dodge'];
    final material = item['materials'];
    final nftOwner = item['nft_owner'];
    final nftName = item['nft_name'];

    items[weaponId] = WeaponItem(
      weaponId,
      name,
      working,
      number,
      attribute,
      level,
      pos,
      powerHp,
      powerAttack,
      powerDefense,
      powerHit,
      powerDodge,
      material,
      nftOwner,
      nftName,
    );

    final has = poses[pos]?.contains(weaponId) ?? false;
    if (!has) {
      if (poses[pos] == null) {
        poses[pos] = [weaponId];
      } else {
        poses[pos]?.add(weaponId);
      }
    }
  }

  /// Loading kungfus
  Future<void> load() async {
    if (items.isEmpty) {
      final response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/weapons'),
      );

      final data = AuthHttpClient.res(response);
      if (data != null) {
        poses.clear();
        for (var item in data['data']) {
          fromNetwork(item);
        }

        notifyListeners();
      }
    }
  }
}
