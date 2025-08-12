import 'package:flutter/material.dart';
import '../helpers/Colors.dart';
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Large oval, strong gradient, image centered on visible part
          Positioned(
            top: -950,
            right: -450,
            child: ClipOval(
              child: Container(
                width: 1500,
                height: 1500,
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
                    // Linear gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Appcolors.primaryColor.withOpacity(1),
                            Appcolors.primaryColor.withOpacity(1),
                            Appcolors.primaryColor.withOpacity(1),
                          ],
                          stops: const [0.0, 0.9, 1.0],
                        ),
                      ),
                    ),
                    // Radial gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-1.0, 1.0), // bottom-left corner
                          radius: 1.2,
                          colors: [
                            Colors.white.withOpacity(1),
                            Colors.white.withOpacity(0), // fade out to transparent
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                    // Decorative white circles above the image
                    Positioned(
                      top: 320,
                      right: 650,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 350,
                      right: 600,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 390,
                      right: 670,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 370,
                      right: 720,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Center the image on the visible oval part
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        // Adjust padding to center image on visible oval part
                        padding: const EdgeInsets.only(right: 500, bottom: 100),
                        child: Image.asset(
                          'assets/images/mainscreen_image.png',
                          width: 310,
                          height: 290,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Move the fields to the bottom of the oval
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 580), // Adjust this to match the oval's bottom
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
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Enter Email',
                          hintText: 'e.g. user@example.com',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'Enter password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 24,),
                      ElevatedButton(
                        onPressed: () {
                          // Handle login/signup
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
          ),
        ],
      ),
    );
  }
}
