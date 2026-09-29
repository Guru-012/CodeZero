import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  Future<void> signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword =
    confirmPasswordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage('Please fill all fields.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      showMessage(
        'Password must contain at least 6 characters.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Signup failed.';

      if (e.code == 'email-already-in-use') {
        message = 'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }

      showMessage(message);
    } catch (e) {
      showMessage('Something went wrong.');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),

      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),

          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF292929),
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              const Text(
                'Create account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Create your Memory AI account.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Email',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              _field(
                controller: emailController,
                hint: 'Enter your email',
              ),

              const SizedBox(height: 18),

              const Text(
                'Password',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              _field(
                controller: passwordController,
                hint: 'Create a password',
                obscure: true,
              ),

              const SizedBox(height: 18),

              const Text(
                'Confirm password',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              _field(
                controller: confirmPasswordController,
                hint: 'Confirm password',
                obscure: true,
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 48,

                child: ElevatedButton(
                  onPressed: isLoading ? null : signup,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(8),
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Create account',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        color: Colors.white,
      ),

      decoration: InputDecoration(
        hintText: hint,

        hintStyle: const TextStyle(
          color: Colors.grey,
        ),

        filled: true,

        fillColor: const Color(0xFF0D0D0D),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}