import 'package:flutter/material.dart';
import 'package:raya_ai/screens/analysis_screen.dart';
import 'package:raya_ai/screens/sorular.dart';
import 'package:raya_ai/theme/app_theme.dart';
import 'package:raya_ai/theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class LoginpageScreen extends StatefulWidget {
  const LoginpageScreen({Key? key}) : super(key: key);

  @override
  State<LoginpageScreen> createState() => _LoginpageScreenState();
}

class _LoginpageScreenState extends State<LoginpageScreen> {
  bool isLogin = true;
  bool rememberMe = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkRememberMe();
    _setupAuthListener();
  }

  // ✅ Auth state değişikliklerini dinle
  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        _handleAuthNavigation();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ Google ile giriş fonksiyonu
  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);
    
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.rayaai://login-callback/',
      );
    } catch (error) {
      if (mounted) {
        _showError('Google giriş hatası: $error');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ✅ Apple ile giriş fonksiyonu
  Future<void> signInWithApple() async {
    setState(() => isLoading = true);
    
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.rayaai://login-callback/',
      );
    } catch (error) {
      if (mounted) {
        _showError('Apple giriş hatası: $error');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ✅ OAuth sonrası veya normal giriş sonrası yönlendirme
  Future<void> _handleAuthNavigation() async {
    final user = supabase.auth.currentUser;
    if (user == null || !mounted) return;

    final metadata = user.userMetadata;
    final bool hasCompletedOnboarding = metadata?['has_completed_onboarding'] ?? false;

    if (hasCompletedOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AnalysisScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SkinOnboardingScreen()),
      );
    }
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      _showError('Lütfen tüm alanları doldurun');
      return;
    }

    if (password != confirmPassword) {
      _showError('Şifreler eşleşmiyor');
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'user_name': name,
          'has_completed_onboarding': false,
        },
      );

      if (mounted) {
        _showSuccess('Kayıt Başarılı! Giriş yapabilirsiniz.');
      }
    } on AuthException catch (e) {
      _showError('Kayıt Başarısız: ${e.message}');
    } catch (e) {
      _showError('Beklenmeyen bir hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<bool> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Lütfen tüm alanları doldurun');
      return false;
    }

    setState(() => isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', rememberMe);
        _showSuccess('Giriş Başarılı!');
        return true;
      } else {
        _showError('Geçersiz kimlik bilgileri');
        return false;
      }
    } catch (e) {
      _showError('Giriş Başarısız');
      return false;
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleLoginNavigation() async {
    final success = await _signIn();
    if (!success || !mounted) return;
    await _handleAuthNavigation();
  }

  Future<void> _checkRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRemember = prefs.getBool('rememberMe') ?? false;

    if (savedRemember) {
      final session = supabase.auth.currentSession;
      if (session != null && mounted) {
        await _handleAuthNavigation();
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Lütfen email adresinizi girin');
      return;
    }

    setState(() => isLoading = true);

    try {
      await supabase.auth.resetPasswordForEmail(email);
      _showSuccess('Şifre sıfırlama emaili gönderildi!');
    } catch (e) {
      _showError('Hata: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.only(bottom: 25, left: 10, right: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.greenAccent[400],
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.only(bottom: 25, left: 10, right: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final ThemeController themeController =
        ThemeControllerProvider.of(context);
    final LinearGradient backgroundGradient = isDark
        ? AppGradients.darkBackground
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDFBFF),
              Color(0xFFEFE8F4),
            ],
          );
    final Color onSurface = theme.colorScheme.onSurface;
    final Color mutedText =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
            onSurface.withOpacity(0.7);
    final Color cardColor =
        isDark ? Colors.white.withOpacity(0.08) : theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: backgroundGradient),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        Text(
                          isLogin
                              ? 'Hesabınıza Giriş Yapın'
                              : 'Yeni Hesap Oluşturun',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isLogin
                              ? 'Kişisel Bakım Asistanın \n Seni Bekliyor'
                              : 'Kişiselleştirilmiş Bakım Dünyasına\nAdım At',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: mutedText,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              alignment:
                                  isLogin
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark ? theme.colorScheme.primary.withOpacity(0.6) : theme.colorScheme.primary.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isLogin = true;
                                      });
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      child: Center(
                                        child: Text(
                                          'Giriş Yap',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isLogin = false;
                                      });
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      child: Center(
                                        child: Text(
                                          'Kayıt Ol',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  if (!isLogin) ...[
                    _buildTextField(
                      context: context,
                      controller: _nameController,
                      hint: 'Ad',
                      icon: Icons.person_outline,
                      isPassword: false,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildTextField(
                    context: context,
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    isPassword: false,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    context: context,
                    controller: _passwordController,
                    hint: 'Şifre',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onTogglePassword: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),

                  if (!isLogin) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      context: context,
                      controller: _confirmPasswordController,
                      hint: 'Şifreyi Onayla',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      onTogglePassword: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                rememberMe = !rememberMe;
                              });
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: mutedText.withOpacity(0.6),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child:
                                  rememberMe
                                      ? Icon(
                                        Icons.check,
                                        size: 14,
                                        color: theme.colorScheme.primary,
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Beni Hatırla',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: mutedText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (isLogin)
                        TextButton(
                          onPressed: isLoading ? null : _resetPassword,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Şifremi Unuttum',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: mutedText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (isLogin) {
                                await _handleLoginNavigation();
                              } else {
                                await _signUp();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? theme.colorScheme.primary.withOpacity(0.6) : theme.colorScheme.primary.withOpacity(0.9),
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27.5),
                        ),
                        elevation: 0,
                        disabledBackgroundColor:
                            theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      child: Text(
                        isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (isLogin)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: mutedText.withOpacity(0.3),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'veya',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: mutedText,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: mutedText.withOpacity(0.3),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                context: context,
                                icon: Icons.g_mobiledata,
                                text: 'Google',
                                onTap: isLoading ? null : signInWithGoogle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSocialButton(
                                context: context,
                                icon: Icons.apple,
                                text: 'Apple',
                                onTap: isLoading ? null : signInWithApple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin
                              ? 'Hesabın yok mu? '
                              : 'Zaten bir hesabın var mı? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedText,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isLogin = !isLogin;
                            });
                          },
                          child: Text(
                            isLogin ? 'Kayıt Ol' : 'Giriş Yap',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  themeController.setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                },
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color fillColor =
        isDark ? Colors.white.withOpacity(0.08) : theme.colorScheme.surface;
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);
    final Color iconColor =
        theme.iconTheme.color?.withOpacity(0.5) ?? Colors.grey;

    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscureText,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.45),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: iconColor,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color containerColor =
        isDark ? Colors.white.withOpacity(0.08) : theme.colorScheme.surface;
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.25)
        : Colors.black.withOpacity(0.2);
    final Color iconColor =
        theme.iconTheme.color ?? theme.colorScheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(25),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}