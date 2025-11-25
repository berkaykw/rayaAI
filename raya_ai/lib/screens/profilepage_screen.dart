import 'package:flutter/material.dart';
import 'package:raya_ai/screens/ProductCompatibilityTest.dart';
import 'package:raya_ai/screens/add_product.dart';
import 'package:raya_ai/screens/analysis_screen.dart';
import 'package:raya_ai/screens/loginpage_screen.dart';
import 'package:raya_ai/screens/analysis_history_screen.dart';
import 'package:raya_ai/screens/daily_tracking_screen.dart';
import 'package:raya_ai/theme/app_theme.dart';
import 'package:raya_ai/theme/theme_controller.dart';
import 'package:raya_ai/widgets-tools/privacy_security_screen.dart';
import 'package:raya_ai/widgets-tools/skin_profile_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raya_ai/widgets-tools/glass_bottom_navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  final int initialSelectedIndex;

  const ProfileScreen({Key? key, this.initialSelectedIndex = -1})
    : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  String? userName;
  String? userEmail;
  bool isLoading = true;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
    _loadUserData();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index)
      return; // aynı sayfaya tıklarsa yeniden yükleme

    setState(() {
      _selectedIndex = index;
    });

    Widget targetPage;

    switch (index) {
      case 0:
        targetPage = const ProductCompatibilityTest();
        break;
      case 1:
        targetPage = const AnalysisScreen();
        break;
      case 2:
        targetPage = const ProductAddScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => targetPage,
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _loadUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Profil fotoğrafını yükle
        final prefs = await SharedPreferences.getInstance();
        final imagePath = prefs.getString('profile_image_path_${user.id}');

        setState(() {
          userEmail = user.email;
          userName = user.userMetadata?['user_name'] ?? 'User';
          if (imagePath != null && File(imagePath).existsSync()) {
            _profileImage = File(imagePath);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Failed to load user data');
    }
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
          MaterialPageRoute(builder: (context) => const LoginpageScreen()),
          (route) => false, // tüm önceki sayfaları kaldır
        );
      }
    } catch (e) {
      _showError('Çıkış yapılamadı: $e');
    }
  }

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final user = supabase.auth.currentUser;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_path_${user.id}', image.path);

          setState(() {
            _profileImage = File(image.path);
          });
          _showSuccess('Profil fotoğrafı güncellendi');
        }
      }
    } catch (e) {
      _showError('Fotoğraf seçilemedi: $e');
    }
  }

  void _showRenameDialog() {
    final nameController = TextEditingController(text: userName);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color dialogColor =
        isDark ? const Color(0xFF2A2A2A) : theme.colorScheme.surface;
    final Color borderColor =
        isDark
            ? Colors.white.withOpacity(0.15)
            : Colors.black.withOpacity(0.05);
    final Color inputFill =
        isDark ? Colors.black54 : Colors.black.withOpacity(0.05);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dialogColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "İsmini Değiştir",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: "Yeni isim girin",
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "İptal",
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          final user = supabase.auth.currentUser;
                          if (newName.length > 16) {
                            _showError("İsim en fazla 16 karakter olabilir.");
                            return;
                          }
                          if (newName.isNotEmpty && user != null) {
                            try {
                              await supabase.auth.updateUser(
                                UserAttributes(data: {'user_name': newName}),
                              );

                              await supabase
                                  .from('user_skin_profiles')
                                  .update({'user_name': newName})
                                  .eq('id', user.id);

                              if (mounted) {
                                setState(() {
                                  userName = newName;
                                });
                                Navigator.of(context).pop();
                                _showSuccess('İsim başarıyla güncellendi');
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.of(context).pop();
                                _showError('İsim güncellenemedi: $e');
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          "Kaydet",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.7),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Profil Fotoğrafı Seç',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Kamera
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                _pickImage(ImageSource.camera);
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 24,
                                      horizontal: 16,
                                    ),
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.pink.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(
                                              0.15,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Kamera',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Galeri
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                _pickImage(ImageSource.gallery);
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 24,
                                      horizontal: 16,
                                    ),
                                    margin: EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.pink.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(
                                              0.15,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.photo_library_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Galeri',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      if (_profileImage != null)
                        Container(
                          margin: EdgeInsets.only(bottom: 12),
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _profileImage = null;
                              });
                              final user = supabase.auth.currentUser;
                              if (user != null) {
                                SharedPreferences.getInstance().then((prefs) {
                                  prefs.remove('profile_image_path_${user.id}');
                                });
                              }
                              Navigator.of(context).pop();
                              _showSuccess('Profil fotoğrafı kaldırıldı');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Fotoğrafı Kaldır',
                              style: TextStyle(
                                color: Colors.redAccent[200],
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'İptal',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color primary = theme.colorScheme.primary;
    final Color onSurface = theme.colorScheme.onSurface;
    final LinearGradient backgroundGradient =
        isDark
            ? AppGradients.darkBackground
            : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDFBFF), Color(0xFFEFE8F4)],
            );
    final themeController = ThemeControllerProvider.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child:
            isLoading
                ? Center(child: CircularProgressIndicator(color: primary))
                : Stack(
                  children: [
                    SafeArea(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: onSurface.withOpacity(0.7),
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const AnalysisScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              _buildProfileHeader(),

                              const SizedBox(height: 40),

                              _buildProfileOption(
                                icon: Icons.person_outline,
                                title: "Ad Değiştir",
                                onTap: _showRenameDialog,
                              ),
                              SizedBox(height: 12),
                              _buildProfileOption(
                                icon: Icons.spa_outlined, // Güzel bir ikon
                                title: 'Cilt Profilim',
                                onTap: () {
                                  // Birazdan oluşturacağımız yeni sayfaya yönlendir
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              SkinProfileDetailsScreen(),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 12),
                              _buildProfileOption(
                                icon: Icons.calendar_month_outlined,
                                title: 'Günlük Takip',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const DailyTrackingScreen(),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 12),
                              _buildProfileOption(
                                icon: Icons.history,
                                title: 'Geçmiş Analizler',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const AnalysisHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 12),
                              _buildThemeSection(
                                themeController: themeController,
                                theme: theme,
                                isDark: isDark,
                              ),
                              SizedBox(height: 12),

                              _buildProfileOption(
                                icon: Icons.lock_outline,
                                title: 'Gizlilik & Güvenlik',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              PrivacyAndSecurityScreen(),
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: 12),

                              _buildProfileOption(
                                icon: Icons.help_outline,
                                title: 'Yardım & Destek',
                                onTap: () {},
                              ),

                              const SizedBox(height: 30),

                              _buildActionButton(
                                text: 'Çıkış Yap',
                                color: Colors.red[600]!,
                                onPressed: _signOut,
                                textColor: Colors.white,
                              ),

                              const SizedBox(height: 112),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: GlassBottomNavBar(
                        selectedIndex: _selectedIndex,
                        onItemTapped: _onItemTapped,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor =
        isDark ? Colors.white.withOpacity(0.05) : theme.colorScheme.surface;
    final Color borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar
          GestureDetector(
            onTap: _showImagePickerDialog,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        _profileImage == null
                            ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.pink,
                                Colors.pinkAccent,
                                Colors.pink,
                              ],
                            )
                            : null,
                    color: _profileImage != null ? Colors.transparent : null,
                    border: Border.all(
                      color:
                          _profileImage != null
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white.withOpacity(0.3),
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child:
                      _profileImage != null
                          ? ClipOval(
                            child: Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            ),
                          )
                          : Center(
                            child: Text(
                              userName != null && userName!.isNotEmpty
                                  ? userName![0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8E9B), Colors.pink],
                      ),
                      border: Border.all(color: Color(0xFF2A2A2A), width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          Text(
            userName ?? '******',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),

          SizedBox(height: 6),

          Text(
            userEmail ?? 'email@example.com',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              letterSpacing: 0.2,
            ),
          ),
        ],
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
    final Color borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
    final Color iconColor = theme.iconTheme.color ?? theme.colorScheme.primary;
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
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: iconColor.withOpacity(0.85), size: 24),
                SizedBox(width: 16),
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

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
    required Color textColor,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27.5),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSection({
    required ThemeController themeController,
    required ThemeData theme,
    required bool isDark,
  }) {
    final ThemeMode currentMode = themeController.themeMode;
    final Color borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
    final Color cardColor =
        isDark ? Colors.white.withOpacity(0.05) : theme.colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tema',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Koyu veya açık temayı tercihine göre seç.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildThemeChoiceChip(
                  label: 'Koyu',
                  icon: Icons.nightlight_round,
                  isSelected: currentMode == ThemeMode.dark,
                  onTap: () => themeController.setThemeMode(ThemeMode.dark),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemeChoiceChip(
                  label: 'Açık',
                  icon: Icons.wb_sunny_outlined,
                  isSelected: currentMode == ThemeMode.light,
                  onTap: () => themeController.setThemeMode(ThemeMode.light),
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final Color primary = theme.colorScheme.primary;
    final bool isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      primary.withOpacity(0.2),
                      primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color:
              isSelected
                  ? null
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? primary
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05)),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? primary : theme.iconTheme.color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primary : theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
