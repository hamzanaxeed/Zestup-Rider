import 'package:flutter/material.dart';
import '../../helpers/Colors.dart';
import '../../helpers/snackbar.dart';
import '../../controllers/auth_Controller.dart';
import 'forget_Password_OTP_Screen.dart';

class ForgetPasswordEmailScreen extends StatefulWidget {
  ForgetPasswordEmailScreen({super.key});

  @override
  State<ForgetPasswordEmailScreen> createState() => _ForgetPasswordEmailScreenState();
}

class _ForgetPasswordEmailScreenState extends State<ForgetPasswordEmailScreen> {
  final TextEditingController _emailController = TextEditingController();

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  Future<void> handleSendResetEmail() async {
    final email = _emailController.text.trim();
    if (!isValidEmail(email)) {
      showErrorSnackbar(context, 'Please enter a valid email address');
      return;
    }
    final success = await AuthController.sendPasswordResetOTP(
      email: email,
      context: context,
    );
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ForgetPasswordOTPScreen(email: email)),
      );
    }
    // Error snackbar is already shown in controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Oval and images (copied from login screen)
            Positioned(
              top: -400,
              right: -200,
              child: ClipOval(
                child: Container(
                  width: 900,
                  height: 900,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 40,
                        spreadRadius: 10,
                        offset: Offset(0, 30),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Appcolors.primaryColor.withOpacity(1),
                              Appcolors.primaryColor.withOpacity(0.8),
                              Colors.white,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 240, bottom: 40),
                          child: Image.asset(
                            'assets/images/mainscreen_image.png',
                            width: 350,
                            height: 350,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 530,
                        left: 400,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 500,
                        left: 600,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 650,
                        left: 670,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 700,
                        left: 300,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Form fields
            Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.62,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'e.g. user@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Appcolors.primaryColor, width: 2),
                          ),
                          labelStyle: TextStyle(color: Colors.black54),
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: handleSendResetEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolors.primaryColor.withOpacity(1),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Send Reset Email', style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
