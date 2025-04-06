import 'package:flutter/foundation.dart';

import '../common/auth_http.dart';
import '../models/user.dart';

const int kungfuEveryLevelMax = 2;

class KungfuItem {
  final int kungfuId;
  final String name;
  final int attribute;
  final int identity;
  final int level;
  final int? nftOwner;
  final String? nftName;
  final int? nftAttribute;
  bool working;
  int number;

  int get myattribute => nftAttribute ?? attribute;

  KungfuItem(
    this.kungfuId,
    this.name,
    this.attribute,
    this.working,
    this.number,
    this.identity,
    this.level,
    this.nftOwner,
    this.nftName,
    this.nftAttribute,
  );

  (int, int, int, int, int) powers() {
    final (d1, r1) = (identity ~/ 100000000, identity % 100000000);
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
      if (v.nftOwner != null &&
          ((v.number > 1 && v.working) || (v.number > 0 && !v.working))) {
        list.add((v.kungfuId, v.nftName ?? v.name));
      }
    });

    return list;
  }

  Future<void> change(int kungfuId, UserModel user) async {
    // send to service
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/kungfus-change/$kungfuId"),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      items[nowWorking]?.working = false;
      items[kungfuId]?.working = true;
      nowWorking = kungfuId;

      // data is user
      user.update(data);

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

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> item) {
    final kungfuId = item['kungfu_id'];
    final name = item['name'];
    final attribute = item['attribute'];
    final working = item['working'];
    final number = item['num'];
    final identity = item['identity'];
    final level = item['level'];
    final nftOwner = item['nft_owner'];
    final nftName = item['nft_name'];
    final nftAttribute = item['nft_attribute'];
    if (working) {
      nowWorking = kungfuId;
    }

    items[kungfuId] = KungfuItem(
      kungfuId,
      name,
      attribute,
      working,
      number,
      identity,
      level,
      nftOwner,
      nftName,
      nftAttribute,
    );

    final count = countByLevel[level] ?? 0;
    if (count == 0) {
      countByLevel[level] = 1;
    } else {
      countByLevel[level] = count + 1;
    }
  }

  /// Loading kungfus
  Future<void> load() async {
    if (items.isEmpty) {
      final response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/kungfus'),
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
