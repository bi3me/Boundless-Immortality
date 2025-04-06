import 'package:flutter/foundation.dart';

import 'user.dart';
import 'material.dart';
import '../common/auth_http.dart';

const elixirEveryLevelMax = 20;

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
      if (v.nftOwner != null && v.number > 1) {
        list.add((v.elixirId, v.nftName ?? v.name));
      }
    });

    return list;
  }

  void eat(int elixirId, UserModel user) async {
    items[elixirId]?.number -= 1;
    if (items[elixirId]?.number == 0) {
      items.remove(elixirId);
    }

    // send to service
    var response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/elixirs-eat/$elixirId"),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      // none
    } else {
      user.update(data); // update user
      notifyListeners();
    }
  }

  Future<bool> create(Map<int, int> materials, String name) async {
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
      notifyListeners();
      return true;
    }
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

    final count = countByLevel[level] ?? 0;
    if (count == 0) {
      countByLevel[level] = 1;
    } else {
      countByLevel[level] = count + 1;
    }
  }

  /// Loading elixirs
  Future<void> load() async {
    if (items.isEmpty) {
      final response = await AuthHttpClient().get(
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
