import 'package:flutter/foundation.dart';

import '../common/auth_http.dart';

@immutable
class BroadcastItem {
  final int id;
  final int btype;
  final String content;
  final DateTime createdAt;
  const BroadcastItem(this.id, this.btype, this.content, this.createdAt);
}

class BroadcastModel extends ChangeNotifier {
  List<BroadcastItem> items = [];

  /// Update user data from network (fully info)
  void fromNetwork(Map<String, dynamic> json) {
    for (var item in json['data']) {
      final id = item['id'];
      final btype = item['btype'];
      final content = item['content'];
      final createdAt = DateTime.parse(item['created_at']);
      items.add(BroadcastItem(id, btype, content, createdAt));
    }

    notifyListeners();
  }

  /// Loading after login/register and timer
  Future<void> load() async {
    final response = await AuthHttpClient().get(
      AuthHttpClient.uri('users/broadcast'),
    );

    final data = AuthHttpClient.res(response);
    if (data != null) {
      fromNetwork(data);
    }
  }
}
