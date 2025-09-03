import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Fixed admin password
  static const String _adminPassword = 'Sharon6263';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // לוגו
              const AppLogo(
                size: 120,
                isIcon: false,
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'פאנל ניהול',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'סטודיו שרון לריקוד',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // טופס כניסה
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // הודעה
                    const Text(
                      'הזן את סיסמת האדמין',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // שדה סיסמה
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signIn(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'סיסמת אדמין',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.admin_panel_settings, color: Colors.white54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        print('Validating password: "$value"');
                        if (value == null || value.isEmpty) {
                          print('Validation failed: empty password');
                          return 'נא להזין את סיסמת האדמין';
                        }
                        print('Validation passed');
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // כפתור כניסה
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
                          print('Button clicked!');
                          _signIn();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'כניסה לפאנל הניהול',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              

            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    print('_signIn called');
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    print('Setting loading to true');
    setState(() => _isLoading = true);

    try {
      print('Password entered: "${_passwordController.text}"');
      print('Expected password: "$_adminPassword"');
      
      // Simple password check
      if (_passwordController.text == _adminPassword) {
        print('Password correct, navigating to dashboard');
        // Password correct, navigate to dashboard
        if (mounted) {
          context.go('/dashboard');
        } else {
          print('Widget not mounted');
        }
      } else {
        print('Password incorrect');
        _showError('סיסמה שגויה');
      }
    } catch (error) {
      print('Error in _signIn: $error');
      _showError('שגיאה לא צפויה: $error');
    } finally {
      if (mounted) {
        print('Setting loading to false');
        setState(() => _isLoading = false);
      }
    }
  }



  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}