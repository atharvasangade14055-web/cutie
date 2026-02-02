import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import 'chat_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final messenger = ScaffoldMessenger.of(context);

    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Please fill in both fields');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final success = await FirebaseService.instance
          .loginUser(_idController.text, _passwordController.text);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushReplacementNamed(ChatScreen.routeName);
      } else {
        setState(() => _errorMessage = 'Invalid credentials');
      }
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Network error. Please try again. ($error)')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateId(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your ID';
    }

    final normalized = trimmed.toLowerCase();
    if (normalized != 'atharva' && normalized != 'gf') {
      return 'Only atharva or gf IDs are allowed';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Enter your password';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Public Chat',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _idController,
                        decoration: const InputDecoration(
                          labelText: 'User ID',
                          hintText: 'atharva or gf',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validateId,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: _validatePassword,
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
