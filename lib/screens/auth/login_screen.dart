import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/snackbar_utils.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _legacyUserIdController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _legacyUserIdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authController = ref.read(authControllerProvider);

    try {
      if (_isLogin) {
        await authController.signInWithIdOrEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await authController.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _legacyUserIdController.text.trim(),
          _nameController.text.trim(),
        );
      }
      // On success, router will auto redirect
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarUtils.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5C0A0A),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
              child: Column(
                children: [
                  const SizedBox(height: 160), // Space for background temples/logo
                  
                  // Ribbon header text overlay
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6E0D0D),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'అణు కల్పక్కం తెలుగు సమితి',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoSansTelugu', // Fallback if no telugu font is defined
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Main Login Card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF2E6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            _isLogin ? 'స్వాగతం! మళ్లీ కలిసినందుకు సంతోషం' : 'కొత్త ఖాతా సృష్టించండి',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF5C0A0A),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Lotus icon decoration
                          const Icon(Icons.spa, color: Color(0xFFD4AF37), size: 24),
                          const SizedBox(height: 24),
                          
                          if (!_isLogin) ...[
                            // Name Field
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: Color(0xFF5C0A0A)),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF3E5D4),
                                hintText: 'పూర్తి పేరు / Full Name (తప్పనిసరి)',
                                hintStyle: const TextStyle(color: Color(0xFF9E7C65)),
                                prefixIcon: const Icon(Icons.person, color: Color(0xFF5C0A0A)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF5C0A0A), width: 2),
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'పేరు తప్పనిసరి' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Legacy User ID Field
                            TextFormField(
                              controller: _legacyUserIdController,
                              style: const TextStyle(color: Color(0xFF5C0A0A)),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFF3E5D4),
                                hintText: 'సభ్యత్వ ID / User ID (తప్పనిసరి)',
                                hintStyle: const TextStyle(color: Color(0xFF9E7C65)),
                                prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF5C0A0A)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF5C0A0A), width: 2),
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'సభ్యత్వ ID తప్పనిసరి' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Email Field (Used for ID or Email during login)
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Color(0xFF5C0A0A)),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF3E5D4),
                              hintText: _isLogin ? 'ఇమెయిల్ అడ్రస్ / User ID' : 'ఇమెయిల్ అడ్రస్',
                              hintStyle: const TextStyle(color: Color(0xFF9E7C65)),
                              prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF5C0A0A)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF5C0A0A), width: 2),
                              ),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'తప్పనిసరి' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Color(0xFF5C0A0A)),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF3E5D4),
                              hintText: 'పాస్‌వర్డ్',
                              hintStyle: const TextStyle(color: Color(0xFF9E7C65)),
                              prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF5C0A0A)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF5C0A0A),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF5C0A0A), width: 2),
                              ),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'తప్పనిసరి' : null,
                          ),
                          
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push('/forgot-password'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                                  child: Text(
                                    'పాస్‌వర్డ్ మర్చిపోయారా?',
                                    style: TextStyle(color: Color(0xFF5C0A0A), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 24),
                          
                          // Login Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5C0A0A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isLogin ? 'లాగిన్ చేయండి' : 'సైన్ అప్ చేయండి',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Toggle Mode
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLogin ? "అకౌంట్ లేదా?" : "ఇప్పటికే అకౌంట్ ఉందా?",
                                style: const TextStyle(color: Color(0xFF5C0A0A), fontWeight: FontWeight.w500),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _isLogin = !_isLogin),
                                child: Text(
                                  _isLogin ? 'సైన్ అప్ చేయండి' : 'లాగిన్ చేయండి',
                                  style: const TextStyle(
                                    color: Color(0xFF7D0E0E),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

