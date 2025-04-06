import 'dart:math';

import 'package:flutter/foundation.dart';

import 'material.dart';
import '../common/auth_http.dart';

const int travelMax = 20;

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
    return MyTravelItem(id, ttype, name, material != null, DateTime.now());
  }
}

class MyTravelItem {
  final int travelId;
  final int ttype;
  final String name;
  bool material;
  final DateTime createdAt;

  MyTravelItem(
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
  Map<int, (TravelItem, MaterialItem?)> historyItems = {};
  TravelItem? mine;

  void clear() {
    latest = 0;
    history.clear();
    historyItems.clear();
    mine = null;
  }

  bool avaiable() {
    if (history.length >= travelMax) {
      DateTime now = DateTime.now();
      final first = history.keys.first;
      final firstTime = history[first]?.createdAt ?? now;
      Duration difference = now.difference(firstTime);
      return difference.inHours >= 24;
    } else {
      return true;
    }
  }

  Future<(TravelItem?, MaterialItem?)> show(int id) async {
    if (historyItems.containsKey(id)) {
      final (t, m) = historyItems[id] ?? (null, null);
      return (t, m);
    }

    if (history.containsKey(id)) {
      return await doTravel(id);
    }

    return (null, null);
  }

  Future<(TravelItem?, MaterialItem?)> random() async {
    if (!avaiable()) {
      return (null, null);
    }

    Random random = Random();
    final id = random.nextInt(latest) + 1;
    return await doTravel(id);
  }

  Future<(TravelItem?, MaterialItem?)> doTravel(int id) async {
    final response = await AuthHttpClient().get(
      AuthHttpClient.uri("users/travel/$id"),
    );

    var data = AuthHttpClient.res(response);
    if (data != null) {
      final newTravel = itemFromNetwork(data['travel']);

      // add to history
      final myTravel = newTravel.toMy();
      if (!history.containsKey(id)) {
        if (history.length >= travelMax) {
          final first = history.keys.first;
          history.remove(first);
        }
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

      historyItems[newTravel.id] = (newTravel, mitem);
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
      history[id]?.material = false;
      notifyListeners();
      return true;
    } else {
      return false;
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
      mine = itemFromNetwork(data);
      notifyListeners();
      return true;
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

    if (history.length >= travelMax) {
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
      if (data['mine'] != null) {
        mine = itemFromNetwork(data['mine']);
      }
    }
  }
}
