import 'package:flutter/material.dart';
import '../helpers/Colors.dart';
import '../controllers/auth_Controller.dart';
import '../helpers/snackbar.dart';
import '../views/home_Screen.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // Add this line

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Large oval, strong gradient, image centered on visible part
            Positioned(
              top: -400, // was -950
              right: -200, // was -450
              child: ClipOval(
                child: Container(
                  width: 900, // was 1500
                  height: 900, // was 1500
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
                      // Linear gradient background (more prominent, dark to white)
        
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Appcolors.primaryColor.withOpacity(1), // dark start
                              Appcolors.primaryColor.withOpacity(0.8),
                              Colors.white, // bright end
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
        
                      // Center the image on the visible oval part
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          // Adjust padding to center image on visible oval part
                          padding: const EdgeInsets.only(right: 240, bottom: 40), // was right: 500, bottom: 100
                          child: Image.asset(
                            'assets/images/mainscreen_image.png',
                            width: 350, // was 310
                            height: 350, // was 290
                           // fit: BoxFit.cover,
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
        
            // Move the fields to the bottom of the oval
        
            Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.62,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text('Enter your details',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24,),
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
                      const SizedBox(height: 15),
        
                      TextField(
                        controller: _passwordController,
                        keyboardType: TextInputType.text,
                        obscureText: _obscurePassword, // Use state variable
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.lock_outline),
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
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
        
                      SizedBox(height: 24,),
        
                      ElevatedButton(
                        onPressed: () async {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text;

                          // Email validation
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (email.isEmpty || password.isEmpty) {
                            showErrorSnackbar(context, 'Please enter both email and password');
                            return;
                          }
                          if (!emailRegex.hasMatch(email)) {
                            showErrorSnackbar(context, 'Please enter a valid email address');
                            return;
                          }
                          if (password.length < 8) {
                            showErrorSnackbar(context, 'Password must be at least 8 characters');
                            return;
                          }

                          EasyLoading.show(status: 'Logging in...');
                          final loginSuccess = await AuthController.login(
                            email: email,
                            password: password,
                            context: context,
                          );
                          EasyLoading.dismiss();

                          if (loginSuccess == true) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => HomeScreen()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolors.primaryColor.withOpacity(1),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Sign in',style: TextStyle(fontSize: 20,color: Colors.white)),
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
