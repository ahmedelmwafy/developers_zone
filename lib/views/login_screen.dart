import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../providers/app_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'waiting_approval_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    try {
      await authController.login(_emailController.text.trim(), _passwordController.text);
      if (mounted && authController.currentUser != null) {
        if (authController.currentUser!.isApproved) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WaitingApprovalPage()));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _signInWithGoogle() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    try {
      await authController.signInWithGoogle();
      if (mounted && authController.currentUser != null) {
        if (authController.currentUser!.isApproved) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WaitingApprovalPage()));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', height: 120),
              const SizedBox(height: 30),
              Text(locale.translate('login'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              TextField(controller: _emailController, decoration: InputDecoration(labelText: locale.translate('email'), labelStyle: const TextStyle(color: Colors.grey))),
              TextField(controller: _passwordController, decoration: InputDecoration(labelText: locale.translate('password'), labelStyle: const TextStyle(color: Colors.grey)), obscureText: true),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: authController.isLoading ? null : _login,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF673AB7)),
                child: authController.isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(locale.translate('login'), style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.grey, thickness: 0.5),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: authController.isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 40),
                label: Text(locale.translate('google_sign_in')),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: Text(locale.translate('register'), style: const TextStyle(color: Color(0xFF673AB7))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
