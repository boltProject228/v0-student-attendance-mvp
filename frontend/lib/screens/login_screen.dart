import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _loginController.text,
        _passwordController.text,
        context,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Ошибка входа. Проверьте логин и пароль.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // 📏 Адаптивные размеры
    final double maxCardWidth = screenWidth < 500 ? screenWidth * 0.9 : 400;
    final double fieldFontSize = screenWidth < 400 ? 14 : 16;
    final double buttonFontSize = screenWidth < 400 ? 16 : 18;
    final double buttonHeight = screenWidth < 400 ? 48 : 52;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              shadowColor: Colors.black26,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 400 ? 20 : 32,
                  vertical: screenWidth < 400 ? 24 : 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 📌 Логотип
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(bottom: 24),
                        child: CircleAvatar(
                          radius: screenWidth < 400 ? 35 : 40,
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(
                            Icons.school,
                            size: screenWidth < 400 ? 35 : 40,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),

                      // 📌 Заголовок
                      Text(
                        'Система Посещаемости',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth < 400 ? 20 : 24,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 📥 Поле логина
                      TextFormField(
                        controller: _loginController,
                        style: TextStyle(fontSize: fieldFontSize),
                        decoration: InputDecoration(
                          labelText: 'Логин',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите логин' : null,
                      ),
                      const SizedBox(height: 16),

                      // 🔐 Поле пароля
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: TextStyle(fontSize: fieldFontSize),
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Введите пароль' : null,
                      ),
                      const SizedBox(height: 24),

                      // 🚪 Кнопка входа
                      FilledButton(
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        style: FilledButton.styleFrom(
                          minimumSize: Size(double.infinity, buttonHeight),
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Войти',
                                style: TextStyle(
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
