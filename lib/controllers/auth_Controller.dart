import '../helpers/Apicall.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/Colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/snackbar.dart';

class AuthController {
  static Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    final body = {
      "email": email,
      "password": password,
    };
    final response = await ApiCall.callApiPost(
      body,
      "/auth/rider/login",
    );
    print('[LOGIN] Response: $response');
    print('[LOGIN] Full Response: $response');

    final data = response['data'];

    if (data != null) {
      print('[LOGIN] Error: ${data['error']}');
      print('[LOGIN] Message: ${response['message']}');
      print('[LOGIN] Success: ${response['success']}');

      final userData = data['data']?['user'];
      if (userData != null) {
        print('[LOGIN] User ID: ${userData['id']}');
        print('[LOGIN] Email: ${userData['email']}');
        print('[LOGIN] First Name: ${userData['firstName']}');
        print('[LOGIN] Last Name: ${userData['lastName']}');
        print('[LOGIN] Phone: ${userData['phone']}');
      }

      print('[LOGIN] Access Token: ${data['data']?['accessToken']}');
      print('[LOGIN] Refresh Token: ${data['data']?['refreshToken']}');
    }

    if (response['statusCode'] == 200) {
      final data = response['data'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', data['accessToken'] ?? '');
      await prefs.setString('refreshToken', data['refreshToken'] ?? '');

      // Store user data
      final userData = data['user'];
      if (userData != null) {
        await prefs.setString('userId', userData['id'] ?? '');
        await prefs.setString('Email', userData['email'] ?? '');
        await prefs.setString('FirstName', userData['firstName'] ?? '');
        await prefs.setString('LastName', userData['lastName'] ?? '');
        await prefs.setString('Phone', userData['phone'] ?? '');
        await prefs.setString('userId', userData['roleId'] ?? '');
        // Store permissions as JSON string


        if (userData['permissions'] != null) {
          await prefs.setString('userPermissions', userData['permissions'].toString());
        }
      }

      // Success: return true after showing snackbar
      showSuccessSnackbar(context, 'Login successful');
      return true;
    } else {
      String? errorMsg;
      if (response['data'] != null && response['data']['error'] != null) {
        errorMsg = response['data']['error'].toString();
      }else if (response['message'] != null) {
        errorMsg = response['message'].toString();
      } else {
        errorMsg = 'Login failed. Please try again.';
      }
      print('[LOGIN] Error Message: $errorMsg');
      showErrorSnackbar(context, errorMsg);
      return false;
    }//
  }
 /////////////////////////////////////////////////////////////////////////////////////////////////////////
  static Future<bool> sendPasswordResetOTP({
    required String email,
    required BuildContext context,
  }) async {
    final body = {
      "email": email,
    };
    final response = await ApiCall.callApiPost(
      body,
      "/auth/rider/password/forgot",
    );
    print('[FORGET PASSWORD] Response: $response');

    if (response['statusCode'] == 200) {
      showSuccessSnackbar(context, 'OTP sent successfully');
      return true;
    } else {
      String msg = response['body']?['error']?.toString() ?? 'Failed to send OTP';
      showErrorSnackbar(context, msg);
      return false;
    }
  }
  /////////////////////////////////////////////////////////
  static Future<bool> verifyOTP({
    required String email,
    required String code,
    required BuildContext context,
  }) async {
    final body = {
      "email": email,
      "code": code,
    };
    final response = await ApiCall.callApiPost(
      body,
      "/auth/password/verify-otp",
      context: context,
    );
    print('[VERIFY OTP] Response: $response');

    if (response['statusCode'] == 200) {
      final resetToken = response['body']?['data']?['resetToken'];
      if (resetToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('resetToken', resetToken);
      }
      showSuccessSnackbar(context, 'OTP Verified');
      return true;
    } else {
      String msg = response['body']?['error']?.toString() ?? 'OTP verification failed';
      showErrorSnackbar(context, msg);
      return false;
    }
  }

}
