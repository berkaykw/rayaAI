import 'dart:io';
import 'dart:convert';
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
  String userTier = 'free'; // 'free' veya 'premium'

  String? _statusMessage;
  SkinAnalysisResult? _analysisResult;
  bool _isLoading = false;
  String? _imageUrlForDisplay;
  File? _selectedImageFile;

  // Yeni: Ürün önerisi tercihleri
  bool _includeProducts = false;
  int _productCount = 3;

  bool _isSabahRutiniExpanded = false;
  bool _isAksamRutiniExpanded = false;
  bool _isMakyajOnerileriExpanded = false;
  bool _isNotlarIpuclariExpanded = false;
  bool _isKapanisNotuExpanded = false;
  bool _isUrunOnerileriExpanded = false; 

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() {
      setState(() {});
    });
    _loadUserName();
    _loadUserTier();
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
      final response = await Supabase.instance.client
          .from('user_subscriptions')
          .select('tier')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      setState(() {
        userTier = response?['tier'] ?? 'free';
      });
    } catch (e) {
      setState(() {
        userTier = 'free';
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
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

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _analysisResult = null;
    });

    // 1. KULLANICI ID'SİNİ AL
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = "Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın.";
        _isLoading = false;
      });
      return;
    }
    final String userId = user.id;

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

    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'analyses_${user.id}';
      final List<String> existingEncoded = prefs.getStringList(storageKey) ?? [];

      final Map<String, dynamic> entry = {
        'timestamp': DateTime.now().toIso8601String(),
        'imagePath': _selectedImageFile?.path,
        'imageUrl': _imageUrlForDisplay,
        'analysis': _analysisResult!.toJson(),
      };

      existingEncoded.add(jsonEncode(entry));
      await prefs.setStringList(storageKey, existingEncoded);

      _showSuccess('Analiz kaydedildi');
    } catch (e) {
      setState(() {
        _statusMessage = 'Analiz kaydedilemedi: $e';
      });
    }
  }

  void _resetState() {
    setState(() {
      _isLoading = false;
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

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[900]!,
                Colors.black,
              ],
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
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
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
                              decorationColor: Colors.black.withOpacity(0.6),
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold
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
                      _showSuccess('Premium özelliği yakında aktif olacak!');
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
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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

  Widget _buildPremiumFeature(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.green,
            size: 20,
          ),
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
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        ),
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
                            Text(
                              userName ?? '******',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
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
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                             child: IconButton(
  onPressed: () {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ProfileScreen(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  },
  icon: const Icon(Icons.person_outline_rounded),
  iconSize: 25,
  color: Colors.white,
),
                            ),
                          ],
                        ),
                      ),
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
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.15),
            Colors.pink.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ürün Önerisi Toggle
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
                          color: Colors.pinkAccent,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Ürün Önerisi',
                          style: TextStyle(
                            color: Colors.white,
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
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle Switch
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
                    color: _includeProducts
                        ? Colors.pinkAccent
                        : Colors.white.withOpacity(0.2),
                  ),
                  child: AnimatedAlign(
                    duration: Duration(milliseconds: 200),
                    alignment: _includeProducts
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 26,
                      height: 26,
                      margin: EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Ürün sayısı seçimi (sadece toggle aktifse göster)
          if (_includeProducts) ...[
            SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white70,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'Kaç ürün görmek istersiniz?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // 3 Ürün Seçeneği
            GestureDetector(
              onTap: () {
                setState(() {
                  _productCount = 3;
                });
              },
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _productCount == 3
                      ? Colors.purple.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _productCount == 3
                        ? Colors.purple
                        : Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _productCount == 3
                              ? Colors.purple
                              : Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                        color: _productCount == 3
                            ? Colors.purple
                            : Colors.transparent,
                      ),
                      child: _productCount == 3
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Ücretsiz',
                            style: TextStyle(
                              color: Colors.white70,
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
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green,
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

            // 10 Ürün Seçeneği (Premium)
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
                      color: _productCount == 10 && userTier == 'premium'
                          ? Colors.amber.withOpacity(0.3)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _productCount == 10 && userTier == 'premium'
                            ? Colors.amber
                            : Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
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
                                  _productCount == 10 && userTier == 'premium'
                                      ? Colors.amber
                                      : Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                            color: _productCount == 10 && userTier == 'premium'
                                ? Colors.amber
                                : Colors.transparent,
                          ),
                          child: _productCount == 10 && userTier == 'premium'
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
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.yellowAccent,
                                    size: 18,
                                  ),
                                ],
                              ),
                              Text(
                                'Premium',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
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
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (userTier == 'free')
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
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
            if (_selectedImageFile == null && _imageUrlForDisplay == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageViewer(
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
              child: _selectedImageFile != null
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
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
                      builder: (context) => FullScreenImageViewer(
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
  );
}

 Widget _buildAnalyzeButton() {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 0,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.withOpacity(0.3),
            Colors.pinkAccent.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _analyzePickedImage,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_fix_high_sharp,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Analiz Et',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(0, 2),
                        blurRadius: 4,
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
  );
}

  Widget _buildBody() {
    if (_isLoading) {
      return Column(children: [SizedBox(height: 250), _buildLoadingState()]);
    } else if (_statusMessage != null) {
      return Column(children: [SizedBox(height: 50,), _buildErrorState(),SizedBox(height: 20,),_buildAnalyzeAgainButton() ,SizedBox(height: 250)]);
    } else if (_analysisResult != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildResultsSection(), _buildAnalyzeAgainButton(), _buildSavedAnalyze()],
      );
    } else {
      return Column(
        children: [
          SizedBox(height: 20),
          _buildTipsCarousel(),
        ],
      );
    }
  }

 Widget _buildButtonCamera() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color.fromARGB(255, 94, 9, 54).withOpacity(0.3),
          Color.fromARGB(255, 94, 9, 54).withOpacity(0.2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Color.fromARGB(255, 94, 9, 54).withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 0,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _pickImageFromCamera,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
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
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildButtonGalery() {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.pink.withOpacity(0.3),
          Colors.pinkAccent.withOpacity(0.2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: 0,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _pickImageFromGallery,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
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
                      color: Colors.black.withOpacity(0.3),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
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
        const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.white),
            Text(
              'Doğru Analiz İçin İpuçları',
              style: TextStyle(
                color: Colors.white,
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
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        tip['icon'] as IconData,
                        color: Colors.pinkAccent,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tip['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tip['text'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          height: 1.4,
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
          const CircularProgressIndicator(color: Colors.pinkAccent),
          const SizedBox(height: 20),
          Text(
            _selectedImageFile != null
                ? 'Resim yükleniyor ve analiz ediliyor...'
                : 'Analiz ediliyor...',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
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
          color: Colors.red.withOpacity(0.1),
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
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.pink.withOpacity(0.3),
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
                                builder: (context) => FullScreenImageViewer(
                                  imageUrl: _imageUrlForDisplay,
                                  imagePath: _selectedImageFile?.path,
                                  isLocalFile: _selectedImageFile != null,
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: _selectedImageFile?.path ?? _imageUrlForDisplay ?? '',
                            child: _selectedImageFile != null
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
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 240,
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(18),
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
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
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
                                  color: Colors.black.withOpacity(0.3),
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
                                      builder: (context) => FullScreenImageViewer(
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
        if (_analysisResult != null)
          _buildAnalysisResults(_analysisResult!),
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
          title: 'Hoş Geldiniz',
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
          gradient: [Colors.blue.withOpacity(0.3), Colors.blueAccent.withOpacity(0.2)],
          isExpanded: _isUrunOnerileriExpanded,
          onTap: () {
            setState(() {
              _isUrunOnerileriExpanded = !_isUrunOnerileriExpanded;
            });
          },
          content: _formatUrunOnerileri(result.outputUrun!),
        ),
      
      // Makyaj ve Renk Önerileri - GENİŞLETİLEBİLİR
      if (result.makyajRenkOnerileri != null)
        _buildExpandableRoutineCard(
          title: result.makyajRenkOnerileri!.baslik ?? 'Makyaj ve Renk Önerileri',
          icon: Icons.brush_outlined,
          gradient: [Colors.pink.withOpacity(0.3), Colors.pinkAccent.withOpacity(0.2)],
          isExpanded: _isMakyajOnerileriExpanded,
          onTap: () {
            setState(() {
              _isMakyajOnerileriExpanded = !_isMakyajOnerileriExpanded;
            });
          },
          content: _buildMakyajOnerileriContent(result.makyajRenkOnerileri!),
        ),
      
      // Önemli Notlar ve İpuçları - GENİŞLETİLEBİLİR
      if (result.onemliNotlarIpuclari != null)
        _buildExpandableRoutineCard(
          title: result.onemliNotlarIpuclari!.baslik ?? 'Önemli Notlar ve İpuçları',
          icon: Icons.lightbulb_outline,
          gradient: [Colors.yellow.withOpacity(0.2), Colors.yellowAccent.withOpacity(0.4)],
          isExpanded: _isNotlarIpuclariExpanded,
          onTap: () {
            setState(() {
              _isNotlarIpuclariExpanded = !_isNotlarIpuclariExpanded;
            });
          },
          content: _buildNotlarIpuclariContent(result.onemliNotlarIpuclari!),
        ),
      
      // Kapanış Notu - GENİŞLETİLEBİLİR
      if (result.kapanisNotu != null)
        _buildExpandableRoutineCard(
          title: 'Kapanış',
          icon: Icons.favorite,
          gradient: [Colors.deepPurple.withOpacity(0.2), Colors.deepPurple.withOpacity(0.4)],
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
        buffer.writeln('• Cilt Alt Tonu: ${analiz.gorselDegerlendirme!.ciltAltTonu}');
      }
      if (analiz.gorselDegerlendirme!.tespitEdilenDurumlar != null) {
        buffer.writeln('• Tespit Edilen Durumlar: ${analiz.gorselDegerlendirme!.tespitEdilenDurumlar}');
      }
      buffer.writeln('');
    }
    
    if (analiz.yasamTarziEtkileri != null) {
      buffer.writeln('💤 Yaşam Tarzı Etkileri:');
      if (analiz.yasamTarziEtkileri!.uykuEtkisi != null) {
        buffer.writeln('• Uyku: ${analiz.yasamTarziEtkileri!.uykuEtkisi}');
      }
      if (analiz.yasamTarziEtkileri!.sigaraVeDigerEtkiler != null) {
        buffer.writeln('• Sigara: ${analiz.yasamTarziEtkileri!.sigaraVeDigerEtkiler}');
      }
      buffer.writeln('');
    }
    
    if (analiz.mevcutRutinDegerlendirmesi != null) {
      buffer.writeln('🔍 Mevcut Rutin Değerlendirmesi:');
      if (analiz.mevcutRutinDegerlendirmesi!.ciltTipiVeTemizlikYorumu != null) {
        buffer.writeln('• ${analiz.mevcutRutinDegerlendirmesi!.ciltTipiVeTemizlikYorumu}');
      }
      if (analiz.mevcutRutinDegerlendirmesi!.mevcutAdimlarVeEksikler != null) {
        buffer.writeln('• ${analiz.mevcutRutinDegerlendirmesi!.mevcutAdimlarVeEksikler}');
      }
    }
    
    return buffer.toString();
  }

 Widget _buildBakimPlaniCard(KisisellestirilmisBakimPlani plan) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: Column(
      children: [
        // Ana başlık kartı
        _buildAnalysisCard(
          title: plan.baslik ?? 'Kişiselleştirilmiş Bakım Planı',
          content: plan.oncelikliHedef != null 
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
            gradient: [Colors.pink.withOpacity(0.3), Colors.pinkAccent.withOpacity(0.2)],
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
            gradient: [Colors.pink.withOpacity(0.3), Colors.pinkAccent.withOpacity(0.2)],
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
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: Stack(
      children: [
        // Glow effect
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
        
        // Ana kart
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: gradient[0].withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                // Tıklanabilir başlık bölümü
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                      bottom: isExpanded ? Radius.zero : Radius.circular(24),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon container
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: gradient[0].withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 14),
                          
                          // Başlık
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Açılır ok ikonu
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: Duration(milliseconds: 300),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
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
                
                // Genişletilebilir içerik
                AnimatedSize(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    height: isExpanded ? null : 0,
                    child: AnimatedOpacity(
                      duration: Duration(milliseconds: 250),
                      opacity: isExpanded ? 1.0 : 0.0,
                      child: isExpanded
                          ? Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                content,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 15,
                                  height: 1.6,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          : SizedBox.shrink(),
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
    buffer.writeln('1️⃣ Çift Aşamalı Temizleme (Yağ)\n${aksamRutini.adim1CiftAsamaliTemizlemeYag}\n');
  }
  if (aksamRutini.adim1CiftAsamaliTemizlemeSu != null) {
    buffer.writeln('1️⃣ Çift Aşamalı Temizleme (Su)\n${aksamRutini.adim1CiftAsamaliTemizlemeSu}\n');
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
    formatted = formatted.replaceAll(RegExp(r'###\s+(\d+\.\s+[^\n]+)'), '\n📦 \$1\n');
    
    // ** kalın yazıları
    formatted = formatted.replaceAll(RegExp(r'\*\*([^\*]+)\*\*'), '\$1');
    
    // * liste işaretlerini
    formatted = formatted.replaceAll(RegExp(r'^\s*\*\s+', multiLine: true), '• ');
    
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // Arka plan glow efekti
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          
          // Ana kart - Glass effect
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.pink.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Pembe gradient overlay (üst köşe)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.pink.withOpacity(0.2),
                            Colors.transparent,
                          ],
                          radius: 1.0,
                        ),
                      ),
                    ),
                  ),
                  
                  // İçerik
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık bölümü
                        Row(
                          children: [
                            // Icon container
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.pinkAccent,
                                    Colors.pink,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 14),
                            
                            // Başlık
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Container(
                                    height: 3,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.pinkAccent,
                                          Colors.pink,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // İçerik
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            content,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
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
            color: Colors.white,
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
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

Widget _buildAnalyzeAgainButton() {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: Stack(
      children: [
        // Glow effect
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: Offset(0, 8),
                ),
              ],
            ),
          ),
        ),

        // Main button (CLICK AREA)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _resetState, // ✅ İlk koddaki işlem
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.pink.withOpacity(0.3),
            highlightColor: Colors.pink.withOpacity(0.2),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2D1B2E),
                    Color(0xFF1A1A1A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.pink.withOpacity(0.5),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.pinkAccent,
                          Colors.pink,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.5),
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

        // Highlight (tıklamayı engellememesi için ignoreEnabled)
        IgnorePointer(
          child: Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSavedAnalyze() {
  final bool isDisabled = _analysisResult == null;
  
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
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
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
        
        // Main button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: isDisabled
                  ? [
                      Color(0xFF1A1A1A),
                      Color(0xFF0D0D0D),
                    ]
                  : [
                      Color(0xFF2A1B3D), // Koyu mor
                      Color(0xFF1A1A1A), // Koyu gri
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDisabled
                  ? Colors.white.withOpacity(0.2)
                  : Colors.deepPurple.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : _saveCurrentAnalysis,
              borderRadius: BorderRadius.circular(20),
              splashColor: isDisabled ? Colors.transparent : Colors.deepPurple.withOpacity(0.3),
              highlightColor: isDisabled ? Colors.transparent : Colors.deepPurple.withOpacity(0.2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDisabled
                              ? [
                                  Colors.grey[700]!,
                                  Colors.grey[800]!,
                                ]
                              : [
                                  Colors.deepPurpleAccent,
                                  Colors.deepPurple,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isDisabled
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.bookmark_rounded,
                        color: isDisabled ? Colors.white38 : Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Analizi Kaydet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.white38 : Colors.white,
                        letterSpacing: 0.5,
                        shadows: isDisabled
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
        
        // Üst gradient highlight
        if (!isDisabled)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

}
