import 'package:flutter/material.dart';
import 'package:raya_ai/screens/loginpage_screen.dart';
import 'package:raya_ai/theme/app_theme.dart';
import 'package:raya_ai/widgets-tools/change_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacyAndSecurityScreen extends StatefulWidget {
  const PrivacyAndSecurityScreen({super.key});

  @override
  State<PrivacyAndSecurityScreen> createState() =>
      _PrivacyAndSecurityScreenState();
}

class _PrivacyAndSecurityScreenState extends State<PrivacyAndSecurityScreen> {
  final supabase = Supabase.instance.client;

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

  Future<void> _signOut() async {
  try {
    // 1️⃣ Supabase oturumunu kapat
    await supabase.auth.signOut();

    // 2️⃣ Remember Me bilgisini temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');

    // 3️⃣ Login ekranına yönlendir
  if (mounted) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => LoginpageScreen()),
    (route) => false, // tüm önceki sayfaları kaldır
  );
}
  } catch (e) {
    _showError('Çıkış yapılamadı: $e');
  }
}

  Future<void> _deleteAccount() async {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color dialogColor =
        isDark ? const Color(0xFF2A2A2A) : theme.colorScheme.surface;
    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: dialogColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Hesabı Sil',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor.withOpacity(0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('İptal', style: TextStyle(color: textColor)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sil', style: TextStyle(color: theme.colorScheme.error)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        // Supabase'de hesap silme işlemi
        _showSuccess('Account deleted successfully');
        await _signOut();
      } catch (e) {
        _showError('Failed to delete account: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        "Gizlilik ve Güvenlik",
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Güvenlik"),
                      // Şifre Değiştir
                      _buildProfileOption(
                        icon: Icons.password_rounded,
                        title: "Şifre Değiştir",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),
                      _buildSectionTitle("Gizlilik ve Veri"),
                      _buildProfileOption(
                        icon: Icons.description_outlined,
                        title: "Kullanım Koşulları",
                        onTap: () {
                        },
                      ),
                      const SizedBox(height: 12),
                      // Gizlilik Politikası
                      _buildProfileOption(
                        icon: Icons.shield_outlined,
                        title: "Gizlilik Politikası",
                        onTap: () {
                        },
                      ),
                      const SizedBox(height: 50),
                      Container(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                                onPressed: _deleteAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27.5),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Hesabı Sil',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Profil sayfanızdaki stilin aynısını kullanabilirsiniz
  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 10, top: 10),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor =
        isDark ? Colors.white.withOpacity(0.05) : theme.colorScheme.surface;
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);
    final Color iconColor =
        theme.iconTheme.color?.withOpacity(0.85) ?? theme.colorScheme.primary;
    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.arrow_forward_ios,
                      color: textColor.withOpacity(0.4),
                      size: 16,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}