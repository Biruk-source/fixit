import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Core setup
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State for UI magic
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation; // Fixed: Properly marked as late

  @override
  void initState() {
    super.initState();
    // Setup animation controller
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Login logic
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (!mounted) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } on FirebaseAuthException catch (e) {
        _showSnackBar(_getErrorMessage(e.code), Colors.redAccent);
      } catch (e) {
        _showSnackBar('Login failed: $e', Colors.redAccent);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Error message handler
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found, fam';
      case 'wrong-password':
        return 'Password’s off, yo';
      case 'invalid-email':
        return 'Email’s whack';
      case 'user-disabled':
        return 'Account’s locked, bro';
      default:
        return 'Somethin’ broke, try again';
    }
  }

  // Styled snackbar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E), // Deep dark blue-black
              Color(0xFF16213E), // Slightly lighter dark shade
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      _buildHeader(),
                      const SizedBox(height: 50),
                      _buildEmailField(),
                      const SizedBox(height: 20),
                      _buildPasswordField(),
                      const SizedBox(height: 15),
                      _buildOptionsRow(),
                      _buildRegisterLink(),
                      const SizedBox(height: 30),
                      _buildLoginButton(),
                      const SizedBox(height: 30),
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

  // Header with neon logo and glow
  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_animController.value * 0.1), // Subtle pulse
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color.fromARGB(255, 37, 240, 254),
                      Color.fromARGB(0, 255, 141, 141)
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00DDEB).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.handyman,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'FixIt',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
            shadows: [
              Shadow(color: Color(0xFF00DDEB), blurRadius: 15),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Find trusted professionals',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF00DDEB),
            fontStyle: FontStyle.italic,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 5),
            ],
          ),
        ),
      ],
    );
  }

  // Email field with dark mode glass effect
  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        cursorColor: const Color(0xFF00DDEB),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: const TextStyle(color: Color(0xFF00DDEB)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          prefixIcon: const Icon(Icons.email, color: Color(0xFF00DDEB)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF00DDEB), width: 2),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Email’s a must, yo';
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Fix that email, fam';
          }
          return null;
        },
      ),
    );
  }

  // Password field with neon accents
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        cursorColor: const Color(0xFF00DDEB),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: const TextStyle(color: Color(0xFF00DDEB)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          prefixIcon: const Icon(Icons.lock, color: Color(0xFF00DDEB)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF00DDEB),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF00DDEB), width: 2),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Gimme that password' : null,
      ),
    );
  }

  // Options row with dark mode styling
  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) => setState(() => _rememberMe = value!),
              activeColor: const Color(0xFF00DDEB),
              checkColor: Colors.black,
            ),
            const Text('Remember Me', style: TextStyle(color: Colors.white70)),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ForgotPasswordScreen()),
            );
          },
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
                color: Color(0xFF00DDEB), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Neon login button with hover effect
  Widget _buildLoginButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00DDEB).withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00DDEB),
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 25,
                width: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Text(
                'Log In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'New here? ',
          style: const TextStyle(
            fontSize: 16,
            shadows: [
              Shadow(
                color: Color.fromARGB(255, 63, 189, 5),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          children: [
            WidgetSpan(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 2, 164, 175),
                    Color.fromARGB(255, 2, 123, 130)
                  ],
                ).createShader(bounds),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          Colors.white, // This ensures the gradient is visible
                      shadows: [
                        Shadow(color: Color(0xFF00DDEB), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
