import 'package:flutter/material.dart';
import '../Models/order_Model.dart';
import '../helpers/Apicall.dart';
import 'dart:convert';

class OrderController extends ChangeNotifier {
  List<Order> _orders = [];
  bool _loading = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOrders({BuildContext? context}) async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    final response = await ApiCall.callApiGet('/riders/orders', withAuth: true, context: context);
    final statusCode = response['statusCode'];
    if (statusCode == 200 && response['body'] != null && response['body']['success'] == true) {
      print('[FETCH ORDERS] Response:');
      //final decoded = json.decode(response['body']);        // parse the JSON
      const encoder = JsonEncoder.withIndent('  ');         // 2-space indentation
      print(encoder.convert(response['body'])); // pretty-print JSON
      final OrdersResponse ordersResponse = OrdersResponse.fromJson(response['body']);
      _orders = ordersResponse.orders;
      _errorMessage = null;
    } else {
      _orders = [];
      if (statusCode == 401) {
        _errorMessage = 'Authentication required. Please login again.';
      } else if (statusCode == 403) {
        _errorMessage = 'Forbidden: You are not a rider or lack permissions.';
      } else if (statusCode == 500) {
        _errorMessage = 'Internal server error. Please try again later.';
      } else {
        _errorMessage = 'Unknown error, contact customer support.';
      }
    }
    _loading = false;
    notifyListeners();
  }
}
