import 'package:flutter/foundation.dart';

import '../common/auth_http.dart';
import '../common/token.dart';

class UserModel extends ChangeNotifier {
  int id = 0;
  String name = '';
  String email = '';
  String eth = '';
  int attribute = 0;
  int level = 0;
  int levelNum = 0;
  int levelUp = 0;
  int coin = 0;
  int power = 0;
  int powerUp = 0;
  int powerHp = 0;
  int powerAttack = 0;
  int powerDefense = 0;
  int powerHit = 0;
  int powerDodge = 0;
  int mate = 0;
  DateTime nextMate = DateTime.now();
  String? avatar;

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    eth = json['eth'];
    attribute = json['attribute'];
    level = json['level'];
    levelNum = json['level_num'];
    levelUp = json['level_up'];
    coin = json['coin'];
    power = json['power'];
    powerUp = json['power_up'];
    powerHp = json['power_hp'];
    powerAttack = json['power_attack'];
    powerDefense = json['power_defense'];
    powerHit = json['power_hit'];
    powerDodge = json['power_dodge'];
    mate = json['mate'];
    nextMate = DateTime.parse(json['next_mate']);
    avatar = json['avatar'];

    notifyListeners();
  }

  /// Settle current level & power
  void settle() {
    //
  }

  /// Login with email & password
  Future<bool> login(String email, String password) async {
    var response = await AuthHttpClient().post(
      AuthHttpClient.uri('login'),
      body: AuthHttpClient.form({'email': email, 'password': password}),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      return false;
    } else {
      await TokenManager.saveToken(data['token']);
      fromNetwork(data['user']);
      return true;
    }
  }

  /// Register with info
  Future<bool> register(
    String email,
    String password,
    String name,
    int attribute,
  ) async {
    var response = await AuthHttpClient().post(
      AuthHttpClient.uri('register'),
      body: AuthHttpClient.form({
        'email': email,
        'password': password,
        'name': name,
        'attribute': attribute,
      }),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      return false;
    } else {
      await TokenManager.saveToken(data['token']);
      fromNetwork(data['user']);
      return true;
    }
  }
}
