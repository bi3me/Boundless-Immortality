import 'package:flutter/foundation.dart';

import 'user.dart';
import 'material.dart';
import '../common/auth_http.dart';

class SeedMaterial {
  final int id;
  final String name;
  final int attribute;
  final int levelAdd;
  final int powersZip;
  final int coin;

  const SeedMaterial(
    this.id,
    this.name,
    this.attribute,
    this.levelAdd,
    this.powersZip,
    this.coin,
  );

  (int, int, int, int, int) powers() {
    final (d1, r1) = (powersZip ~/ 100000000, powersZip % 100000000);
    final (d2, r2) = (r1 ~/ 1000000, r1 % 1000000);
    final (d3, r3) = (r2 ~/ 10000, r2 % 10000);
    final (d4, d5) = (r3 ~/ 100, r3 % 100);

    return (d5, d4, d3, d2, d1);
  }
}

class SeedItem {
  final int id;
  final int materialId;
  int number;

  SeedItem(this.id, this.materialId, this.number);
}

class PlantItem {
  final int id;
  final int materialId;
  final DateTime endedAt;
  final DateTime createdAt;

  const PlantItem(this.id, this.materialId, this.endedAt, this.createdAt);
}

class PlantModel extends ChangeNotifier {
  Map<int, SeedMaterial> materials = {};
  Map<int, SeedItem> seeds = {};
  Map<int, PlantItem> plants = {};

  void clear() {
    materials.clear();
    seeds.clear();
    plants.clear();
  }

  bool availableForCreate() {
    return plants.length < 8;
  }

  Future<bool> buy(int id, UserModel user) async {
    // send to service
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/plant/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      seedFromNetwork(data);
      user.settle();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  void plant(int id) async {
    if ((seeds[id]?.number ?? 0) < 1 || !availableForCreate()) {
      return;
    }

    // send to service
    var response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/plant-seed/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      // none
    } else {
      seeds[id]?.number -= 1;
      plantFromNetwork(data);
      notifyListeners();
    }
  }

  void collect(int id, MaterialModel m) async {
    var response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/plant-collect/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      // none
    } else {
      plants.remove(id);
      m.fromNetwork(data);
      notifyListeners();
    }
  }

  void materialFromNetwork(Map<String, dynamic> item) {
    final id = item['id'];
    final name = item['name'];
    final attribute = item['attribute'];
    final levelAdd = item['level_add'];
    final powersZip = item['powers'];
    final coin = item['coin'];

    materials[id] = SeedMaterial(id, name, attribute, levelAdd, powersZip, coin);
  }

  void seedFromNetwork(Map<String, dynamic> item) {
    final id = item['id'];
    final materialId = item['material_id'];
    final number = item['num'];

    seeds[id] = SeedItem(id, materialId, number);
  }

  void plantFromNetwork(Map<String, dynamic> item) {
    final id = item['id'];
    final materialId = item['material_id'];

    final endedAt = DateTime.parse(item['ended_at']);
    final createdAt = DateTime.parse(item['created_at']);

    plants[id] = PlantItem(id, materialId, endedAt, createdAt);
  }

  /// Loading elixirs
  Future<void> load(bool force) async {
    if (force || materials.isEmpty) {
      final response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/plant'),
      );

      final data = AuthHttpClient.res(response);
      if (data != null) {
        clear();
        for (var item in data['materials']) {
          materialFromNetwork(item);
        }
        for (var item in data['seeds']) {
          seedFromNetwork(item);
        }
        for (var item in data['plants']) {
          plantFromNetwork(item);
        }

        notifyListeners();
      }
    }
  }
}
