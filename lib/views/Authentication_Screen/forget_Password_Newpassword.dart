import 'package:flutter/material.dart';

class ForgetPasswordNewpasswordScreen extends StatelessWidget {
  final String email;
  const ForgetPasswordNewpasswordScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set New Password')),
      body: Center(
        child: Text('Set new password for $email'),
      ),
    );
  }
}

