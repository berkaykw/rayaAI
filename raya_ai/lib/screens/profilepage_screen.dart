import 'package:flutter/material.dart';
import 'package:raya_ai/screens/ProductCompatibilityTest.dart';
import 'package:raya_ai/screens/add_product.dart';
import 'package:raya_ai/screens/analysis_screen.dart';
import 'package:raya_ai/screens/loginpage_screen.dart';
import 'package:raya_ai/screens/analysis_history_screen.dart';
import 'package:raya_ai/widgets-tools/privacy_security_screen.dart';
import 'package:raya_ai/widgets-tools/skin_profile_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raya_ai/widgets-tools/glass_bottom_navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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

  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _onItemTapped(int index) {
  if (_selectedIndex == index) return; // aynı sayfaya tıklarsa yeniden yükleme

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
        return FadeTransition(
          opacity: animation,
          child: child,
        );
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
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                                          color: Colors.white.withOpacity(0.15),
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
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                                          color: Colors.white.withOpacity(0.15),
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
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        );
      },
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
        child:
            isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.pink))
                : Stack(
                  children: [
                    SafeArea(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.topLeft,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AnalysisScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Profile Header
                              _buildProfileHeader(),
                    
                              SizedBox(height: 40),
                    
                              // Profile Options
                              _buildProfileOption(
                      icon: Icons.person_outline,
                      title: "Ad Değiştir",
                      onTap: () {
                        TextEditingController _nameController = TextEditingController(text: userName);
                    
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Color(0xFF2A2A2A),
                            child: SingleChildScrollView(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                    Text(
                      "İsmini Değiştir",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Sabit renk
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                         color: Colors.white, // Yazı rengi
                         fontSize: 16,
                        ),
                      decoration: InputDecoration(
                        hintText: "Yeni isim girin",
                        filled: true,
                        fillColor: Colors.black54, // Sabit renk
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
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                      onPressed: () async {
                        final newName = _nameController.text.trim();
                        final user = supabase.auth.currentUser; // Mevcut kullanıcıyı al
                        if (newName.length > 16) {
                        _showError("İsim en fazla 16 karakter olabilir.");
                        return;
                        }
                        if (newName.isNotEmpty && user != null) {
                          try {
                            // 1. ADIM: Authentication meta verisini güncelle
                            // Bu, gelecekteki trigger'lar veya fonksiyonlar için
                            // "ana kaynak" olarak kalır.
                            await supabase.auth.updateUser(
                              UserAttributes(
                                data: {'user_name': newName},
                              ),
                            );
                    
                          // 2. ADIM: "user_skin_profiles" tablosundaki veriyi güncelle
                            // (Eski kodunuzda 'profiles' yazıyordu, düzelttik)
                            await supabase
                                .from('user_skin_profiles') // <-- DÜZELTME BURADA
                                .update({'user_name': newName})
                                .eq('id', user.id); // Sadece mevcut kullanıcının satırını güncelle
                    
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
                            backgroundColor: Colors.greenAccent[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            "Kaydet",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
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
                        );
                      },),
                    
                    
                              SizedBox(height: 12),
                              _buildProfileOption(
                            icon: Icons.spa_outlined, // Güzel bir ikon
                            title: 'Cilt Profilim',
                            onTap: () {
                              // Birazdan oluşturacağımız yeni sayfaya yönlendir
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SkinProfileDetailsScreen(),
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
                                      builder: (context) => const AnalysisHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 12),
                    
                              _buildProfileOption(
                                icon: Icons.lock_outline,
                                title: 'Gizlilik & Güvenlik',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PrivacyAndSecurityScreen(),
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
                    
                    
                              SizedBox(height: 30),
                    
                              // Logout Button
                              _buildActionButton(
                                text: 'Çıkış Yap',
                                color: Colors.grey[900]!,
                                onPressed: _signOut,
                              ),
                    
                              SizedBox(height: 12),
                              SizedBox(height: 100),
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
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
                    gradient: _profileImage == null
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
                      color: _profileImage != null
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
                  child: _profileImage != null
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
                        colors: [
                          Color(0xFFFF8E9B),
                          Colors.pink,
                        ],
                      ),
                      border: Border.all(
                        color: Color(0xFF2A2A2A),
                        width: 3.5,
                      ),
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

          // User Name
          Text(
            userName ?? '******',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              height: 1.2,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.15),
                ),
                Shadow(
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  color: Colors.black.withOpacity(0.25),
                ),
              ],
            ),
          ),

          SizedBox(height: 6),

          // User Email
          Text(
            userEmail ?? 'email@example.com',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
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
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
                Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.4),
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
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27.5),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
 

}
