import 'dart:io';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raya_ai/screens/ProductCompatibilityTest.dart';
import 'package:raya_ai/screens/add_product.dart';
import 'package:raya_ai/screens/profilepage_screen.dart';
import 'package:raya_ai/widgets-tools/glass_bottom_navbar.dart';
import '../services/api_service.dart';
import '../models/analysis_model.dart';
import 'package:raya_ai/widgets-tools/full_screen_image_viewer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raya_ai/theme/app_theme.dart';
import 'daily_tracking_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _selectedIndex = 1;
  final ApiService _apiService = ApiService();
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? userName;
  String userTier = 'premium'; // 'free' veya 'premium'

  String? _statusMessage;
  SkinAnalysisResult? _analysisResult;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _imageUrlForDisplay;
  File? _selectedImageFile;
  bool _hasDailyAnalysis = false;

  // Yeni: Ürün önerisi tercihleri
  bool _includeProducts = false;
  int _productCount = 3;

  bool _isSabahRutiniExpanded = false;
  bool _isAksamRutiniExpanded = false;
  bool _isMakyajOnerileriExpanded = false;
  bool _isNotlarIpuclariExpanded = false;
  bool _isKapanisNotuExpanded = false;
  bool _isUrunOnerileriExpanded = false;

  // Tema kontrolü
  bool get _isDarkTheme => Theme.of(context).brightness == Brightness.dark;

  Color get _primaryTextColor =>
      _isDarkTheme ? AppColors.darkText : AppColors.lightText;

  Color get _secondaryTextColor =>
      _isDarkTheme ? Colors.white70 : Colors.black54;

  Color get _backgroundColor =>
      _isDarkTheme ? AppColors.darkBackground : AppColors.lightBackground;

  LinearGradient get _backgroundGradient =>
      _isDarkTheme
          ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.black],
          )
          : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.lightBackground, Color(0xFFE6E6FA)],
          );

  Color get _cardBorderColor =>
      _isDarkTheme
          ? Colors.white.withOpacity(0.2)
          : Colors.black.withOpacity(0.1);

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() {
      setState(() {});
    });
    _loadUserName();
    _loadUserName();
    _loadUserTier().then((_) => _checkDailyAnalysisStatus());
  }

  void _loadUserName() {
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      userName = user?.userMetadata?['user_name'];
    });
  }

  Future<void> _loadUserTier() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // final response =
      //     await Supabase.instance.client
      //         .from('user_subscriptions')
      //         .select('tier')
      //         .eq('user_id', user.id)
      //         .eq('is_active', true)
      //         .maybeSingle();

      if (!mounted) return;
      setState(() {
        // TEST İÇİN PREMIUM YAPILDI
        userTier = 'premium'; // response?['tier'] ?? 'free';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        userTier = 'premium'; // 'free';
      });
    }
  }

  Future<void> _checkDailyAnalysisStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'analyses_${user.id}';
      final List<String> existingEncoded =
          prefs.getStringList(storageKey) ?? [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      bool found = false;
      for (var item in existingEncoded) {
        final Map<String, dynamic> decoded = jsonDecode(item);
        final timestamp = decoded['timestamp'];
        final type = decoded['type'];
        if (timestamp != null) {
          final date = DateTime.parse(timestamp);
          final analysisDate = DateTime(date.year, date.month, date.day);
          if (analysisDate.isAtSameMomentAs(today)) {
            // type 'daily' veya null (eski kayıtlar) ise günlük analiz yapılmış say
            if (type == 'daily' || type == null) {
              found = true;
              break;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _hasDailyAnalysis = found;
        });
      }
    } catch (e) {
      print('Limit kontrolü hatası: $e');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
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

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        _setSelectedImage(File(image.path));
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Kamera açılırken hata oluştu: $e';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        _setSelectedImage(File(image.path));
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Galeri açılırken hata oluştu: $e';
      });
    }
  }

  void _setSelectedImage(File imageFile) {
    setState(() {
      _selectedImageFile = imageFile;
      _imageUrlForDisplay = null;
      _statusMessage = null;
      _analysisResult = null;
    });
  }

  Future<void> _analyzePickedImage() async {
    if (_selectedImageFile == null) {
      setState(() {
        _statusMessage = 'Lütfen önce bir resim seçin.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    // 1. KULLANICI ID'SİNİ AL
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage =
            "Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.";
      });
      return;
    }
    final String userId = user.id;

    // --- GÜNLÜK LİMİT KONTROLÜ (FREE KULLANICILAR İÇİN) ---
    if (userTier == 'free') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final storageKey = 'analyses_$userId';
        final List<String> existingEncoded =
            prefs.getStringList(storageKey) ?? [];

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        bool hasAnalysisToday = false;

        for (var item in existingEncoded) {
          final Map<String, dynamic> decoded = jsonDecode(item);
          final timestamp = decoded['timestamp'];
          if (timestamp != null) {
            final date = DateTime.parse(timestamp);
            final analysisDate = DateTime(date.year, date.month, date.day);
            if (analysisDate.isAtSameMomentAs(today)) {
              hasAnalysisToday = true;
              break;
            }
          }
        }

        if (hasAnalysisToday) {
          _showPremiumDialog();
          return; // Analizi başlatma
        }
      } catch (e) {
        print('Limit kontrolü hatası: $e');
        // Hata olsa bile devam etsin mi? Şimdilik devam etsin, kullanıcı mağdur olmasın.
      }
    }
    // -------------------------------------------------------

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _analysisResult = null;
    });

    try {
      // 2. SERVİSİ YENİ PARAMETRELERLE ÇAĞIR (GÜNCELLENDİ)
      final result = await _apiService.analyzeImageFromGallery(
        _selectedImageFile!,
        userId,
        _includeProducts,
        _productCount,
      );

      setState(() {
        _analysisResult = result;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Analiz sırasında bir hata oluştu: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCurrentAnalysis() async {
    // Eğer zaten kaydetme işlemi devam ediyorsa, yeni bir işlem başlatma
    if (_isSaving) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = 'Kullanıcı oturumu bulunamadı.';
      });
      return;
    }
    if (_analysisResult == null) {
      setState(() {
        _statusMessage = 'Kaydedilecek analiz bulunamadı.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'analyses_${user.id}';
      final List<String> existingEncoded =
          prefs.getStringList(storageKey) ?? [];

      // Check if daily analysis exists for today
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      bool hasDailyToday = false;

      for (var item in existingEncoded) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(item);
          final timestamp = decoded['timestamp'];
          final type = decoded['type'];
          if (timestamp != null && type == 'daily') {
            final date = DateTime.parse(timestamp);
            final analysisDate = DateTime(date.year, date.month, date.day);
            if (analysisDate.isAtSameMomentAs(today)) {
              hasDailyToday = true;
              break;
            }
          }
        } catch (_) {}
      }

      final String analysisType = hasDailyToday ? 'normal' : 'daily';

      final Map<String, dynamic> entry = {
        'timestamp': DateTime.now().toIso8601String(),
        'imagePath': _selectedImageFile?.path,
        'imageUrl': _imageUrlForDisplay,
        'analysis': _analysisResult!.toJson(),
        'type': analysisType,
      };

      existingEncoded.add(jsonEncode(entry));
      await prefs.setStringList(storageKey, existingEncoded);

      if (mounted) {
        _showSuccess('Analiz kaydedildi');
        _checkDailyAnalysisStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Analiz kaydedilemedi: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _resetState() {
    setState(() {
      _isLoading = false;
      _isSaving = false;
      _statusMessage = null;
      _analysisResult = null;
      _selectedImageFile = null;
      _imageUrlForDisplay = null;
      _includeProducts = false;
      _productCount = 3;
    });
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

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[900]!, Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.pink.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Premium Icon
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pinkAccent, Colors.pink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Title
                    Text(
                      'Premium\'a Geçin',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Daha fazla özelliğin keyfini çıkarın',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 24),

                    // Features
                    _buildPremiumFeature(
                      Icons.shopping_bag,
                      '10 Ürün Önerisi',
                      'Daha fazla seçenek, daha iyi sonuçlar',
                    ),
                    SizedBox(height: 12),
                    _buildPremiumFeature(
                      Icons.compare,
                      'Detaylı Karşılaştırma',
                      'Ürünleri yan yana inceleyin',
                    ),
                    SizedBox(height: 12),
                    _buildPremiumFeature(
                      Icons.support_agent,
                      'Öncelikli Destek',
                      'Sorularınız hızlıca cevaplanır',
                    ),
                    SizedBox(height: 12),
                    _buildPremiumFeature(
                      Icons.block,
                      'Reklamsız Deneyim',
                      'Kesintisiz kullanım',
                    ),
                    SizedBox(height: 24),

                    // Price Box
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.pinkAccent.withOpacity(0.35),
                            Colors.pink.withOpacity(0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₺169,99',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'aylık',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₺339,99',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  decorationThickness: 2,
                                  decorationColor: Colors.black.withOpacity(
                                    0.6,
                                  ),
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '%50 İndirim',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Premium satın alma işlemi
                          Navigator.pop(context);
                          _showSuccess(
                            'Premium özelliği yakında aktif olacak!',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.pink.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Premium\'a Geç',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Daha Sonra',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanBadge() {
    bool isPremium = userTier == 'premium';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isPremium
                ? const Color(0xFFE23F75).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPremium ? const Color(0xFFE23F75) : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPremium) ...[
            const Icon(
              Icons.workspace_premium,
              color: Color(0xFFE23F75),
              size: 12,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            isPremium ? 'Premium' : 'Free',
            style: TextStyle(
              color: isPremium ? const Color(0xFFE23F75) : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: _backgroundGradient),
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start, // Sola hizala
                              mainAxisSize:
                                  MainAxisSize
                                      .min, // Sadece gerektiği kadar yer kapla
                              children: [
                                // 1. Kısım: "Merhaba," (Soluk ve Zarif)
                                Row(
                                  children: [
                                    Text(
                                      'Merhaba,',
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.2,
                                        color: _primaryTextColor.withOpacity(
                                          0.7,
                                        ), // Soluk renk
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildPlanBadge(),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      colors: const [
                                        Color(
                                          0xFFE23F75,
                                        ), // Senin Koyu Pemben (Canlı)
                                        Color.fromARGB(
                                          255,
                                          225,
                                          149,
                                          176,
                                        ), // Ortaya çok hafif daha açık bir ton (Geçişi yumuşatır)
                                        Color(0xFFE23F75), // Tekrar Koyu Pembe
                                      ],
                                      // Renklerin nerede başlayıp biteceğini ayarlar (0.0 -> 0.5 -> 1.0)
                                      stops: const [0.1, 0.5, 0.9],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      tileMode:
                                          TileMode
                                              .mirror, // Geçişin kenarlarda yumuşak bitmesini sağlar
                                    ).createShader(bounds);
                                  },
                                  child: Text(
                                    userName ?? '******',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                      height: 1.2,
                                      letterSpacing: -0.5,
                                      color:
                                          Colors
                                              .white, // ShaderMask altında bu renk önemsizdir ama render için gereklidir
                                      shadows:
                                          _isDarkTheme
                                              ? [
                                                // KOYU TEMA: Derinlik için Siyah Gölge
                                                Shadow(
                                                  offset: const Offset(0, 4),
                                                  blurRadius: 12,
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                ),
                                              ]
                                              : [
                                                // AÇIK TEMA: Parlama (Glow) için Pembe Gölge
                                                Shadow(
                                                  offset: const Offset(
                                                    0,
                                                    0,
                                                  ), // Gölge tam arkada olsun
                                                  blurRadius:
                                                      10, // Işığın yayılma miktarı
                                                  // Ana rengin (0xFFE23F75) şeffaf hali
                                                  color: const Color(
                                                    0xFFE23F75,
                                                  ).withOpacity(0.5),
                                                ),
                                                // İsteğe bağlı: Daha belirgin olması için ikinci bir katman
                                                Shadow(
                                                  offset: const Offset(0, 2),
                                                  blurRadius: 4,
                                                  color: const Color(
                                                    0xFFE23F75,
                                                  ).withOpacity(0.3),
                                                ),
                                              ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        _isDarkTheme
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _cardBorderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const DailyTrackingScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.calendar_today_outlined,
                                    ),
                                    iconSize: 25,
                                    color: _primaryTextColor,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        _isDarkTheme
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _cardBorderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (_, __, ___) => ProfileScreen(
                                                initialSelectedIndex:
                                                    _selectedIndex,
                                              ),
                                          transitionDuration: const Duration(
                                            milliseconds: 350,
                                          ),
                                          transitionsBuilder: (
                                            _,
                                            animation,
                                            __,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                    iconSize: 25,
                                    color: _primaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_isLoading &&
                          _statusMessage == null &&
                          _analysisResult == null)
                        Column(
                          children: [
                            _buildCenterText(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      if (!_isLoading &&
                          _statusMessage == null &&
                          _analysisResult == null)
                        Column(
                          children: [
                            _buildButtonCamera(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      if (!_isLoading &&
                          _statusMessage == null &&
                          _analysisResult == null)
                        Column(
                          children: [
                            _buildButtonGalery(),
                            const SizedBox(height: 20),
                          ],
                        ),

                      // Seçilen resim ve ürün önerisi seçenekleri
                      if (_selectedImageFile != null &&
                          !_isLoading &&
                          _analysisResult == null)
                        Column(
                          children: [
                            _buildSelectedImagePreview(),
                            const SizedBox(height: 20),
                            _buildProductOptionsSection(),
                            const SizedBox(height: 20),
                            _buildAnalyzeButton(),
                            const SizedBox(height: 40),
                          ],
                        ),

                      _buildBody(),
                      SizedBox(height: 200),
                      if (_isLoading &&
                          _statusMessage == null &&
                          _analysisResult == null)
                        SizedBox(height: 300),
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

  Widget _buildProductOptionsSection() {
    return Container(
      decoration: BoxDecoration(
        // --- ARKA PLAN GRADYANI ---
        gradient: LinearGradient(
          colors:
              _isDarkTheme
                  ? [
                    // Koyu Mod (Aynı kaldı)
                    Colors.purple.withOpacity(0.15),
                    Colors.pink.withOpacity(0.15),
                  ]
                  : [
                    // AÇIK MOD (YENİ - Belirgin Koyumsu Pembe Tonları):
                    // Daha doygun, gül kurusu/rose gold hissi veren geçişler
                    Color(
                      0xFFFFEBF2,
                    ), // Başlangıç: Yumuşak ama belirgin açık pembe
                    Color(
                      0xFFFFC4D6,
                    ), // Bitiş: Daha koyu, tatlı bir gül pembesi
                  ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        // --- KENARLIK ---
        border: Border.all(
          color:
              _isDarkTheme
                  ? _cardBorderColor
                  : Color(
                    0xFFFFB2C9,
                  ), // Açık mod: Arka plandan bir tık koyu, belirgin pembe kenarlık
          width: 1.5, // Kenarlık bir tık kalınlaştırıldı
        ),
        // --- GÖLGE ---
        boxShadow:
            _isDarkTheme
                ? []
                : [
                  BoxShadow(
                    // Gölgeye hafif pembe tonu verildi, daha canlı durması için
                    color: Colors.pink.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BAŞLIK KISMI ---
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          // Açık modda ikon rengi daha koyu ve belirgin bir fuşya/bordo
                          color:
                              _isDarkTheme
                                  ? AppColors.pinkSecondary
                                  : Color(0xFFC2185B),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ürün Önerisi',
                          style: TextStyle(
                            color: _primaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cildinize uygun ürünler önerelim',
                      style: TextStyle(
                        color:
                            _isDarkTheme
                                ? _secondaryTextColor
                                : Colors.grey[800],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // --- TOGGLE SWITCH ---
              GestureDetector(
                onTap: () {
                  setState(() {
                    _includeProducts = !_includeProducts;
                    if (!_includeProducts) {
                      _productCount = 3;
                    }
                  });
                },
                child: Container(
                  width: 56,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color:
                        _includeProducts
                            ? AppColors.pinkSecondary
                            : (_isDarkTheme
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black87.withOpacity(
                                  0.4,
                                )), // Açık mod pasif: Düz gri yerine pembemsi gri
                  ),
                  child: AnimatedAlign(
                    duration: Duration(milliseconds: 200),
                    alignment:
                        _includeProducts
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Container(
                      width: 26,
                      height: 26,
                      margin: EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_includeProducts) ...[
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.info_outline, color: _secondaryTextColor, size: 16),
                SizedBox(width: 6),
                Text(
                  'Kaç ürün görmek istersiniz?',
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // --- 3 ÜRÜN SEÇENEĞİ ---
            GestureDetector(
              onTap: () {
                setState(() {
                  _productCount = 3;
                });
              },
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      _productCount == 3
                          ? (_isDarkTheme
                              ? Colors.pink.withOpacity(0.15)
                              : Color(
                                0xFFFFE4E9,
                              )) // Açık mod seçili: Belirgin tatlı pembe vurgu
                          : (_isDarkTheme
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white), // Açık mod seçili değil: Beyaz
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _productCount == 3
                            ? Colors.pink
                            : (_isDarkTheme
                                ? _cardBorderColor
                                : Colors.grey.shade300),
                    width: _productCount == 3 ? 2 : 1,
                  ),
                  boxShadow:
                      (!_isDarkTheme && _productCount != 3)
                          ? [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ]
                          : [],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              _productCount == 3
                                  ? Colors.pink.withOpacity(0.4)
                                  : (_isDarkTheme
                                      ? Colors.white.withOpacity(0.4)
                                      : Colors.grey.shade400),
                          width: 2,
                        ),
                        color:
                            _productCount == 3
                                ? Colors.pink
                                : Colors.transparent,
                      ),
                      child:
                          _productCount == 3
                              ? Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                              : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3 Ürün',
                            style: TextStyle(
                              color: _primaryTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Ücretsiz',
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(
                          _isDarkTheme ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'ÜCRETSİZ',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // --- 10 ÜRÜN SEÇENEĞİ (PREMIUM) ---
            GestureDetector(
              onTap: () {
                if (userTier == 'premium') {
                  setState(() {
                    _productCount = 10;
                  });
                } else {
                  _showPremiumDialog();
                }
              },
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          _productCount == 10 && userTier == 'premium'
                              ? (_isDarkTheme
                                  ? Colors.amber.withOpacity(0.3)
                                  : Color(
                                    0xFFFFF0D4,
                                  )) // Açık mod Premium: Daha zengin amber/krem
                              : (_isDarkTheme
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _productCount == 10 && userTier == 'premium'
                                ? Colors.amber
                                : (_isDarkTheme
                                    ? _cardBorderColor
                                    : Colors.grey.shade300),
                        width:
                            _productCount == 10 && userTier == 'premium'
                                ? 2
                                : 1,
                      ),
                      boxShadow:
                          (!_isDarkTheme &&
                                  !(_productCount == 10 &&
                                      userTier == 'premium'))
                              ? [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ]
                              : [],
                    ),
                    child: Row(
                      children: [
                        // ... (Bu kısımdaki içerik aynı kaldı) ...
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  _productCount == 10 && userTier == 'premium'
                                      ? Colors.amber
                                      : (_isDarkTheme
                                          ? Colors.white.withOpacity(0.4)
                                          : Colors.grey.shade400),
                              width: 2,
                            ),
                            color:
                                _productCount == 10 && userTier == 'premium'
                                    ? Colors.amber
                                    : Colors.transparent,
                          ),
                          child:
                              _productCount == 10 && userTier == 'premium'
                                  ? Center(
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                  : null,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '10 Ürün',
                                    style: TextStyle(
                                      color: _primaryTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.star_rounded,
                                    color:
                                        _isDarkTheme
                                            ? Colors.yellowAccent
                                            : Colors.amber,
                                    size: 18,
                                  ),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: _secondaryTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (userTier == 'free')
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.pinkAccent, Colors.pink],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Premium\'a Geç',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(
                                _isDarkTheme ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber, width: 1),
                            ),
                            child: Text(
                              'PREMIUM',
                              style: TextStyle(
                                color:
                                    _isDarkTheme
                                        ? Colors.amber
                                        : Colors.amber[800],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Kilitli (Free kullanıcı için kaplama)
                  if (userTier == 'free')
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              _isDarkTheme
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        children: [
          // Ana resim
          GestureDetector(
            onTap: () {
              if (_selectedImageFile == null && _imageUrlForDisplay == null)
                return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FullScreenImageViewer(
                        imageUrl: _imageUrlForDisplay,
                        imagePath: _selectedImageFile?.path,
                        isLocalFile: _selectedImageFile != null,
                      ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: _selectedImageFile?.path ?? _imageUrlForDisplay ?? '',
                child:
                    _selectedImageFile != null
                        ? Image.file(
                          _selectedImageFile!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                        : (_imageUrlForDisplay != null
                            ? Image.network(
                              _imageUrlForDisplay!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                            : const SizedBox.shrink()),
              ),
            ),
          ),

          // Sağ üst badge - Analiz tamamlandı
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.9),
                    Colors.greenAccent.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Fotoğraf Yüklendi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sol alt - Büyütme butonu
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              decoration: BoxDecoration(
                color:
                    _isDarkTheme
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _isDarkTheme
                          ? Colors.white.withOpacity(0.3)
                          : Colors.black.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isDarkTheme ? 0.3 : 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => FullScreenImageViewer(
                              imageUrl: _imageUrlForDisplay,
                              imagePath: _selectedImageFile?.path,
                              isLocalFile: _selectedImageFile != null,
                            ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.zoom_in_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Büyült',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildAnalyzeButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(_isDarkTheme ? 0.3 : 0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                _isDarkTheme
                    ? [
                      Colors.pink.withOpacity(0.3),
                      Colors.pinkAccent.withOpacity(0.2),
                    ]
                    : [
                      Colors.pink.withOpacity(0.25),
                      Colors.pinkAccent.withOpacity(0.2),
                    ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                _isDarkTheme
                    ? _cardBorderColor
                    : Colors.black87.withOpacity(0.25),
            width: _isDarkTheme ? 1.5 : 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _analyzePickedImage,
            borderRadius: BorderRadius.circular(20),
            splashColor:
                _isDarkTheme
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
            highlightColor:
                _isDarkTheme
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          _isDarkTheme
                              ? Colors.white.withOpacity(0.15)
                              : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_fix_high_sharp,
                      color: _primaryTextColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Analiz Et',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                      letterSpacing: 0.5,
                      shadows:
                          _isDarkTheme
                              ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ]
                              : [],
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

  Widget _buildBody() {
    if (_isLoading) {
      return Column(children: [SizedBox(height: 250), _buildLoadingState()]);
    } else if (_statusMessage != null) {
      return Column(
        children: [
          SizedBox(height: 50),
          _buildErrorState(),
          SizedBox(height: 20),
          _buildAnalyzeAgainButton(),
          SizedBox(height: 250),
        ],
      );
    } else if (_analysisResult != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResultsSection(),
          _buildAnalyzeAgainButton(),
          _buildSavedAnalyze(),
        ],
      );
    } else {
      return Column(children: [SizedBox(height: 20), _buildTipsCarousel()]);
    }
  }

  Widget _buildButtonCamera() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  _isDarkTheme
                      ? [
                        Color.fromARGB(255, 94, 9, 54).withOpacity(0.3),
                        Color.fromARGB(255, 94, 9, 54).withOpacity(0.2),
                      ]
                      : [
                        Color.fromARGB(255, 94, 9, 54).withOpacity(0.94),
                        Color.fromARGB(255, 120, 15, 70).withOpacity(0.84),
                      ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  _isDarkTheme
                      ? _cardBorderColor
                      : Colors.white.withOpacity(0.3),
              width: _isDarkTheme ? 1.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(
                  255,
                  94,
                  9,
                  54,
                ).withOpacity(_isDarkTheme ? 0.3 : 0.25),
                blurRadius: _isDarkTheme ? 20 : 20,
                spreadRadius: 0,
                offset: Offset(0, _isDarkTheme ? 8 : 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _pickImageFromCamera,
              borderRadius: BorderRadius.circular(20),
              splashColor:
                  _isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.3),
              highlightColor:
                  _isDarkTheme
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            _isDarkTheme
                                ? Colors.white.withOpacity(0.15)
                                : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Fotoğraf Çek',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonGalery() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  _isDarkTheme
                      ? [
                        Colors.pink.withOpacity(0.3),
                        Colors.pinkAccent.withOpacity(0.2),
                      ]
                      : [
                        Colors.pink.withOpacity(0.8),
                        Colors.pinkAccent.withOpacity(0.7),
                      ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  _isDarkTheme
                      ? _cardBorderColor
                      : Colors.black87.withOpacity(0.35),
              width: _isDarkTheme ? 1.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(_isDarkTheme ? 0.3 : 0.5),
                blurRadius: _isDarkTheme ? 20 : 20,
                spreadRadius: 0,
                offset: Offset(0, _isDarkTheme ? 8 : 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _pickImageFromGallery,
              borderRadius: BorderRadius.circular(20),
              splashColor:
                  _isDarkTheme
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.3),
              highlightColor:
                  _isDarkTheme
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            _isDarkTheme
                                ? Colors.white.withOpacity(0.15)
                                : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.photo_library_sharp,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Galeriden Seç',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCarousel() {
    final tips = [
      {
        'icon': Icons.wb_sunny_outlined,
        'title': 'Işık',
        'text': 'Fotoğrafınızı aydınlık ve doğal bir ışıkta çekin.',
      },
      {
        'icon': Icons.clean_hands_outlined,
        'title': 'Makyaj',
        'text': 'En doğru sonuç için makyajsız bir cilde sahip olun.',
      },
      {
        'icon': Icons.center_focus_weak,
        'title': 'Mesafe',
        'text': 'Yüzünüzün tamamının kameraya net sığdığından emin olun.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: _primaryTextColor),
            Text(
              'Doğru Analiz İçin İpuçları',
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 155,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Container(
                width: 220,
                margin: EdgeInsets.only(
                  right: index == tips.length - 1 ? 0 : 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors:
                        _isDarkTheme
                            ? [
                              Colors.white.withOpacity(0.1),
                              Colors.white.withOpacity(0.05),
                            ]
                            : [
                              Colors.white.withOpacity(0.4),
                              Colors.white.withOpacity(0.3),
                            ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: _cardBorderColor, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        tip['icon'] as IconData,
                        color: AppColors.pinkSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tip['title'] as String,
                        style: TextStyle(
                          color: _primaryTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tip['text'] as String,
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.pinkSecondary),
          const SizedBox(height: 20),
          Text(
            _selectedImageFile != null
                ? 'Resim yükleniyor ve analiz ediliyor...'
                : 'Analiz ediliyor...',
            style: TextStyle(color: _secondaryTextColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _isDarkTheme
                  ? Colors.red.withOpacity(0.1)
                  : Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              _statusMessage ?? 'Bilinmeyen bir hata oluştu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _primaryTextColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Resim gösterimi - Modern ve şık tasarım
          if (_imageUrlForDisplay != null || _selectedImageFile != null)
            Container(
              margin: const EdgeInsets.only(bottom: 24, left: 0, right: 0),
              child: Stack(
                children: [
                  // Glow effect altında
                  Positioned.fill(
                    child: Container(
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 0,
                            offset: Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.2),
                            blurRadius: 40,
                            spreadRadius: 0,
                            offset: Offset(0, 15),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Ana container
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors:
                            _isDarkTheme
                                ? [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ]
                                : [
                                  Colors.white.withOpacity(0.9),
                                  Colors.white.withOpacity(0.7),
                                ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.pink.withOpacity(
                          _isDarkTheme ? 0.3 : 0.2,
                        ),
                        width: 2,
                      ),
                    ),
                    padding: EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          // Resim
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => FullScreenImageViewer(
                                        imageUrl: _imageUrlForDisplay,
                                        imagePath: _selectedImageFile?.path,
                                        isLocalFile: _selectedImageFile != null,
                                      ),
                                ),
                              );
                            },
                            child: Hero(
                              tag:
                                  _selectedImageFile?.path ??
                                  _imageUrlForDisplay ??
                                  '',
                              child:
                                  _selectedImageFile != null
                                      ? Image.file(
                                        _selectedImageFile!,
                                        height: 240,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                      : Image.network(
                                        _imageUrlForDisplay!,
                                        height: 240,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  height: 240,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black26,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: Colors.white54,
                                                      size: 50,
                                                    ),
                                                  ),
                                                ),
                                      ),
                            ),
                          ),

                          // Alt gradient overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(18),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),

                          // Sağ üst badge - Analiz tamamlandı
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.9),
                                    Colors.greenAccent.withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Analiz Tamamlandı',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Sol alt - Büyütme butonu
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),

                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      _isDarkTheme ? 0.3 : 0.1,
                                    ),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => FullScreenImageViewer(
                                              imageUrl: _imageUrlForDisplay,
                                              imagePath:
                                                  _selectedImageFile?.path,
                                              isLocalFile:
                                                  _selectedImageFile != null,
                                            ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_in_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Büyüt',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
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
                    ),
                  ),

                  // Üst sağ köşe accent glow
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.pink.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Analiz kartları
          if (_analysisResult != null) _buildAnalysisResults(_analysisResult!),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults(SkinAnalysisResult result) {
    return Column(
      children: [
        // Giriş mesajı - AÇIK KALACAK
        if (result.giris != null)
          _buildAnalysisCard(
            title: 'Analiziniz Tamamlandı',
            content: result.giris!,
            icon: Icons.waving_hand,
          ),

        // Bütüncül Cilt Analizi - AÇIK KALACAK
        if (result.butunculCiltAnalizi != null)
          _buildButunculCiltAnaliziCard(result.butunculCiltAnalizi!),

        // Kişiselleştirilmiş Bakım Planı (Sabah ve Akşam Rutinleri içerir)
        if (result.kisisellestirilmisBakimPlani != null)
          _buildBakimPlaniCard(result.kisisellestirilmisBakimPlani!),

        // Ürün Önerileri - GENİŞLETİLEBİLİR
        if (result.outputUrun != null && result.outputUrun!.isNotEmpty)
          _buildExpandableRoutineCard(
            title: 'Ürün Önerileri',
            icon: Icons.shopping_bag_outlined,
            gradient: [
              Colors.pink.withOpacity(0.3),
              Colors.pinkAccent.withOpacity(0.2),
            ],
            isExpanded: _isUrunOnerileriExpanded,
            onTap: () {
              setState(() {
                _isUrunOnerileriExpanded = !_isUrunOnerileriExpanded;
              });
            },
            content: _formatUrunOnerileri(result.outputUrun!),
          ),
        SizedBox(height: 12),
        // Makyaj ve Renk Önerileri - GENİŞLETİLEBİLİR
        if (result.makyajRenkOnerileri != null)
          _buildExpandableRoutineCard(
            title:
                result.makyajRenkOnerileri!.baslik ??
                'Makyaj ve Renk Önerileri',
            icon: Icons.brush_outlined,
            gradient: [
              Colors.pink.withOpacity(0.3),
              Colors.pinkAccent.withOpacity(0.2),
            ],
            isExpanded: _isMakyajOnerileriExpanded,
            onTap: () {
              setState(() {
                _isMakyajOnerileriExpanded = !_isMakyajOnerileriExpanded;
              });
            },
            content: _buildMakyajOnerileriContent(result.makyajRenkOnerileri!),
          ),
        SizedBox(height: 12),

        // Önemli Notlar ve İpuçları - GENİŞLETİLEBİLİR
        if (result.onemliNotlarIpuclari != null)
          _buildExpandableRoutineCard(
            title:
                result.onemliNotlarIpuclari!.baslik ??
                'Önemli Notlar ve İpuçları',
            icon: Icons.lightbulb_outline,
            gradient: [
              Colors.pink.withOpacity(0.3),
              Colors.pinkAccent.withOpacity(0.2),
            ],
            isExpanded: _isNotlarIpuclariExpanded,
            onTap: () {
              setState(() {
                _isNotlarIpuclariExpanded = !_isNotlarIpuclariExpanded;
              });
            },
            content: _buildNotlarIpuclariContent(result.onemliNotlarIpuclari!),
          ),
        SizedBox(height: 12),

        // Kapanış Notu - GENİŞLETİLEBİLİR
        if (result.kapanisNotu != null)
          _buildExpandableRoutineCard(
            title: 'Kapanış',
            icon: Icons.favorite,
            gradient: [
              Colors.pink.withOpacity(0.3),
              Colors.pinkAccent.withOpacity(0.2),
            ],
            isExpanded: _isKapanisNotuExpanded,
            onTap: () {
              setState(() {
                _isKapanisNotuExpanded = !_isKapanisNotuExpanded;
              });
            },
            content: result.kapanisNotu!,
          ),
      ],
    );
  }

  Widget _buildButunculCiltAnaliziCard(ButunculCiltAnalizi analiz) {
    return _buildAnalysisCard(
      title: analiz.baslik ?? 'Bütüncül Cilt Analizi',
      content: _buildButunculCiltAnaliziContent(analiz),
      icon: Icons.face_outlined,
    );
  }

  String _buildButunculCiltAnaliziContent(ButunculCiltAnalizi analiz) {
    final buffer = StringBuffer();

    if (analiz.gorselDegerlendirme != null) {
      buffer.writeln('📸 Görsel Değerlendirme:');
      if (analiz.gorselDegerlendirme!.ciltTonu != null) {
        buffer.writeln('• Cilt Tonu: ${analiz.gorselDegerlendirme!.ciltTonu}');
      }
      if (analiz.gorselDegerlendirme!.ciltAltTonu != null) {
        buffer.writeln(
          '• Cilt Alt Tonu: ${analiz.gorselDegerlendirme!.ciltAltTonu}',
        );
      }
      if (analiz.gorselDegerlendirme!.tespitEdilenDurumlar != null) {
        buffer.writeln(
          '• Tespit Edilen Durumlar: ${analiz.gorselDegerlendirme!.tespitEdilenDurumlar}',
        );
      }
      buffer.writeln('');
    }

    if (analiz.yasamTarziEtkileri != null) {
      buffer.writeln('💤 Yaşam Tarzı Etkileri:');
      if (analiz.yasamTarziEtkileri!.uykuEtkisi != null) {
        buffer.writeln('• Uyku: ${analiz.yasamTarziEtkileri!.uykuEtkisi}');
      }
      if (analiz.yasamTarziEtkileri!.sigaraVeDigerEtkiler != null) {
        buffer.writeln(
          '• Sigara: ${analiz.yasamTarziEtkileri!.sigaraVeDigerEtkiler}',
        );
      }
      buffer.writeln('');
    }

    if (analiz.mevcutRutinDegerlendirmesi != null) {
      buffer.writeln('🔍 Mevcut Rutin Değerlendirmesi:');
      if (analiz.mevcutRutinDegerlendirmesi!.ciltTipiVeTemizlikYorumu != null) {
        buffer.writeln(
          '• ${analiz.mevcutRutinDegerlendirmesi!.ciltTipiVeTemizlikYorumu}',
        );
      }
      if (analiz.mevcutRutinDegerlendirmesi!.mevcutAdimlarVeEksikler != null) {
        buffer.writeln(
          '• ${analiz.mevcutRutinDegerlendirmesi!.mevcutAdimlarVeEksikler}',
        );
      }
    }

    return buffer.toString();
  }

  Widget _buildBakimPlaniCard(KisisellestirilmisBakimPlani plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Ana başlık kartı
          _buildAnalysisCard(
            title: plan.baslik ?? 'Kişiselleştirilmiş Bakım Planı',
            content:
                plan.oncelikliHedef != null
                    ? '🎯 Öncelikli Hedef:\n${plan.oncelikliHedef}'
                    : '',
            icon: Icons.spa_outlined,
          ),

          const SizedBox(height: 12),

          // Sabah Rutini Kartı (Genişletilebilir)
          if (plan.sabahRutini != null)
            _buildExpandableRoutineCard(
              title: plan.sabahRutini!.baslik ?? 'Sabah Rutini',
              icon: Icons.wb_sunny_outlined,
              gradient: [
                Colors.pink.withOpacity(0.3),
                Colors.pinkAccent.withOpacity(0.2),
              ],
              isExpanded: _isSabahRutiniExpanded,
              onTap: () {
                setState(() {
                  _isSabahRutiniExpanded = !_isSabahRutiniExpanded;
                });
              },
              content: _buildSabahRutiniContent(plan.sabahRutini!),
            ),

          const SizedBox(height: 12),

          // Akşam Rutini Kartı (Genişletilebilir)
          if (plan.aksamRutini != null)
            _buildExpandableRoutineCard(
              title: plan.aksamRutini!.baslik ?? 'Akşam Rutini',
              icon: Icons.nightlight_round,
              gradient: [
                Colors.pink.withOpacity(0.3),
                Colors.pinkAccent.withOpacity(0.2),
              ],
              isExpanded: _isAksamRutiniExpanded,
              onTap: () {
                setState(() {
                  _isAksamRutiniExpanded = !_isAksamRutiniExpanded;
                });
              },
              content: _buildAksamRutiniContent(plan.aksamRutini!),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandableRoutineCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required bool isExpanded,
    required VoidCallback onTap,
    required String content,
    Color? customContentBg,
  }) {
    // Tema değişkenleri
    final theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;
    final Color accent2 = theme.colorScheme.secondary;

    final Color glassCardBg = Colors.pink.shade400.withOpacity(0.25);
    final Color glassContentBoxBg = Colors.pink.shade50.withOpacity(0.4);
    final Color glassAccent = Colors.pink.shade600.withOpacity(0.6);
    final Color glassBorder = Colors.pink.shade700.withOpacity(0.2);

    final Color glowColor =
        _isDarkTheme
            ? accent.withOpacity(0.15)
            : Colors.pink.shade400.withOpacity(0.2);

    final Color contentBackground =
        customContentBg ??
        (_isDarkTheme ? Colors.black.withOpacity(0.2) : glassContentBoxBg);

    final Color contentTextColor =
        _isDarkTheme ? Colors.white.withOpacity(0.9) : Colors.black87;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          // --- GLOW EFEKTİ ---
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 18,
                    spreadRadius: -3,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),

          // --- KART GÖVDESİ ---
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // 1. Blur
                if (!_isDarkTheme)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                // 2. Dekorasyon ve İçerik
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: _isDarkTheme ? null : glassCardBg,
                    gradient:
                        _isDarkTheme
                            ? LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.12),
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                    border: Border.all(
                      color:
                          _isDarkTheme ? accent.withOpacity(0.3) : glassBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Yansıma Efektleri
                      if (_isDarkTheme)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  accent.withOpacity(0.15),
                                  Colors.transparent,
                                ],
                                radius: 1.0,
                              ),
                            ),
                          ),
                        ),
                      if (!_isDarkTheme)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5],
                              ),
                            ),
                          ),
                        ),

                      // --- İÇERİK COLUMN ---
                      // Column'u Stack içinde tutuyoruz ama doğrudan child olarak
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- BAŞLIK ---
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onTap,
                              borderRadius: BorderRadius.vertical(
                                top: const Radius.circular(24),
                                bottom:
                                    isExpanded
                                        ? Radius.zero
                                        : const Radius.circular(24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Row(
                                  children: [
                                    // İkon
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            _isDarkTheme ? null : glassAccent,
                                        gradient:
                                            _isDarkTheme
                                                ? LinearGradient(
                                                  colors: [accent, accent2],
                                                )
                                                : null,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        icon,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Başlık Metni
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            height: 3,
                                            width: 40,
                                            decoration: BoxDecoration(
                                              color:
                                                  _isDarkTheme
                                                      ? null
                                                      : glassAccent,
                                              gradient:
                                                  _isDarkTheme
                                                      ? LinearGradient(
                                                        colors: [
                                                          accent,
                                                          accent2,
                                                        ],
                                                      )
                                                      : null,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Ok İkonu
                                    AnimatedRotation(
                                      turns: isExpanded ? 0.5 : 0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // --- AÇILAN METİN ---
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child:
                                isExpanded
                                    ? Container(
                                      decoration: BoxDecoration(
                                        color: contentBackground,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              bottom: Radius.circular(24),
                                            ),
                                        border: Border(
                                          top: BorderSide(
                                            color:
                                                _isDarkTheme
                                                    ? theme.dividerColor
                                                        .withOpacity(0.2)
                                                    : Colors.white.withOpacity(
                                                      0.4,
                                                    ),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                        content,
                                        style: TextStyle(
                                          color: contentTextColor,
                                          fontSize: 15,
                                          height: 1.6,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSabahRutiniContent(dynamic sabahRutini) {
    final buffer = StringBuffer();

    if (sabahRutini.adim1Temizleme != null) {
      buffer.writeln('1️⃣ Temizleme\n${sabahRutini.adim1Temizleme}\n');
    }
    if (sabahRutini.adim2Serum != null) {
      buffer.writeln('2️⃣ Serum\n${sabahRutini.adim2Serum}\n');
    }
    if (sabahRutini.adim3Nemlendirme != null) {
      buffer.writeln('3️⃣ Nemlendirme\n${sabahRutini.adim3Nemlendirme}\n');
    }
    if (sabahRutini.adim4Koruma != null) {
      buffer.writeln('4️⃣ Koruma\n${sabahRutini.adim4Koruma}');
    }

    return buffer.toString().trim();
  }

  // Akşam rutini içeriği:
  String _buildAksamRutiniContent(dynamic aksamRutini) {
    final buffer = StringBuffer();

    if (aksamRutini.adim1CiftAsamaliTemizlemeYag != null) {
      buffer.writeln(
        '1️⃣ Çift Aşamalı Temizleme (Yağ)\n${aksamRutini.adim1CiftAsamaliTemizlemeYag}\n',
      );
    }
    if (aksamRutini.adim1CiftAsamaliTemizlemeSu != null) {
      buffer.writeln(
        '1️⃣ Çift Aşamalı Temizleme (Su)\n${aksamRutini.adim1CiftAsamaliTemizlemeSu}\n',
      );
    }
    if (aksamRutini.adim2Tonik != null) {
      buffer.writeln('2️⃣ Tonik\n${aksamRutini.adim2Tonik}\n');
    }
    if (aksamRutini.adim3TedaviSerumu != null) {
      buffer.writeln('3️⃣ Tedavi Serumu\n${aksamRutini.adim3TedaviSerumu}\n');
    }
    if (aksamRutini.adim4Nemlendirme != null) {
      buffer.writeln('4️⃣ Nemlendirme\n${aksamRutini.adim4Nemlendirme}\n');
    }
    if (aksamRutini.ekAdimGozKremi != null) {
      buffer.writeln('✨ Ek Adım - Göz Kremi\n${aksamRutini.ekAdimGozKremi}');
    }

    return buffer.toString().trim();
  }

  // Akşam rutini içeriği

  String _buildMakyajOnerileriContent(MakyajRenkOnerileri oneriler) {
    final buffer = StringBuffer();

    if (oneriler.altTonPaleti != null) {
      buffer.writeln('🎨 Alt Ton Paleti:');
      buffer.writeln('${oneriler.altTonPaleti}');
      buffer.writeln('');
    }

    if (oneriler.onerilerErkekIcin != null) {
      buffer.writeln('👨 Erkekler İçin Öneriler:');
      if (oneriler.onerilerErkekIcin!.tenUrunu != null) {
        buffer.writeln('• Ten Ürünü: ${oneriler.onerilerErkekIcin!.tenUrunu}');
      }
      if (oneriler.onerilerErkekIcin!.kapatici != null) {
        buffer.writeln('• Kapatıcı: ${oneriler.onerilerErkekIcin!.kapatici}');
      }
    }

    return buffer.toString().trim();
  }

  String _formatUrunOnerileri(String urunOnerileri) {
    // Markdown formatını daha okunabilir hale getir
    String formatted = urunOnerileri;

    // ### başlıkları için
    formatted = formatted.replaceAllMapped(
      RegExp(r'###\s+(\d+\.\s+[^\n]+)'),
      (match) => '\n📦 ${match.group(1)}\n',
    );

    // ** kalın yazıları
    formatted = formatted.replaceAllMapped(
      RegExp(r'\*\*([^\*]+)\*\*'),
      (match) => match.group(1) ?? '',
    );

    // * liste işaretlerini
    formatted = formatted.replaceAll(
      RegExp(r'^\s*\*\s+', multiLine: true),
      '• ',
    );

    // Fazla boşlukları temizle
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return formatted.trim();
  }

  String _buildNotlarIpuclariContent(OnemliNotlarIpuclari notlar) {
    final buffer = StringBuffer();

    if (notlar.alerjilerNotu != null) {
      buffer.writeln('⚠️ Alerjiler:');
      buffer.writeln('${notlar.alerjilerNotu}');
      buffer.writeln('');
    }

    if (notlar.icerikUyarisi != null) {
      buffer.writeln('💡 İçerik Uyarısı:');
      buffer.writeln('${notlar.icerikUyarisi}');
      buffer.writeln('');
    }

    if (notlar.yasamTarziIpucu != null) {
      buffer.writeln('🌿 Yaşam Tarzı İpucu:');
      buffer.writeln('${notlar.yasamTarziIpucu}');
    }

    return buffer.toString().trim();
  }

  Widget _buildAnalysisCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;
    final Color accent2 = theme.colorScheme.secondary;

    // --- RENK PALETİ ---
    final Color glassCardBg = Colors.pink.shade400.withOpacity(0.25);
    final Color glassContentBoxBg = Colors.pink.shade50.withOpacity(0.4);
    final Color glassAccent = Colors.pink.shade600.withOpacity(0.6);
    final Color glassBorder = Colors.pink.shade700.withOpacity(0.2);

    // --- GLOW RENGİ ---
    final Color glowColor =
        _isDarkTheme
            ? accent.withOpacity(0.15)
            : Colors.pink.shade400.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // --- HAFİF GÖLGE EFEKTİ ---
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 18,
                    spreadRadius: -3,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: glowColor.withOpacity(_isDarkTheme ? 0.05 : 0.1),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),

          // --- ANA KART ---
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // 1. Blur (Sadece Açık Mod)
                if (!_isDarkTheme)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                // 2. Kart Yapısı ve Zemin Rengi
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: _isDarkTheme ? null : glassCardBg,
                    gradient:
                        _isDarkTheme
                            ? LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.12),
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                    border: Border.all(
                      color:
                          _isDarkTheme ? accent.withOpacity(0.3) : glassBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // --- YANSIMA EFEKTİ (DÜZENLENDİ) ---

                      // KOYU MOD İÇİN ESKİ YANSIMA (Sağ üst köşe)
                      if (_isDarkTheme)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  accent.withOpacity(0.15),
                                  Colors.transparent,
                                ],
                                radius: 1.0,
                              ),
                            ),
                          ),
                        ),

                      // AÇIK MOD İÇİN YENİ PÜRÜZSÜZ GEÇİŞ (Tüm kart yüzeyi)
                      if (!_isDarkTheme)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft, // Sol üstten
                                end: Alignment.bottomRight, // Sağ alta doğru
                                colors: [
                                  // Çok hafif beyazımsı/pembe ışık
                                  Colors.white.withOpacity(0.3),
                                  // Ortaya gelmeden kaybolan geçiş
                                  Colors.transparent,
                                ],
                                // Geçişin nerede başlayıp biteceği (daha yumuşak olması için)
                                stops: const [0.0, 0.5],
                              ),
                            ),
                          ),
                        ),

                      // --- İÇERİK ---
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // İkon Kutusu
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _isDarkTheme ? null : glassAccent,
                                    gradient:
                                        _isDarkTheme
                                            ? LinearGradient(
                                              colors: [accent, accent2],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                            : null,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            _isDarkTheme
                                                ? accent.withOpacity(0.2)
                                                : Colors.pink.shade700
                                                    .withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    icon,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // BAŞLIK: Hep Beyaz
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(
                                                0.4,
                                              ),
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Alt Çizgi
                                      Container(
                                        height: 3,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color:
                                              _isDarkTheme ? null : glassAccent,
                                          gradient:
                                              _isDarkTheme
                                                  ? LinearGradient(
                                                    colors: [accent, accent2],
                                                  )
                                                  : null,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Metin Kutusu
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    _isDarkTheme
                                        ? Colors.black.withOpacity(0.2)
                                        : glassContentBoxBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      _isDarkTheme
                                          ? theme.dividerColor.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                content,
                                style: TextStyle(
                                  color:
                                      _isDarkTheme
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.black87,
                                  fontSize: 15,
                                  height: 1.6,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterText() {
    return Column(
      children: [
        Image.asset("assets/images/logo1.png", width: 170),
        const SizedBox(height: 20),
        Text(
          'Cilt Analizine Başla',
          style: TextStyle(
            color: _primaryTextColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Cildinin özelliklerini keşfetmek için\nfotoğraf çek veya galeriden seç',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_hasDailyAnalysis && userTier == 'free') ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color:
                  _isDarkTheme
                      ? Colors.red.withOpacity(0.1)
                      : Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _isDarkTheme
                        ? Colors.redAccent.withOpacity(0.3)
                        : Colors.redAccent.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Günlük analiz hakkınız doldu.',
                    style: TextStyle(
                      color:
                          _isDarkTheme
                              ? Colors.redAccent.withOpacity(0.9)
                              : Colors.red[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showPremiumDialog,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Premium\'a Geç',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          if (_hasDailyAnalysis) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Günlük analizinizi tamamladınız.',
                          style: TextStyle(
                            color:
                                _isDarkTheme
                                    ? Colors.greenAccent
                                    : Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'İsterseniz anlık analiz yapabilirsiniz',
                          style: TextStyle(
                            color:
                                _isDarkTheme
                                    ? Colors.greenAccent.withOpacity(0.8)
                                    : Colors.green[700]!,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!_hasDailyAnalysis)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Color(0xFF8B5CF6).withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8B5CF6).withOpacity(0.15),
                    blurRadius: 32,
                    spreadRadius: 4,
                    offset: Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder:
                          (context) => Container(
                            decoration: BoxDecoration(
                              color:
                                  _isDarkTheme
                                      ? Color(0xFF1E1E1E).withOpacity(0.45)
                                      : Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: Offset(0, -5),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    12,
                                    24,
                                    40,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color:
                                              _isDarkTheme
                                                  ? Colors.white.withOpacity(
                                                    0.2,
                                                  )
                                                  : Colors.grey.withOpacity(
                                                    0.3,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      Text(
                                        'Fotoğraf Kaynağı',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _isDarkTheme
                                                  ? Colors.white
                                                  : Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Analiz için bir fotoğraf yükleyin',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color:
                                              _isDarkTheme
                                                  ? Colors.white54
                                                  : Colors.white70,
                                        ),
                                      ),
                                      SizedBox(height: 32),
                                      Row(
                                        children: [
                                          _buildImageSourceOption(
                                            icon: Icons.camera_alt_rounded,
                                            label: 'Kamera',
                                            onTap: () {
                                              Navigator.pop(context);
                                              _pickImageFromCamera();
                                            },
                                            isDark: _isDarkTheme,
                                          ),
                                          _buildImageSourceOption(
                                            icon: Icons.photo_library_rounded,
                                            label: 'Galeri',
                                            onTap: () {
                                              Navigator.pop(context);
                                              _pickImageFromGallery();
                                            },
                                            isDark: _isDarkTheme,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.analytics_outlined, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Günlük Analizini Yap',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 120,
          margin: EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color:
                isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.pink, Colors.pinkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeAgainButton() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 20),
      child: SizedBox(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Stack(
              children: [
                // Glow effect - çift katmanlı
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(
                            _isDarkTheme ? 0.4 : 0.5,
                          ),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: Offset(0, 8),
                        ),
                        // İkinci katman parlama
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(
                            _isDarkTheme ? 0.2 : 0.3,
                          ),
                          blurRadius: 28,
                          spreadRadius: -2,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                  ),
                ),
                // Main button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          _isDarkTheme
                              ? [
                                Colors.pink.withOpacity(0.1),
                                Colors.pinkAccent.withOpacity(0.1),
                              ]
                              : [
                                Colors.pink.withOpacity(0.8),
                                Colors.pinkAccent.withOpacity(0.7),
                              ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          _isDarkTheme
                              ? _cardBorderColor
                              : Colors.pink.withOpacity(0.35),
                      width: _isDarkTheme ? 1.5 : 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _resetState,
                      borderRadius: BorderRadius.circular(20),
                      splashColor:
                          _isDarkTheme
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white.withOpacity(0.3),
                      highlightColor:
                          _isDarkTheme
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 24,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors:
                                      _isDarkTheme
                                          ? [
                                            Colors.white.withOpacity(0.15),
                                            Colors.white.withOpacity(0.1),
                                          ]
                                          : [
                                            Colors.white.withOpacity(0.3),
                                            Colors.white.withOpacity(0.2),
                                          ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(
                                      _isDarkTheme ? 0.3 : 0.4,
                                    ),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Tekrar Analiz Yap',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    offset: Offset(0, 2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedAnalyze() {
    final bool isDisabled = _analysisResult == null || _isSaving;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              // Glow effect
              if (!isDisabled)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(
                            _isDarkTheme ? 0.4 : 0.5,
                          ),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: Offset(0, 8),
                        ),
                        // İkinci katman parlama
                        BoxShadow(
                          color: Colors.deepPurpleAccent.withOpacity(
                            _isDarkTheme ? 0.2 : 0.3,
                          ),
                          blurRadius: 28,
                          spreadRadius: -2,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                  ),
                ),

              // Main button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        isDisabled
                            ? (_isDarkTheme
                                ? [Color(0xFF1A1A1A), Color(0xFF0D0D0D)]
                                : [Colors.grey[300]!, Colors.grey[200]!])
                            : (_isDarkTheme
                                ? [
                                  Colors.deepPurple.withOpacity(0.05),
                                  Colors.deepPurpleAccent.withOpacity(0.05),
                                ]
                                : [
                                  Colors.deepPurple.withOpacity(0.8),
                                  Colors.deepPurpleAccent.withOpacity(0.7),
                                ]),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isDisabled
                            ? _cardBorderColor
                            : (_isDarkTheme
                                ? _cardBorderColor
                                : Colors.deepPurple.withOpacity(0.35)),
                    width: _isDarkTheme ? 1.5 : 2,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isDisabled ? null : _saveCurrentAnalysis,
                    borderRadius: BorderRadius.circular(20),
                    splashColor:
                        isDisabled
                            ? Colors.transparent
                            : (_isDarkTheme
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.3)),
                    highlightColor:
                        isDisabled
                            ? Colors.transparent
                            : (_isDarkTheme
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.15)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSaving)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors:
                                      isDisabled
                                          ? (_isDarkTheme
                                              ? [
                                                Colors.grey[700]!,
                                                Colors.grey[800]!,
                                              ]
                                              : [
                                                Colors.grey[400]!,
                                                Colors.grey[300]!,
                                              ])
                                          : (_isDarkTheme
                                              ? [
                                                Colors.white.withOpacity(0.15),
                                                Colors.white.withOpacity(0.1),
                                              ]
                                              : [
                                                Colors.white.withOpacity(0.3),
                                                Colors.white.withOpacity(0.2),
                                              ]),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow:
                                    isDisabled
                                        ? []
                                        : [
                                          BoxShadow(
                                            color: Colors.deepPurple
                                                .withOpacity(
                                                  _isDarkTheme ? 0.3 : 0.4,
                                                ),
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                              ),
                              child: Icon(
                                Icons.bookmark_rounded,
                                color:
                                    isDisabled
                                        ? (_isDarkTheme
                                            ? Colors.white38
                                            : Colors.black38)
                                        : Colors.white,
                                size: 24,
                              ),
                            ),
                          SizedBox(width: 12),
                          Text(
                            'Analizi Kaydet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDisabled
                                      ? (_isDarkTheme
                                          ? Colors.white38
                                          : Colors.black38)
                                      : Colors.white,
                              letterSpacing: 0.5,
                              shadows:
                                  isDisabled
                                      ? []
                                      : [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.4),
                                          offset: Offset(0, 2),
                                          blurRadius: 6,
                                        ),
                                      ],
                            ),
                          ),
                        ],
                      ),
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
}
