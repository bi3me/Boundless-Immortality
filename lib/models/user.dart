import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../common/auth_http.dart';
import '../common/token.dart';
import '../main.dart';

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
  bool newRegister = false;

  Widget detailPage = SizedBox.shrink();

  void clear() {
    detailPage = SizedBox.shrink();
  }

  void closeNewRegister() {
    newRegister = false;
  }

  void router(BuildContext context, String path) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 760) {
      for (var route in MyApp.routers) {
        if (route.path == path) {
          final widget = route.builder(context, GoRouterState.of(context));
          detailPage = widget ?? SizedBox.shrink();
          notifyListeners();
        }
      }
    } else {
      GoRouter.of(context).push(path);
    }
  }

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> json) {
    if (!json.containsKey('id')) {
      return;
    }

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
  }

  void update(Map<String, dynamic> json) {
    fromNetwork(json);
    notifyListeners();
  }

  /// Settle current level & power
  void settle() async {
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri('users/settle'),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      level = data['level'];
      levelNum = data['level_num'];
      levelUp = data['level_up'];
      coin = data['coin'];
      power = data['power'];
      powerUp = data['power_up'];
      powerHp = data['power_hp'];
      powerAttack = data['power_attack'];
      powerDefense = data['power_defense'];
      powerHit = data['power_hit'];
      powerDodge = data['power_dodge'];
      notifyListeners();
    }
  }

  /// Login with email & password
  Future<bool> login(String email, String password) async {
    final response = await AuthHttpClient().post(
      AuthHttpClient.uri('login'),
      body: AuthHttpClient.form({'email': email, 'password': password}),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      return false;
    } else {
      await TokenManager.saveToken(data['token']);
      update(data['user']);
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
    final response = await AuthHttpClient().post(
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
      update(data['user']);
      newRegister = true;
      return true;
    }
  }
}
