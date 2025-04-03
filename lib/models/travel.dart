import 'dart:math';

import 'package:flutter/foundation.dart';

import 'material.dart';
import '../common/auth_http.dart';

class TravelItem {
  final int id;
  final int ttype;
  final String name;
  final String content;
  final int power;
  final int? material;
  final DateTime createdAt;

  const TravelItem(
    this.id,
    this.ttype,
    this.name,
    this.content,
    this.power,
    this.material,
    this.createdAt,
  );

  MyTravelItem toMy() {
    return MyTravelItem(id, ttype, name, material == null, DateTime.now());
  }
}

class MyTravelItem {
  final int travelId;
  final int ttype;
  final String name;
  final bool material;
  final DateTime createdAt;

  const MyTravelItem(
    this.travelId,
    this.ttype,
    this.name,
    this.material,
    this.createdAt,
  );
}

class TravelModel extends ChangeNotifier {
  int latest = 0;
  Map<int, MyTravelItem> history = {};
  TravelItem? mine;

  bool avaiable() {
    if (history.length >= 20) {
      DateTime now = DateTime.now();
      final first = history.keys.first;
      final firstTime = history[first]?.createdAt ?? now;
      Duration difference = now.difference(firstTime);
      return difference.inHours >= 24;
    } else {
      return true;
    }
  }

  Future<bool> create(String content) async {
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri('users/travel'),
      body: AuthHttpClient.form({'content': content}),
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

  Future<(TravelItem?, MaterialItem?)> random() async {
    if (!avaiable()) {
      return (null, null);
    }
    print(latest);

    Random random = Random();
    final id = random.nextInt(latest) + 1;
    final response = await AuthHttpClient().get(
      AuthHttpClient.uri("users/travel/$id"),
    );

    var data = AuthHttpClient.res(response);
    if (data != null) {
      final newTravel = itemFromNetwork(data['travel']);

      // add to history
      final myTravel = newTravel.toMy();
      if (history.length >= 20) {
        final first = history.keys.first;
        history.remove(first);
      }
      history[myTravel.travelId] = myTravel;

      MaterialItem? mitem;
      if (data.containsKey('material')) {
        // update materials, but not mymaterial, so change it
        data['material']['material_id'] = data['material']['id'];
        data['material']['num'] = 1;
        mitem = MaterialModel.parseNetwork(data['material']);
      }
      notifyListeners();

      return (newTravel, mitem);
    } else {
      return (null, null);
    }
  }

  Future<bool> solve(int id, MaterialModel material) async {
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/travel/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      material.fromNetwork(data);
      return true;
    } else {
      return false;
    }
  }

  TravelItem itemFromNetwork(Map<String, dynamic> item) {
    final id = item['id'];
    final ttype = item['ttype'];
    final name = item['name'];
    final content = item['content'];
    final power = item['power'];
    final material = item['material_id'];
    final updatedAt = DateTime.parse(item['updated_at']);

    return TravelItem(id, ttype, name, content, power, material, updatedAt);
  }

  void fromNetwork(Map<String, dynamic> item) {
    final travelId = item['travel_id'];
    final ttype = item['ttype'];
    final name = item['name'];
    final material = item['material'];
    final createdAt = DateTime.parse(item['created_at']);
    final t = MyTravelItem(travelId, ttype, name, material, createdAt);

    if (history.length >= 20) {
      final first = history.keys.first;
      history.remove(first);
    }
    history[travelId] = t;
  }

  /// Loading travels
  Future<void> load() async {
    // load latest travel id
    final response = await AuthHttpClient().get(
      AuthHttpClient.uri('users/travel'),
    );
    final data = AuthHttpClient.res(response);

    if (data != null) {
      latest = data['latest'];
      if (history.isEmpty) {
        for (var item in data['history']) {
          fromNetwork(item);
        }
        notifyListeners();
      }
    }
  }
}
