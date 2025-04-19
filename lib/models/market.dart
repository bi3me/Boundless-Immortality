import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'material.dart';
import 'kungfu.dart';
import 'elixir.dart';
import 'weapon.dart';
import '../common/auth_http.dart';

class MarketItem {
  final int id;
  final int mtype;
  final int userId;
  final int itemId;
  final String itemName;
  final int itemAttribute;
  final int coin;

  MarketItem(
    this.id,
    this.mtype,
    this.userId,
    this.itemId,
    this.itemName,
    this.itemAttribute,
    this.coin,
  );
}

class MarketModel extends ChangeNotifier {
  Map<int, MarketItem> materials = {};
  Map<int, MarketItem> kungfus = {};
  Map<int, MarketItem> elixirs = {};
  Map<int, MarketItem> weapons = {};

  Future<Map<String, dynamic>?> fetchItem(int id) async {
    final response = await AuthHttpClient().get(
      AuthHttpClient.uri('users/market-item/$id')
    );
    return AuthHttpClient.res(response);
  }

  Future<bool> create(int mtype, int id, int coin) async {
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri('users/market'),
      body: AuthHttpClient.form({'mtype': mtype, 'item_id': id, 'coin': coin}),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      return false;
    } else {
      fromNetwork(data, mtype);
      notifyListeners();
      return true;
    }
  }

  Future<void> buy(int mtype, int id, BuildContext context) async {
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/market/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      if (context.mounted) {
        switch (mtype) {
          case 1:
            materials.remove(id);
            context.read<MaterialModel>().load(true);
            break;
          case 2:
            kungfus.remove(id);
            context.read<KungfuModel>().load(true);
            break;
          case 3:
            elixirs.remove(id);
            context.read<ElixirModel>().load(true);
            break;
          case 4:
            weapons.remove(id);
            context.read<WeaponModel>().load(true);
            break;
          default:
            break;
        }
      }
      notifyListeners();
    }
  }

  void fromNetwork(Map<String, dynamic> item, int mtype) {
    final id = item['id'];
    final mtype = item['mtype'];
    final userId = item['user_id'];
    final itemId = item['item_id'];
    final itemName = item['item_name'];
    final itemAttribute = item['item_attribute'];
    final coin = item['coin'];
    final m = MarketItem(
      id,
      mtype,
      userId,
      itemId,
      itemName,
      itemAttribute,
      coin,
    );

    switch (mtype) {
      case 1:
        materials[id] = m;
      case 2:
        kungfus[id] = m;
      case 3:
        elixirs[id] = m;
      case 4:
        weapons[id] = m;
      default:
        break;
    }
  }

  /// Loading markets
  Future<void> load() async {
    // load materials type: 1
    final response1 = await AuthHttpClient().get(
      AuthHttpClient.uri('users/market/1'),
    );

    final data1 = AuthHttpClient.res(response1);
    if (data1 != null) {
      materials.clear();
      for (var item in data1['data']) {
        fromNetwork(item, 1);
      }

      notifyListeners();
    }

    // load materials type: 2
    final response2 = await AuthHttpClient().get(
      AuthHttpClient.uri('users/market/2'),
    );

    final data2 = AuthHttpClient.res(response2);
    if (data2 != null) {
      kungfus.clear();
      for (var item in data2['data']) {
        fromNetwork(item, 2);
      }

      notifyListeners();
    }

    // load materials type: 3
    final response3 = await AuthHttpClient().get(
      AuthHttpClient.uri('users/market/3'),
    );

    final data3 = AuthHttpClient.res(response3);
    if (data3 != null) {
      elixirs.clear();
      for (var item in data3['data']) {
        fromNetwork(item, 3);
      }

      notifyListeners();
    }

    // load materials type: 4
    final response4 = await AuthHttpClient().get(
      AuthHttpClient.uri('users/market/4'),
    );

    final data4 = AuthHttpClient.res(response4);
    if (data4 != null) {
      weapons.clear();
      for (var item in data4['data']) {
        fromNetwork(item, 4);
      }

      notifyListeners();
    }
  }
}
