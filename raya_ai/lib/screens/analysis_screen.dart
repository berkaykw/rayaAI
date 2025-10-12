import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raya_ai/widgets/glass_bottom_navbar.dart';
import '../services/api_service.dart';
import '../models/analysis_model.dart';
import 'package:raya_ai/widgets/full_screen_image_viewer.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _selectedIndex = 1;
  final ApiService _apiService = ApiService();
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // EKLE

  String? _statusMessage;
  List<AnalysisSection>? _analysisResult;
  bool _isLoading = false;
  String? _imageUrlForDisplay;
  File? _selectedImageFile; // Seçilen resmi saklamak için

  @override
  void initState() {
    super.initState();
    _urlController.addListener(() {
      setState(() {});
    });
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

  /// Kamera ile fotoğraf çek
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Kalite ayarı
      );

      if (image != null) {
        await _analyzePickedImage(File(image.path));
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Kamera açılırken hata oluştu: $e';
      });
    }
  }

  /// Galeriden fotoğraf seç
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        await _analyzePickedImage(File(image.path));
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Galeri açılırken hata oluştu: $e';
      });
    }
  }

  /// Seçilen resmi analiz et
  Future<void> _analyzePickedImage(File imageFile) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _analysisResult = null;
      _selectedImageFile = imageFile;
      _imageUrlForDisplay = null; // URL ile gelen resimler için
    });

    try {
      // Resmi yükle ve analiz et
      final result = await _apiService.analyzeImageFromGallery(imageFile);
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

  void _resetState() {
    setState(() {
      _isLoading = false;
      _statusMessage = null;
      _analysisResult = null;
      _selectedImageFile = null;
      _imageUrlForDisplay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      endDrawer: Drawer(
        backgroundColor: Colors.black87,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Text(
                  'RAYA AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white24),

              ListTile(
                leading: const Icon(Icons.account_circle_outlined, color: Colors.pinkAccent),
                title: const Text(
                  'Profil',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Driver durumu ekranına yönlendirme
                },
              ),

              ListTile(
                leading: const Icon(Icons.settings, color: Colors.pinkAccent),
                title: const Text(
                  'Ayarlar',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Driver ayarları ekranına yönlendirme
                },
              ),

              ListTile(
                leading: const Icon(Icons.history, color: Colors.pinkAccent),
                title: const Text(
                  'Analiz Geçmişi',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Driver geçmiş ekranına yönlendirme
                },
              ),

              const Spacer(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Çıkış',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Çıkış işlemi
                },
              ),
            ],
          ),
        ),
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                onPressed: () {},
                                icon: Icon(Icons.auto_awesome),
                                iconSize: 22,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Raya AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
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
                              child: Builder(
                                builder:
                                    (context) => IconButton(
                                      onPressed: () {
                                        Scaffold.of(
                                          context,
                                        ).openEndDrawer(); // Soldan drawer aç
                                      },
                                      icon: const Icon(Icons.menu_rounded),
                                      iconSize: 22,
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isLoading && _statusMessage == null && _analysisResult == null)
                        Column(
                          children: [
                            _buildCenterText(),
                            const SizedBox(height: 40),
                          ],
                        ),
                        if (!_isLoading && _statusMessage == null && _analysisResult == null)
                        Column(
                          children: [
                            _buildButtonCamera(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      if (!_isLoading && _statusMessage == null && _analysisResult == null)
                        Column(
                          children: [
                            _buildButtonGalery(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      _buildBody(),
                      SizedBox(height: 200,),
                      if (_isLoading && _statusMessage == null && _analysisResult == null)
                        SizedBox(height: 300,),
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

  Widget _buildBody() {
    if (_isLoading) {
      return Column(
        children: [
          SizedBox(height: 250,),
          _buildLoadingState(),
        ],
      );
    } else if (_statusMessage != null) {
      return _buildErrorState();
    } else if (_analysisResult != null) {
      return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResultsSection(),
        _buildAnalyzeAgainButton(),
      ],
    );
    } else {
      return _buildTipsCarousel();
    }
  }

  Widget _buildButtonCamera() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _pickImageFromCamera, // GÜNCELLENDI
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
        onPressed: _isLoading ? null : _pickImageFromGallery, // GÜNCELLENDI
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
            Icon(Icons.lightbulb_outline,color: Colors.white,),
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
              _statusMessage!,
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
        Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.pink, Colors.pink[300]!],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.5),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.face_retouching_natural,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40),
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
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text('Tekrar Analiz Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: Colors.pink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
