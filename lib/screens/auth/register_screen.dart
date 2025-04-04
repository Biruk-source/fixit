import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import '../../services/auth_service.dart';
import 'skills.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // Theme Colors
  static const Color _primaryColor = Color(0xFF00DDEB);
  static const Color _background = Color(0xFF121212);
  static const Color _surface = Color(0xFF1E1E1E);
  static const Color _onSurface = Color(0xFFE0E0E0);
  static const Color _errorColor = Color(0xFFCF6679);

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _phoneController = TextEditingController();
  final _skillsSearchController = TextEditingController();
  final AuthService _authService = AuthService();

  // State
  final List<String> _selectedSkills = [];
  List<String> _filteredSkills = [];
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _userType = 'client';
  String? _profession;
  bool _isHoveringRegister = false;

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _filteredSkills = commonSkills; // Initialize filtered skills

    // Animation setup
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _phoneController.dispose();
    _skillsSearchController.dispose();
    super.dispose();
  }

  void _removeSkill(String skill) {
    setState(() {
      _selectedSkills.remove(skill);
    });
  }

  void _filterSkills(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSkills = commonSkills;
      } else {
        _filteredSkills = commonSkills
            .where((skill) => skill.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmController.text) {
      _showSnackBar("Passwords don't match!", _errorColor);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.createUserWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      await _authService.createUserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        userType: _userType,
        profession: _profession,
      );

      if (!mounted) return;
      _showSnackBar("Registration successful!", Colors.green);
      if (_userType == 'client') {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } else if (_userType == 'worker') {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/professional-setup', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email already in use';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format';
      }
      _showSnackBar(message, _errorColor);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', _errorColor);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildHeader() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color.fromARGB(255, 38, 48, 49),
                  Color.fromARGB(0, 73, 18, 18)
                ],
                stops: [0.1, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color.fromARGB(255, 204, 235, 0).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_add_alt_1,
              size: 60,
              color: Color.fromARGB(255, 229, 202, 202),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _onSurface,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join our community of professionals',
            style: TextStyle(
              fontSize: 16,
              color: _onSurface.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 8),
          child: Text(
            'I am a:',
            style: TextStyle(
              color: _onSurface.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildUserTypeCard(
                title: 'hiring',
                icon: Icons.home,
                isSelected: _userType == 'client',
                onTap: () => setState(() => _userType = 'client'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUserTypeCard(
                title: 'Professional',
                icon: Icons.handyman,
                isSelected: _userType == 'worker',
                onTap: () => setState(() => _userType = 'worker'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserTypeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _surface : _surface.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: _primaryColor.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? _primaryColor : _onSurface.withOpacity(0.7),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? _primaryColor : _onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionAndSkillsField() {
    if (_userType != 'worker') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        TextFormField(
          onChanged: (value) => _profession = value,
          style: const TextStyle(color: _onSurface),
          cursorColor: _primaryColor,
          decoration: InputDecoration(
            labelText: 'Your Profession',
            labelStyle: const TextStyle(color: _primaryColor),
            hintText: 'Electrician, Plumber, etc.',
            hintStyle: TextStyle(color: _onSurface.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.work, color: _primaryColor),
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: _primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: _onSurface),
          cursorColor: _primaryColor,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: _primaryColor),
            prefixIcon: Icon(icon, color: _primaryColor),
            suffixIcon: onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: _primaryColor,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: _primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: _errorColor, width: 1),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringRegister = true),
      onExit: (_) => setState(() => _isHoveringRegister = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 55,
        margin: const EdgeInsets.only(top: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [_primaryColor, Color(0xFF007D8B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(_isHoveringRegister ? 0.5 : 0.3),
              blurRadius: _isHoveringRegister ? 25 : 15,
              spreadRadius: _isHoveringRegister ? 3 : 1,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text(
                  'CREATE ACCOUNT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: TextStyle(
              color: _onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
            children: [
              TextSpan(
                text: 'Sign In',
                style: const TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: _primaryColor,
                      blurRadius: 10,
                    ),
                  ],
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildUserTypeSelector(),
                    _buildProfessionAndSkillsField(),
                    _buildInputField(
                      label: 'Full Name',
                      icon: Icons.person,
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      label: 'Email',
                      icon: Icons.email,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      label: 'Phone Number',
                      icon: Icons.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    _buildInputField(
                      label: 'Password',
                      icon: Icons.lock,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      onToggleVisibility: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    _buildInputField(
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onToggleVisibility: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    _buildRegisterButton(),
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
