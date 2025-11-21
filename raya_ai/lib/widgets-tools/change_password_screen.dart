import 'package:flutter/material.dart';
import 'package:raya_ai/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

 Future<void> _changePassword() async {
    // 1. Formun geçerli olup olmadığını kontrol et
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. E-postayı ve şifreleri al
    final userEmail = _supabase.auth.currentUser?.email;
    if (userEmail == null) {
      _showError('Kullanıcı e-postası bulunamadı. Lütfen tekrar giriş yapın.');
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    setState(() => _isLoading = true);

    try {
      // 3. ADIM: MEVCUT ŞİFREYİ DOĞRULA (Yeni Yöntem)
      // Kullanıcıyı mevcut şifresiyle yeniden giriş yaptırmayı deneyerek
      // şifrenin doğruluğunu kontrol ediyoruz.
      await _supabase.auth.signInWithPassword(
        email: userEmail,
        password: currentPassword,
      );

      // 4. ADIM: Doğrulama başarılıysa, şifreyi GÜNCELLE
      // (signInWithPassword başarılı olduysa buraya geçer)
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 5. BAŞARI
      if (mounted) {
        _showSuccess('Şifreniz başarıyla güncellendi.');
        Navigator.pop(context); // Bir önceki (Gizlilik) sayfasına dön
      }

    } on AuthException catch (e) {
      if (mounted) {
        // Hata mesajı "Invalid login credentials" ise
        // (signInWithPassword bu hatayı verir)
        final message = (e.message.contains("Invalid login credentials"))
            ? 'Mevcut şifreniz hatalı.'
            : e.message;
        _showError('Hata: $message');
      }
    } catch (e) {
      if (mounted) {
        _showError('Beklenmedik bir hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primary = theme.colorScheme.primary;
    final Color onSurface = theme.colorScheme.onSurface;
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Özel AppBar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 22),
                      color: onSurface.withOpacity(0.7),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        "Şifre Değiştir",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Boşluk
                  ],
                ),
              ),

              // İçerik
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Mevcut Şifre
                        _buildPasswordField(
                          controller: _currentPasswordController,
                          label: 'Mevcut Şifre',
                          obscureText: _obscureCurrent,
                          onToggleObscure: () =>
                              setState(() => _obscureCurrent = !_obscureCurrent),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Lütfen mevcut şifrenizi girin'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        // Yeni Şifre
                        _buildPasswordField(
                          controller: _newPasswordController,
                          label: 'Yeni Şifre',
                          obscureText: _obscureNew,
                          onToggleObscure: () =>
                              setState(() => _obscureNew = !_obscureNew),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Lütfen yeni bir şifre girin';
                            }
                            if (val.length < 6) {
                              return 'Şifre en az 6 karakter olmalıdır';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        // Yeni Şifre Tekrar
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Yeni Şifre (Tekrar)',
                          obscureText: _obscureConfirm,
                          onToggleObscure: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Lütfen yeni şifrenizi doğrulayın';
                            }
                            if (val != _newPasswordController.text) {
                              return 'Şifreler eşleşmiyor';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                        // Kaydet Butonu
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              disabledBackgroundColor:
                                  primary.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27.5),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    'Şifreyi Güncelle',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tasarımınızla uyumlu bir text field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color fillColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);
    final Color labelColor =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
            Colors.grey;
    final Color iconColor =
        theme.iconTheme.color?.withOpacity(0.7) ?? Colors.grey;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: iconColor,
          ),
          onPressed: onToggleObscure,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }

  // Hata ve başarı mesajları için yardımcı fonksiyonlar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(message, style: TextStyle(fontWeight: FontWeight.bold)),
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
          child: Text(message, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        backgroundColor: Colors.greenAccent[400],
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.only(bottom: 25, left: 10, right: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}