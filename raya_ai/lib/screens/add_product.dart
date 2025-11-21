import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raya_ai/screens/ProductCompatibilityTest.dart';
import 'package:raya_ai/screens/analysis_screen.dart';
import 'package:raya_ai/widgets-tools/glass_bottom_navbar.dart';

class ProductAddScreen extends StatefulWidget {
  const ProductAddScreen({Key? key}) : super(key: key);

  @override
  State<ProductAddScreen> createState() => _ProductAddScreenState();
}

class _ProductAddScreenState extends State<ProductAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedCategory;
  File? _productImage;
  bool _isLoading = false;
  int _selectedIndex = 2;

  bool get _isDarkTheme => Theme.of(context).brightness == Brightness.dark;

  Color get _primaryTextColor =>
      _isDarkTheme ? Colors.white : Colors.black87;

  Color get _secondaryTextColor =>
      _isDarkTheme ? Colors.white70 : Colors.black54;

  Color get _iconColor =>
      _isDarkTheme ? Colors.white70 : Colors.black54;

  Color get _hintTextColor =>
      _isDarkTheme ? Colors.white54 : Colors.black45;

  Color get _inputFillColor =>
      _isDarkTheme ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04);

  Color get _inputBorderColor =>
      _isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.12);

  LinearGradient get _backgroundGradient => _isDarkTheme
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[900]!, Colors.black],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDFBFF), Color(0xFFE6E6FA)],
        );

  final List<String> _categories = [
    'Temizleyici',
    'Tonik',
    'Serum',
    'Nemlendirici',
    'Göz Kremi',
    'Maske',
    'Güneş Kremi',
    'Peeling',
    'Yağ',
    'Diğer',
  ];

  @override
  void dispose() {
    _productNameController.dispose();
    _brandController.dispose();
    _ingredientsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _productImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Resim seçilirken hata oluştu: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _isDarkTheme ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _isDarkTheme ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Ürün Fotoğrafı Ekle',
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildImageSourceOption(
              icon: Icons.camera_alt,
              title: 'Kamera',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            SizedBox(height: 12),
            _buildImageSourceOption(
              icon: Icons.photo_library,
              title: 'Galeri',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final Color containerColor =
        _isDarkTheme ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
    final Color borderColor =
        _isDarkTheme ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.08);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink, Colors.pinkAccent],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _isDarkTheme ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _isDarkTheme ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Kategori Seç',
                    style: TextStyle(
                      color: _primaryTextColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: _isDarkTheme ? Colors.white24 : Colors.black12,
              height: 1,
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isSelected ? Colors.pink : _secondaryTextColor,
                    ),
                    title: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.pink : _primaryTextColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.greenAccent[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      _showErrorSnackBar('Lütfen bir kategori seçin');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Burada ürünü Supabase veya local storage'a kaydet
      await Future.delayed(Duration(seconds: 2)); // Simülasyon

      final productData = {
        'name': _productNameController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _selectedCategory,
        'ingredients': _ingredientsController.text.trim(),
        'notes': _notesController.text.trim(),
        'imagePath': _productImage?.path,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _showSuccessSnackBar('Ürün başarıyla kaydedildi!');
      
      // Ürün bilgilerini geri döndür ve sayfayı kapat
      Navigator.pop(context, productData);
    } catch (e) {
      _showErrorSnackBar('Ürün kaydedilirken hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: _backgroundGradient,
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _iconColor,
                            size: 22,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnalysisScreen(),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Yeni Ürün Ekle',
                          style: TextStyle(
                            color: _primaryTextColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Ürün Fotoğrafı
                            _buildImageSection(),
                            SizedBox(height: 24),

                            // Ürün Adı
                            _buildInputField(
                              controller: _productNameController,
                              label: 'Ürün Adı',
                              hint: 'Örn: CeraVe Nemlendirici Krem',
                              icon: Icons.shopping_bag_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ürün adı gerekli';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Marka
                            _buildInputField(
                              controller: _brandController,
                              label: 'Marka',
                              hint: 'Örn: CeraVe',
                              icon: Icons.business_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Marka adı gerekli';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Kategori
                            _buildCategorySelector(),
                            SizedBox(height: 16),

                            // İçerik Listesi
                            _buildInputField(
                              controller: _ingredientsController,
                              label: 'İçerik Listesi (Opsiyonel)',
                              hint: 'Ürünün içeriğindeki maddeleri yazın',
                              icon: Icons.list_alt,
                              maxLines: 5,
                              validator: null,
                            ),
                            SizedBox(height: 16),

                            // Notlar
                            _buildInputField(
                              controller: _notesController,
                              label: 'Notlar (Opsiyonel)',
                              hint: 'Ürün hakkında notlarınız...',
                              icon: Icons.note_outlined,
                              maxLines: 3,
                              validator: null,
                            ),
                            SizedBox(height: 32),

                            // Kaydet Butonu
                            _buildSaveButton(),
                            SizedBox(height: 20),
                            SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

  Widget _buildImageSection() {
    final gradientColors = _isDarkTheme
        ? [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ]
        : [
            Colors.pink.withOpacity(0.08),
            Colors.pinkAccent.withOpacity(0.05),
          ];
    final borderColor =
        _isDarkTheme ? Colors.pink.withOpacity(0.3) : Colors.pinkAccent.withOpacity(0.4);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
        ),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: _productImage == null
          ? InkWell(
              onTap: _showImageSourceDialog,
              borderRadius: BorderRadius.circular(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink, Colors.pinkAccent],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Ürün Fotoğrafı Ekle',
                    style: TextStyle(
                      color: _primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dokunarak fotoğraf ekleyin',
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _productImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _buildImageActionButton(
                        icon: Icons.edit,
                        onTap: _showImageSourceDialog,
                      ),
                      SizedBox(width: 8),
                      _buildImageActionButton(
                        icon: Icons.delete,
                        onTap: () {
                          setState(() {
                            _productImage = null;
                          });
                        },
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? Colors.pink).withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.pink, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(color: _primaryTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _hintTextColor),
            filled: true,
            fillColor: _inputFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.pink, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_outlined, color: Colors.pink, size: 20),
            SizedBox(width: 8),
            Text(
              'Kategori',
              style: TextStyle(
                color: _primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: _showCategoryPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _inputFillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedCategory != null
                    ? Colors.pink
                    : _inputBorderColor,
                width: _selectedCategory != null ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory ?? 'Kategori seçin...',
                  style: TextStyle(
                    color: _selectedCategory != null
                        ? _primaryTextColor
                        : _hintTextColor,
                    fontSize: 16,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: _secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.pink, Colors.pinkAccent],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveProduct,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Ürünü Kaydet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}