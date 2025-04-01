import 'dart:convert';
import 'package:http/http.dart' as http;

import './token.dart';
import './constants.dart';

class AuthHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  static Uri uri(String path) {
    return Uri.parse("$domain/$path");
  }

  static String form(Map<String, dynamic> form) {
    return jsonEncode(form);
  }

  static Map<String, dynamic>? res(http.Response response) {
    if (response.statusCode == 200) {
      String decodedBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(decodedBody) as Map<String, dynamic>;
      if (data.containsKey('error')) {
        print(data);
        // TODO toast
        return null;
      } else {
        return data;
      }
    } else {
      print(response.statusCode);
      print(response.body);
      // TODO toast Failed to load data
      return null;
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['Content-Type'] = 'application/json; charset=UTF-8';

    final token = await TokenManager.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
