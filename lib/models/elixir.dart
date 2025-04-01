import 'package:flutter/foundation.dart';

import '../common/auth_http.dart';

class ElixirItem {
  final int elixirId;
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
  final int? nftOwner;
  final String? nftName;
  int number;

  ElixirItem(
    this.elixirId,
    this.name,
    this.attribute,
    this.number,
    this.level,
    this.levelAdd,
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

class ElixirModel extends ChangeNotifier {
  Map<int, ElixirItem> items = {};

  void eat(int elixirId) {
    items[elixirId]?.number -= 1;
    if (items[elixirId]?.number == 0) {
      items.remove(elixirId);
    }

    // TODO send to service

    notifyListeners();
  }

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> item) {
    final elixirId = item['elixir_id'];
    final name = item['name'];
    final attribute = item['attribute'];
    final number = item['num'];
    final level = item['level'];
    final levelAdd = item['level_add'];
    final powerHp = item['power_hp'];
    final powerAttack = item['power_attack'];
    final powerDefense = item['power_defense'];
    final powerHit = item['power_hit'];
    final powerDodge = item['power_dodge'];
    final material = item['materials'];
    final nftOwner = item['nft_owner'];
    final nftName = item['nft_name'];

    items[elixirId] = ElixirItem(
      elixirId,
      name,
      attribute,
      number,
      level,
      levelAdd,
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

  /// Loading elixirs
  Future<void> load() async {
    if (items.isEmpty) {
      var response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/elixirs'),
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
