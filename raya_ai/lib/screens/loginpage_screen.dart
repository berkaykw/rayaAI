import 'package:flutter/material.dart';
import 'package:raya_ai/screens/analysis_screen.dart';
import 'package:raya_ai/screens/sorular.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
void initState() {
  super.initState();
  _checkRememberMe();
}

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

 Future<void> _signUp() async {
  // Alanlardan verileri al ve boşlukları temizle
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  final name = _nameController.text.trim();
  final confirmPassword = _confirmPasswordController.text.trim();

  // ✅ Yazım hatası düzeltildi (mantıksal OR eklendi)
  if (email.isEmpty || password.isEmpty || name.isEmpty) {
    _showError('Lütfen tüm alanları doldurun');
    return;
  }


  if (password != confirmPassword) {
    _showError('Şifreler eşleşmiyor');
    return;
  }

 try {
      // ✅ has_completed_onboarding: false bayrağını metadata'ya ekle
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'user_name': name,
          'has_completed_onboarding': false, // <-- BU SATIRI EKLE
        },
      );

      if (mounted) {
        _showSuccess(
          'Kayıt Başarılı! Lütfen e-posta adresinizi doğrulayın.',
        );
      }
    } on AuthException catch (e) {
      _showError('Kayıt Başarısız: ${e.message}');
    } catch (e) {
      _showError('An unexpected error occurred: $e');
    }
  }

  // ✅ Giriş Yapma Fonksiyonu
  Future<bool> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Lütfen tüm alanları doldurun');
      return false; // ❗ başarısız
    }

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', rememberMe); // ✅ remember kaydı
        _showSuccess('Giriş Başarılı!');
        return true;
      } else {
        _showError('Invalid credentials');
        return false;
      }
    } catch (e) {
      _showError('Giriş Başarısız');
      return false;
    }
  }

  // ✅ GİRİŞ İÇİN YENİ YÖNLENDİRME FONKSİYONU
  Future<void> _handleLoginNavigation() async {
    // Önce normal giriş yapmayı dene
    final success = await _signIn();

    // Giriş başarısızsa veya ekran artık yoksa dur
    if (!success || !mounted) return;

    try {
      // Giriş yapan kullanıcıyı al
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showError("Kullanıcı oturumu bulunamadı.");
        return;
      }

      // Kullanıcının metadata'sını kontrol et
      final metadata = user.userMetadata;
      // '?? false' kısmı, herhangi bir nedenle bayrak hiç ayarlanmamışsa
      // (örn: eski kullanıcılar) onu 'false' varsayar.
      final bool hasCompletedOnboarding =
          metadata?['has_completed_onboarding'] ?? false;

      if (hasCompletedOnboarding) {
        // Soruları daha önce tamamlamış -> Ana Ekrana git
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AnalysisScreen()),
        );
      } else {
        // İlk girişi, soruları doldurmadı -> Soru Ekranına git
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SkinOnboardingScreen()),
        );
      }
    } catch (e) {
      _showError("Yönlendirme hatası: $e");
    }
  }
  
  // ✅ Beni Hatırla Fonksiyonu
  Future<void> _checkRememberMe() async {
  final prefs = await SharedPreferences.getInstance();
  final savedRemember = prefs.getBool('rememberMe') ?? false;

  if (savedRemember) {
    final session = supabase.auth.currentSession;
    if (session != null) {
      // Kullanıcı zaten giriş yapmış → AnalysisScreen’e yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AnalysisScreen()),
      );
    }
  }
}
  // ✅ Şifre Sıfırlama (E-mail linki gönderir)
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    try {
      await supabase.auth.resetPasswordForEmail(email);
      _showSuccess('Password reset email sent!');
    } catch (e) {
      _showError('Error: $e');
    }
  }

  // ✅ Snackbar helper
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              Center(
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Text(
                      isLogin
                          ? 'Hesabınıza Giriş Yapın'
                          : 'Yeni Hesap Oluşturun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      isLogin
                          ? 'Kişisel Bakım Asistanın \n Seni Bekliyor'
                          : 'Kişiselleştirilmiş Bakım Dünyasına\nAdım At',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),

              // Login / Sign up Toggle
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Stack(
                      children: [
                        AnimatedAlign(
                          duration: Duration(milliseconds: 300),
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
                                color: Color(0xFF3A3A3A),
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
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
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
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

              SizedBox(height: 30),

              // Form Alanları
              if (!isLogin) ...[
                _buildTextField(
                  controller: _nameController,
                  hint: 'Ad',
                  icon: Icons.person_outline,
                ),
                SizedBox(height: 16),
              ],

              _buildTextField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email_outlined,
              ),

              SizedBox(height: 16),

              _buildTextField(
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
                SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hint: 'Şifreyi Onayla',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onTogglePassword: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ],

              SizedBox(height: 16),

              // Remember me / Forgot password
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
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child:
                              rememberMe
                                  ? Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.pink,
                                  )
                                  : null,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Beni Hatırla',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (isLogin)
                    TextButton(
                      onPressed: _resetPassword,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Şifremi Unuttum',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 30),

              // Login/Sign up Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                 onPressed: () async {
            if (isLogin) {
              // ✅ _signIn() ve yönlendirme mantığını ayır.
              //    Yeni fonksiyonu burada çağır.
              await _handleLoginNavigation();
            } else {
              _signUp();
            }
          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27.5),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Social Login Buttons
              /*        Row(
                children: [
                  Expanded(
                    child: _buildSocialButton(
                      icon: Icons.g_mobiledata,
                      text: 'Google',
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildSocialButton(
                      icon: Icons.apple,
                      text: 'Apple',
                    ),
                  ),
                ],
              ),    */
              SizedBox(height: 20),

              // Footer Text
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLogin ? 'Hesabın yok mu? ' : 'Zaten bir hesabın var mı? ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
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
                          color: Colors.pink,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscureText,
        style: TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.4),
            size: 20,
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withOpacity(0.4),
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

  Widget _buildSocialButton({required IconData icon, required String text}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(1), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
