import 'package:flutter/material.dart';
import '../../helpers/Colors.dart';
import '../../helpers/snackbar.dart';
import '../../controllers/auth_Controller.dart';
import 'forget_Password_Newpassword.dart';

class ForgetPasswordOTPScreen extends StatefulWidget {
  final String email;
  const ForgetPasswordOTPScreen({super.key, required this.email});

  @override
  State<ForgetPasswordOTPScreen> createState() => _ForgetPasswordOTPScreenState();
}

class _ForgetPasswordOTPScreenState extends State<ForgetPasswordOTPScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int idx, String value) {
    if (value.length == 1 && idx < 5) {
      _focusNodes[idx + 1].requestFocus();
    }
    if (value.isEmpty && idx > 0) {
      _focusNodes[idx - 1].requestFocus();
    }
  }

  String getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> handleVerifyOTP() async {
    final otp = getOtp();
    if (otp.length != 6) {
      showErrorSnackbar(context, 'Enter 6 digit OTP');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final success = await AuthController.verifyOTP(
      email: widget.email,
      code: otp,
      context: context,
    );
    setState(() {
      _isLoading = false;
    });
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ForgetPasswordNewpasswordScreen(email: widget.email)),
      );
    }
    // Error snackbar is already shown in controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Stack(
              children: [
                // Oval and images (same as other screens)
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
                          // ...same decorative dots as other screens...
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.62),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          Text(
                            'OTP Verification',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'Enter the 6-digit OTP sent to ${widget.email}',
                            style: TextStyle(color: Colors.black54),
                          ),
                          SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (idx) {
                              return Container(
                                width: 45, // reduced from 52
                                height: 48, // reduced from 60
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                child: TextField(
                                  controller: _otpControllers[idx],
                                  focusNode: _focusNodes[idx],
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // reduced font size
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Appcolors.primaryColor, width: 2),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    _onOtpChanged(idx, value);
                                    if (value.length > 1) {
                                      _otpControllers[idx].text = value.substring(0, 1);
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: handleVerifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Appcolors.primaryColor.withOpacity(1),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Verify OTP', style: TextStyle(fontSize: 20, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
