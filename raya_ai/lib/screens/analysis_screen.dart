import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  List<AnalysisSection>? _analysisResult;
  bool _isLoading = false;
  String? _imageUrlForDisplay;
  File? _selectedImageFile;

  // Yeni: Ürün önerisi tercihleri
  bool _includeProducts = false;
  int _productCount = 3;

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
    setState(() {
      _selectedIndex = index;
    });
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

    try {
      final result = await _apiService.analyzeImageFromGallery(_selectedImageFile!);
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
    if (_analysisResult == null || _analysisResult!.isEmpty) {
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
        'sections': _analysisResult!.map((s) => s.toJson()).toList(),
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
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(),
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
      child: GestureDetector(
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
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _analyzePickedImage,
        icon: const Icon(Icons.auto_fix_high_sharp, color: Colors.white),
        label: const Text(
          'Analiz Et',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.pink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
      return _buildTipsCarousel();
    }
  }

  Widget _buildButtonCamera() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _pickImageFromCamera,
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text(
          'Fotoğraf Çek',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: const Color.fromARGB(255, 94, 9, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonGalery() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _pickImageFromGallery,
        icon: const Icon(Icons.photo_library_sharp, color: Colors.white),
        label: const Text(
          'Galeriden Seç',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.pink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          // Resim gösterimi - hem URL hem de File desteği
          if (_imageUrlForDisplay != null || _selectedImageFile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: GestureDetector(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
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
                            : Image.network(
                              _imageUrlForDisplay!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
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
              ),
            ),
          if (_analysisResult != null)
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _analysisResult!.length,
              itemBuilder: (context, index) {
                final section = _analysisResult![index];
                return _buildAnalysisCard(section);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(AnalysisSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: const TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 20, color: Colors.white38),
              Text(
                section.content,
                style: TextStyle(
                  height: 1.5,
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _resetState,
        icon: const Icon(Icons.refresh, color: Colors.white,size: 24,),
        label: const Text(
          'Tekrar Analiz Yap',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.pink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

 Widget _buildSavedAnalyze() {
  return Padding(
    padding: const EdgeInsets.only(top: 15),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _analysisResult == null ? null : _saveCurrentAnalysis,
        icon: const Icon(Icons.save_outlined, color: Colors.white, size: 24),
        label: const Text(
          'Analizi Kaydet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.green[500],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  );
}

}
