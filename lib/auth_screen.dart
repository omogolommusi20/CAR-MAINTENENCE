import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';

class CarMaintenanceApp extends StatelessWidget {
  const CarMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8C547),
          secondary: Color(0xFFFF6B2B),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedEngineType;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _carMakeController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carYearController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _engineTypes = ['Petrol', 'Diesel', 'Hybrid', 'Electric'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _carMakeController.dispose();
    _carModelController.dispose();
    _carYearController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animController.reset();
    setState(() => _isLogin = !_isLogin);
    _animController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isLogin && _selectedEngineType == null) {
      _showSnack('Please select an engine type', const Color(0xFFFF6B2B));
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _login();
      } else {
        await _register();
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}', const Color(0xFFFF6B2B));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final query = await FirebaseFirestore.instance
        .collection('LOGIN')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    if (query.docs.isEmpty) {
      _showSnack('Invalid username or password', const Color(0xFFFF6B2B));
      return;
    }

    final data = query.docs.first.data();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          userName: data['username'] ?? username,
          carMake: data['carMake'] ?? '',
          carModel: data['carModel'] ?? '',
          carYear: data['carYear'] ?? '',
          engineType: data['engineType'] ?? 'Petrol',
        ),
      ),
    );
  }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final existing = await FirebaseFirestore.instance
        .collection('LOGIN')
        .where('username', isEqualTo: username)
        .get();

    if (existing.docs.isNotEmpty) {
      _showSnack('Username already taken', const Color(0xFFFF6B2B));
      return;
    }

    await FirebaseFirestore.instance.collection('LOGIN').add({
      'username': username,
      'password': password,
      'name': _nameController.text.trim(),
      'carMake': _carMakeController.text.trim(),
      'carModel': _carModelController.text.trim(),
      'carYear': _carYearController.text.trim(),
      'engineType': _selectedEngineType,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _showSnack('Account created! Please sign in.', const Color(0xFF4CAF50));
    _toggleMode();
  }

  // ─── GOOGLE SIGN-IN ───────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        _showSnack('Google sign-in failed', const Color(0xFFFF6B2B));
        setState(() => _isLoading = false);
        return;
      }

      // Check if user already has a profile in Firestore
      final existing = await FirebaseFirestore.instance
          .collection('LOGIN')
          .where('email', isEqualTo: user.email)
          .get();

      if (existing.docs.isNotEmpty) {
        // Existing user — go to HomeScreen
        final data = existing.docs.first.data();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: data['username'] ?? user.displayName ?? 'User',
              carMake: data['carMake'] ?? '',
              carModel: data['carModel'] ?? '',
              carYear: data['carYear'] ?? '',
              engineType: data['engineType'] ?? 'Petrol',
            ),
          ),
        );
      } else {
        // New Google user — save basic profile and prompt car details
        await FirebaseFirestore.instance.collection('LOGIN').add({
          'username': user.displayName ?? user.email ?? 'GoogleUser',
          'email': user.email,
          'name': user.displayName ?? '',
          'carMake': '',
          'carModel': '',
          'carYear': '',
          'engineType': 'Petrol',
          'createdAt': FieldValue.serverTimestamp(),
          'loginMethod': 'google',
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              userName: user.displayName ?? 'User',
              carMake: '',
              carModel: '',
              carYear: '',
              engineType: 'Petrol',
            ),
          ),
        );
      }
    } catch (e) {
      _showSnack(
          'Google sign-in error: ${e.toString()}', const Color(0xFFFF6B2B));
    }
    setState(() => _isLoading = false);
  }
  // ─────────────────────────────────────────────────────────────────────────

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 36),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildToggle(),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildForm(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                  // Divider with OR
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: Colors.white.withValues(alpha: 0.15))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                          child: Divider(
                              color: Colors.white.withValues(alpha: 0.15))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Google Sign-In Button
                  _buildGoogleButton(),
                  const SizedBox(height: 16),
                  _buildSwitchPrompt(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF16161F),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google "G" logo drawn with colored text
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                      text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                  TextSpan(
                      text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
                  TextSpan(
                      text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
                  TextSpan(
                      text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
                  TextSpan(
                      text: 'l', style: TextStyle(color: Color(0xFF34A853))),
                  TextSpan(
                      text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(color: const Color(0xFF0A0A0F)),
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFE8C547).withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFF6B2B).withValues(alpha: 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        CustomPaint(
          size: Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height,
          ),
          painter: _GridPainter(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE8C547),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car_rounded,
                  color: Color(0xFF0A0A0F), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('AutoCare',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3)),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'Welcome back' : 'Get started',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5),
        ),
        const SizedBox(height: 6),
        Text(
          _isLogin
              ? 'Sign in to continue to your garage'
              : 'Create your account to manage your car',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _toggleTab('Sign In', _isLogin),
          _toggleTab('Register', !_isLogin),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if ((label == 'Sign In' && !_isLogin) ||
              (label == 'Register' && _isLogin)) {
            _toggleMode();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE8C547) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  color: active ? const Color(0xFF0A0A0F) : Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            _buildField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
          ],
          _buildField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.alternate_email_rounded,
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            toggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) => v!.length < 4 ? 'Minimum 4 characters' : null,
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.directions_car_rounded,
                    color: Color(0xFFE8C547), size: 15),
                const SizedBox(width: 7),
                Text('Vehicle Details',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _carMakeController,
                    label: 'Make',
                    icon: Icons.build_outlined,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(
                    controller: _carModelController,
                    label: 'Model',
                    icon: Icons.directions_car_outlined,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _carYearController,
                    label: 'Year',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      final yr = int.tryParse(v);
                      if (yr == null || yr < 1990 || yr > 2026) {
                        return 'Invalid year';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildEngineDropdown()),
              ],
            ),
          ],
          if (_isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {},
                child: const Text('Forgot password?',
                    style: TextStyle(
                        color: Color(0xFFE8C547),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngineDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedEngineType,
      dropdownColor: const Color(0xFF16161F),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Colors.white30, size: 20),
      decoration: InputDecoration(
        labelText: 'Engine',
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
        prefixIcon: const Icon(Icons.local_gas_station_outlined,
            color: Colors.white30, size: 18),
        filled: true,
        fillColor: const Color(0xFF16161F),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8C547), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: _engineTypes
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedEngineType = v),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white30, size: 18),
        suffixIcon: toggleObscure != null
            ? GestureDetector(
                onTap: toggleObscure,
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white30,
                  size: 18,
                ),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF16161F),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8C547), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B2B), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B2B), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8C547),
          foregroundColor: const Color(0xFF0A0A0F),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Color(0xFF0A0A0F)),
              )
            : Text(
                _isLogin ? 'Sign In' : 'Create Account',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.3),
              ),
      ),
    );
  }

  Widget _buildSwitchPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : 'Already have an account? ',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
        ),
        GestureDetector(
          onTap: _toggleMode,
          child: Text(
            _isLogin ? 'Register' : 'Sign In',
            style: const TextStyle(
                color: Color(0xFFE8C547),
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
