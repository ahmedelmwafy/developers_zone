import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'waiting_approval_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _register() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.isEmpty) return;
    
    final authController = Provider.of<AuthController>(context, listen: false);
    try {
      await authController.register(_emailController.text.trim(), _passwordController.text, _nameController.text.trim());
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
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.code, size: 80, color: Color(0xFF673AB7)),
            const SizedBox(height: 20),
            Text(locale.translate('register'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: locale.translate('name'), labelStyle: const TextStyle(color: Colors.grey))),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: locale.translate('email'), labelStyle: const TextStyle(color: Colors.grey))),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: locale.translate('password'), labelStyle: const TextStyle(color: Colors.grey)), obscureText: true),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: authController.isLoading ? null : _register,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF673AB7)),
              child: authController.isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(locale.translate('register'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
