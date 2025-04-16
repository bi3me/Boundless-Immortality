import 'package:flutter/foundation.dart';

import 'user.dart';
import '../common/auth_http.dart';

class DuelItem {
  final int id;
  final int level;
  final int coin;
  final int player;
  final int? challenger;
  final bool? win;

  DuelItem(
    this.id,
    this.level,
    this.coin,
    this.player,
    this.challenger,
    this.win,
  );

  bool isWin(int me) {
    if (win != null) {
      final rwin = win ?? false;
      return (player == me && rwin) || (challenger == me && !rwin);
    } else {
      return false;
    }
  }
}

class ActivedDuelItem {
  final int id;
  final int level;
  final int coin;
  final int player;
  final int? challenger;
  final String name;
  final int power;
  final bool isMe;

  ActivedDuelItem(
    this.id,
    this.level,
    this.coin,
    this.player,
    this.challenger,
    this.name,
    this.power,
    this.isMe,
  );
}

class DuelModel extends ChangeNotifier {
  Map<int, ActivedDuelItem> actives = {};
  Map<int, ActivedDuelItem> mine = {};
  Map<int, DuelItem> history = {};

  void clear() {
    actives.clear();
    mine.clear();
    history.clear();
  }

  Future<bool> create(int dtype, int coin, int? private) async {
    var response = await AuthHttpClient().post(
      AuthHttpClient.uri('users/duels'),
      body: AuthHttpClient.form({
        'dtype': dtype,
        'coin': coin,
        'private': private,
      }),
    );

    final data = AuthHttpClient.res(response);
    if (data == null) {
      return false;
    } else {
      activedFromNetwork(data, true);
      notifyListeners();
      return true;
    }
  }

  Future<void> accept(int id, UserModel user) async {
    // users/duels-accept
    var response = await AuthHttpClient().post(
      AuthHttpClient.uri("users/duels-accept/$id"),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      print(data);
      if (data['win']) {
        actives.remove(id);
      }

      fromNetwork(data['duel']);

      // update user data['user']
      user.update(data['user']);

      notifyListeners();
    }
  }

  void fromNetwork(Map<String, dynamic> item) {
    final id = item['id'];
    final level = item['level'];
    final coin = item['coin'];
    final player = item['player'];
    final challenger = item['challenger'];
    final win = item['win'];

    history[id] = DuelItem(id, level, coin, player, challenger, win);
  }

  void activedFromNetwork(Map<String, dynamic> item, bool me) {
    final id = item['id'];
    final level = item['level'];
    final coin = item['coin'];
    final player = item['player'];
    final challenger = item['challenger'];
    final name = item['name'];
    final power = item['power'];
    final ad = ActivedDuelItem(
      id,
      level,
      coin,
      player,
      challenger,
      name,
      power,
      me,
    );

    if (me) {
      mine[id] = ad;
    } else {
      actives[id] = ad;
    }
  }

  /// Loading duels
  Future<void> load() async {
    // load actived duels
    if (actives.isEmpty) {
      final response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/duels'),
      );

      final data = AuthHttpClient.res(response);
      if (data != null) {
        for (var item in data['data']) {
          activedFromNetwork(item, false);
        }

        notifyListeners();
      }
    }

    // load history duels
    if (mine.isEmpty) {
      final response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/duels-private'),
      );

      final data = AuthHttpClient.res(response);
      if (data != null) {
        for (var item in data['data']) {
          activedFromNetwork(item, true);
        }

        notifyListeners();
      }
    }

    // load history duels
    if (history.isEmpty) {
      final response = await AuthHttpClient().get(
        AuthHttpClient.uri('users/duels-me'),
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
