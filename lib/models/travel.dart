import 'dart:math';

import 'package:flutter/foundation.dart';

import 'material.dart';
import '../common/auth_http.dart';

const int travelMax = 20;

class TravelNeighbor {
  final int id;
  final int ttype;
  final String name;

  const TravelNeighbor(this.id, this.ttype, this.name);
}

class TravelItem {
  final int id;
  final int ttype;
  final String name;
  final String content;
  final int power;
  final List<TravelNeighbor?> neighbors;
  MaterialItem? material;
  final DateTime createdAt;

  TravelItem(
    this.id,
    this.ttype,
    this.name,
    this.content,
    this.power,
    this.neighbors,
    this.material,
    this.createdAt,
  );

  MyTravelItem toMy() {
    return MyTravelItem(id, ttype, name, DateTime.now());
  }

  TravelNeighbor toNeighbor() {
    return TravelNeighbor(id, ttype, name);
  }

  static empty() {
    return TravelItem(0, 0, '', '', 0, [], null, DateTime.now());
  }
}

class MyTravelItem {
  final int travelId;
  final int ttype;
  final String name;
  final DateTime createdAt;

  MyTravelItem(this.travelId, this.ttype, this.name, this.createdAt);
}

class TravelModel extends ChangeNotifier {
  int latest = 0;
  Map<int, MyTravelItem> history = {};
  Map<int, TravelItem> historyItems = {};
  TravelItem? mine;

  TravelItem main = TravelItem.empty();
  Map<int, TravelNeighbor?> neighbors = {
    0: null,
    1: null,
    2: null,
    3: null,
    4: null,
    5: null,
    6: null,
    7: null,
    8: null,
  };

  void updateMain(TravelItem? newMain) {
    main = newMain ?? TravelItem.empty();

    // check show my travel
    if (main.id != 0) {
      // print(main.neighbors);
      neighbors[0] = main.toNeighbor();
      neighbors[1] = main.neighbors[0];
      neighbors[2] = main.neighbors[1];
      neighbors[3] = main.neighbors[2];
      neighbors[4] = main.neighbors[3];
      neighbors[5] = main.neighbors[4];
      neighbors[6] = main.neighbors[5];
      neighbors[7] = main.neighbors[6];
      neighbors[8] = main.neighbors[7];
    }

    notifyListeners();
  }

  void clear() {
    latest = 0;
    history.clear();
    historyItems.clear();
    mine = null;
    main = TravelItem.empty();
    neighbors = {
      0: null,
      1: null,
      2: null,
      3: null,
      4: null,
      5: null,
      6: null,
      7: null,
      8: null,
    };
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

  Future<bool> show(int id) async {
    if (historyItems.containsKey(id)) {
      updateMain(historyItems[id]);
      return true;
    } else {
      final newMain = await doTravel(id);
      updateMain(newMain);
      return newMain != null;
    }
  }

  Future<bool> random() async {
    if (!avaiable()) {
      return false;
    }

    Random random = Random();
    final id = random.nextInt(latest) + 1;
    final newMain = await doTravel(id);
    updateMain(newMain);
    return newMain != null;
  }

  Future<TravelItem?> doTravel(int id) async {
    final response = await AuthHttpClient().get(
      AuthHttpClient.uri("users/travel/$id"),
    );

    var data = AuthHttpClient.res(response);
    if (data != null) {
      final newTravel = itemFromNetwork(data);

      // add to history
      final myTravel = newTravel.toMy();
      if (!history.containsKey(id)) {
        if (history.length >= travelMax) {
          final first = history.keys.first;
          history.remove(first);
        }
      }

      history[myTravel.travelId] = myTravel;
      historyItems[newTravel.id] = newTravel;

      notifyListeners();
      return newTravel;
    } else {
      return null;
    }
  }

  Future<bool> solve(int id, MaterialModel material) async {
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/travel/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      material.fromNetwork(data);
      // update local
      historyItems[id]?.material = null;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> create(String content, int neighbor, int arrow) async {
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri('users/travel'),
      body: AuthHttpClient.form({
        'content': content,
        'neighbor': neighbor,
        'neighbor_arrow': arrow,
      }),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      return false;
    } else {
      mine = itemFromNetwork(data);
      // clear cache
      historyItems.clear();
      updateMain(mine);
      return true;
    }
  }

  TravelItem itemFromNetwork(Map<String, dynamic> item) {
    final id = item['id'];
    final ttype = item['ttype'];
    final name = item['name'];
    final content = item['content'];
    final power = item['power'];
    final updatedAt = DateTime.parse(item['updated_at']);
    MaterialItem? material;
    if (item['material'] != null) {
      // fix the my material
      Map<String, dynamic> mitem = item['material'];
      mitem['material_id'] = mitem['id'];
      mitem['num'] = 1;
      material = MaterialModel.parseNetwork(mitem);
    }

    List<TravelNeighbor?> neighbors = [];
    for (var neighborItem in item['neighbors']) {
      if (neighborItem != null) {
        final nid = neighborItem['id'];
        final nttype = neighborItem['ttype'];
        final nname = neighborItem['name'];
        neighbors.add(TravelNeighbor(nid, nttype, nname));
      } else {
        neighbors.add(null);
      }
    }

    return TravelItem(
      id,
      ttype,
      name,
      content,
      power,
      neighbors,
      material,
      updatedAt,
    );
  }

  void fromNetwork(Map<String, dynamic> item) {
    final travelId = item['travel_id'];
    final ttype = item['ttype'];
    final name = item['name'];
    final createdAt = DateTime.parse(item['created_at']);
    final t = MyTravelItem(travelId, ttype, name, createdAt);

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
        updateMain(mine);
      }
    }
  }
}
