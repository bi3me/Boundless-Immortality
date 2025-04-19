import 'package:flutter/foundation.dart';

import '../common/auth_http.dart';
import '../models/user.dart';

const int kungfuEveryLevelMax = 2;

class KungfuItem {
  final int id;
  final String name;
  final int attribute;
  final int level;
  final int powers;
  bool working;
  bool locking;

  KungfuItem(
    this.id,
    this.name,
    this.attribute,
    this.level,
    this.powers,
    this.working,
    this.locking,
  );

  (int, int, int, int, int) getPowers() {
    final (d1, r1) = (powers ~/ 100000000, powers % 100000000);
    final (d2, r2) = (r1 ~/ 1000000, r1 % 1000000);
    final (d3, r3) = (r2 ~/ 10000, r2 % 10000);
    final (d4, d5) = (r3 ~/ 100, r3 % 100);

    return (d5, d4, d3, d2, d1);
  }
}

class KungfuModel extends ChangeNotifier {
  Map<int, KungfuItem> items = {};
  int nowWorking = 0;
  Map<int, int> countByLevel = {};

  KungfuItem? get working => items[nowWorking];

  static int powersSum(int level) {
    switch (level) {
      case 1:
        return 10;
      case 2:
        return 20;
      case 3:
        return 30;
      case 4:
        return 50;
      case 5:
        return 60;
      case 6:
        return 70;
      case 7:
        return 80;
      case 8:
        return 90;
      default:
        return 0;
    }
  }

  void clear() {
    items.clear();
    nowWorking = 0;
    countByLevel.clear();
  }

  int availableForCreate(int level) {
    final already = countByLevel[level] ?? 0;
    int times = 0;
    if (already < kungfuEveryLevelMax) {
      times = kungfuEveryLevelMax - already;
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

  Future<void> change(int id, UserModel user) async {
    // send to service
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/kungfus-change/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      items[nowWorking]?.working = false;
      items[id]?.working = true;
      nowWorking = id;

      // data is user
      user.update(data);

      notifyListeners();
    }
  }

  Future<void> unlock(int id, UserModel user) async {
    // send to service
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/kungfus-unlock/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      items[id]?.locking = false;
      user.settle();
      notifyListeners();
    }
  }

  Future<bool> create(
    String name,
    int hp,
    int attack,
    int defense,
    int hit,
    int dodge,
  ) async {
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri('users/kungfus'),
      body: AuthHttpClient.form({
        'name': name,
        'power_hp': hp,
        'power_attack': attack,
        'power_defense': defense,
        'power_hit': hit,
        'power_dodge': dodge,
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

  static KungfuItem parseNetwork(Map<String, dynamic> item) {
    final id = item['id'];
    final name = item['name'];
    final attribute = item['attribute'];
    final level = item['level'];
    final powers = item['powers'];
    final working = item['working'];
    final locking = item['locking'];

    return KungfuItem(id, name, attribute, level, powers, working, locking);
  }

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> data) {
    final item = parseNetwork(data);

    if (item.working) {
      nowWorking = item.id;
    }

    items[item.id] = item;

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
        AuthHttpClient.uri('users/kungfus'),
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
