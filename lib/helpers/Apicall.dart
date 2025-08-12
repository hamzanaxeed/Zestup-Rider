import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String BASEURL = "https://zestupbackend-59oze.sevalla.app/api";

class ApiCall {
  // POST
  static Future<Map<String, dynamic>> callApiPost(
    Map<String, dynamic> body,
    String endpoint,
    {bool withAuth = false, String type = 'invalid'}
  ) async {
    final baseUrl = "$BASEURL$endpoint";
    print("[POST] $baseUrl");
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (withAuth) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
          print("[POST] Authenticated with token");
        } else {
          print("[POST] No token found for auth");
        }
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      print("[POST] Status: ${response.statusCode}");
      final jsonResponse = jsonDecode(response.body);

      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': jsonResponse,
      };
    } catch (e) {
      print("[POST] Error: $e");
      return {
        'statusCode': 500,
        'success': false,
        'error': true,
        'message': 'Network error or invalid response',
        'exception': e.toString(),
      };
    }
  }

  // PUT
  static Future<Map<String, dynamic>> callApiPut(
    Map<String, dynamic> body,
    String endpoint,
    {bool withAuth = false}
  ) async {
    final baseUrl = "$BASEURL$endpoint";
    print("[PUT] $baseUrl");
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (withAuth) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
          print("[PUT] Authenticated with token");
        } else {
          print("[PUT] No token found for auth");
        }
      }

      final response = await http.put(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      print("[PUT] Status: ${response.statusCode}");
      final jsonResponse = jsonDecode(response.body);

      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        'data': jsonResponse,
      };
    } catch (e) {
      print("[PUT] Error: $e");
      return {
        'statusCode': 500,
        'success': false,
        'error': true,
        'message': 'Network error or invalid response',
        'exception': e.toString(),
      };
    }
  }

  // GET
  static Future<Map<String, dynamic>> callApiGet(
    String endpoint,
    {bool withAuth = false}
  ) async {
    final baseUrl = "$BASEURL$endpoint";
    print("[GET] $baseUrl");
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (withAuth) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
          print("[GET] Authenticated with token");
        } else {
          print("[GET] No token found for auth");
        }
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      print("[GET] Status: ${response.statusCode}");
      final jsonResponse = jsonDecode(response.body);

      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        'data': jsonResponse,
      };
    } catch (e) {
      print("[GET] Error: $e");
      return {
        'statusCode': 500,
        'success': false,
        'error': true,
        'message': 'Network error or invalid response',
        'exception': e.toString(),
      };
    }
  }

  // DELETE
  static Future<Map<String, dynamic>> callApiDelete(
    String endpoint,
    {bool withAuth = false, Map<String, dynamic>? body}
  ) async {
    final baseUrl = "$BASEURL$endpoint";
    print("[DELETE] $baseUrl");
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (withAuth) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
          print("[DELETE] Authenticated with token");
        } else {
          print("[DELETE] No token found for auth");
        }
      }

      http.Response response;
      if (body != null) {
        response = await http.delete(
          Uri.parse(baseUrl),
          headers: headers,
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));
      } else {
        response = await http.delete(
          Uri.parse(baseUrl),
          headers: headers,
        ).timeout(const Duration(seconds: 30));
      }

      print("[DELETE] Status: ${response.statusCode}");
      final jsonResponse = jsonDecode(response.body);

      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200 || response.statusCode == 204,
        'data': jsonResponse,
      };
    } catch (e) {
      print("[DELETE] Error: $e");
      return {
        'statusCode': 500,
        'success': false,
        'error': true,
        'message': 'Network error or invalid response',
        'exception': e.toString(),
      };
    }
  }
}

