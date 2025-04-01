import 'package:flutter/foundation.dart';

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
}

class WeaponModel extends ChangeNotifier {
  Map<int, WeaponItem> items = {};
  Map<int, int> pos = {};

  void change(int weaponId) {
    items[weaponId]?.working = true;
    items[pos[items[weaponId]?.pos]]?.working = false;

    // TODO send to service

    notifyListeners();
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
  }

  /// Loading kungfus
  Future<void> load() async {
    if (items.isEmpty) {
      var response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/weapons'),
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
