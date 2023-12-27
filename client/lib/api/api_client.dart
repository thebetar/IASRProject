import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  Future<String> calculate(String mathExpression) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/calculate'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'mathExpression': mathExpression,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['result'].toString();
    } else {
      throw Exception('Failed to calculate');
    }
  }
}
