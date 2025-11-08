import 'dart:convert';
import 'dart:io'; // File kullanımı için eklendi
import 'package:flutter/material.dart';
import 'package:raya_ai/screens/add_product.dart';
import 'package:raya_ai/screens/analysis_screen.dart';
import 'package:raya_ai/widgets-tools/glass_bottom_navbar.dart';
import 'package:raya_ai/models/analysis_model.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalAnalysisEntry {  // _ kaldırıldı
  final String timestamp;
  final String? imagePath;
  final String? imageUrl;
  final List<LocalSection>? sections;  // _ kaldırıldı
  final SkinAnalysisResult? analysis;

  LocalAnalysisEntry({
    required this.timestamp,
    this.imagePath,
    this.imageUrl,
    this.sections,
    this.analysis,
  });

  factory LocalAnalysisEntry.fromJson(Map<String, dynamic> json) {
    if (json['analysis'] != null) {
      return LocalAnalysisEntry(
        timestamp: json['timestamp'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
        imageUrl: json['imageUrl'] as String?,
        analysis: SkinAnalysisResult.fromJson(json['analysis'] as Map<String, dynamic>),
      );
    }
    
    final List sectionsJson = json['sections'] as List? ?? [];
    return LocalAnalysisEntry(
      timestamp: json['timestamp'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      imageUrl: json['imageUrl'] as String?,
      sections: sectionsJson
          .map((e) => LocalSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  
  int get sectionCount {
    if (analysis != null) {
      int count = 0;
      if (analysis!.giris != null) count++;
      if (analysis!.butunculCiltAnalizi != null) count++;
      if (analysis!.kisisellestirilmisBakimPlani != null) count++;
      if (analysis!.makyajRenkOnerileri != null) count++;
      if (analysis!.onemliNotlarIpuclari != null) count++;
      if (analysis!.kapanisNotu != null) count++;
      return count;
    }
    return sections?.length ?? 0;
  }

  // ProductCompatibilityTest için display text
  String get displayText {
    final date = DateTime.tryParse(timestamp);
    if (date != null) {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return timestamp;
  }
}

class LocalSection {  // _ kaldırıldı
  final String title;
  final String content;

  LocalSection({required this.title, required this.content});

  factory LocalSection.fromJson(Map<String, dynamic> json) {
    return LocalSection(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

// Sonuç durumlarını yönetmek için bir enum
enum CompatibilityResult {
  Compatible,
  NotCompatible,
  Neutral,
}

class ProductCompatibilityTest extends StatefulWidget {
  const ProductCompatibilityTest({super.key});

  @override
  State<ProductCompatibilityTest> createState() =>
      _ProductCompatibilityTestState();
}

class _ProductCompatibilityTestState extends State<ProductCompatibilityTest> {
  int _selectedIndex = 0;

  // GERÇEK LocalAnalysisEntry kullanıyoruz (analysis_history_screen.dart'tan)
  late Future<List<LocalAnalysisEntry>> _entriesFuture;

  String? _selectedAnalysisTimestamp;
  String? _selectedProduct;
  bool _isLoading = false;
  CompatibilityResult? _result;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<LocalAnalysisEntry>> _loadEntries() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'analyses_${user.id}';
    final List<String> encodedList = prefs.getStringList(storageKey) ?? [];

    return encodedList.reversed.map((encoded) {
      final Map<String, dynamic> map =
          jsonDecode(encoded) as Map<String, dynamic>;
      return LocalAnalysisEntry.fromJson(map);
    }).toList();
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

  void _showAnalysisPicker(List<LocalAnalysisEntry> entries) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Geçmiş Analizi Seçin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.white24),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history,
                            size: 48, color: Colors.white.withOpacity(0.4)),
                        SizedBox(height: 12),
                        Text(
                          'Henüz kaydedilmiş analiz yok',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final analysis = entries[index];
                      final bool isSelected =
                          analysis.timestamp == _selectedAnalysisTimestamp;
                      
                      // Resim kontrolü
                      final hasLocalImage = analysis.imagePath != null &&
                          analysis.imagePath!.isNotEmpty &&
                          File(analysis.imagePath!).existsSync();
                      final hasNetworkImage = analysis.imageUrl != null &&
                          analysis.imageUrl!.isNotEmpty;
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.pink.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.pink
                                : Colors.white.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isSelected ? Colors.pink : Colors.white54,
                              ),
                              SizedBox(width: 12),
                              // Analiz resmi
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.pink.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: hasLocalImage
                                      ? Image.file(
                                          File(analysis.imagePath!),
                                          fit: BoxFit.cover,
                                        )
                                      : hasNetworkImage
                                          ? Image.network(
                                              analysis.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  _buildPlaceholderImage(),
                                            )
                                          : _buildPlaceholderImage(),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            analysis.displayText,
                            style: TextStyle(
                              color: isSelected ? Colors.pink : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${analysis.sectionCount} bölüm',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedAnalysisTimestamp = analysis.timestamp;
                              _result = null;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Örnek ürünler listesi (içerik bilgileri ile)
  final List<Map<String, dynamic>> _sampleProducts = [
    {
      'name': 'CeraVe Nemlendirici Krem',
      'brand': 'CeraVe',
      'category': 'Nemlendirici',
      'size': '50ml',
      'ingredients': ['Ceramides', 'Hyaluronic Acid', 'Glycerin'],
      'problematicIngredients': [],
      'beneficialFor': ['Kuru Cilt', 'Hassas Cilt', 'Bariyer Onarımı'],
    },
    {
      'name': 'La Roche-Posay Toleriane Ultra',
      'brand': 'La Roche-Posay',
      'category': 'Nemlendirici',
      'size': '40ml',
      'ingredients': ['Niacinamide', 'Glycerin', 'Squalane'],
      'problematicIngredients': [],
      'beneficialFor': ['Hassas Cilt', 'Kızarıklık', 'Tahriş'],
    },
    {
      'name': 'The Ordinary Niacinamide 10% + Zinc 1%',
      'brand': 'The Ordinary',
      'category': 'Serum',
      'size': '30ml',
      'ingredients': ['Niacinamide', 'Zinc PCA'],
      'problematicIngredients': [],
      'beneficialFor': ['Yağlı Cilt', 'Akne', 'Gözenek'],
    },
    {
      'name': 'Paula\'s Choice 2% BHA Liquid Exfoliant',
      'brand': 'Paula\'s Choice',
      'category': 'Tonik',
      'size': '118ml',
      'ingredients': ['Salicylic Acid', 'Methylpropanediol'],
      'problematicIngredients': ['Salicylic Acid'],
      'beneficialFor': ['Yağlı Cilt', 'Gözenek', 'Siyah Nokta'],
      'warnings': ['Hassas ciltlerde tahriş edebilir', 'Güneş hassasiyeti yaratabilir'],
    },
    {
      'name': 'Neutrogena Ultra Gentle Daily Cleanser',
      'brand': 'Neutrogena',
      'category': 'Temizleyici',
      'size': '200ml',
      'ingredients': ['Sodium Laureth Sulfate', 'Glycerin'],
      'problematicIngredients': ['Sodium Laureth Sulfate'],
      'beneficialFor': ['Normal Cilt'],
      'warnings': ['Hassas ciltlerde kuruluk yaratabilir'],
    },
    {
      'name': 'Vichy Aqualia Thermal Serum',
      'brand': 'Vichy',
      'category': 'Serum',
      'size': '30ml',
      'ingredients': ['Hyaluronic Acid', 'Mineralizing Water'],
      'problematicIngredients': [],
      'beneficialFor': ['Kuru Cilt', 'Dehidrasyon', 'Nem'],
    },
    {
      'name': 'Avene Thermal Spring Water',
      'brand': 'Avene',
      'category': 'Tonik',
      'size': '300ml',
      'ingredients': ['Thermal Spring Water'],
      'problematicIngredients': [],
      'beneficialFor': ['Hassas Cilt', 'Tahriş', 'Kızarıklık'],
    },
    {
      'name': 'Bioderma Sensibio H2O Micellar Water',
      'brand': 'Bioderma',
      'category': 'Temizleyici',
      'size': '250ml',
      'ingredients': ['Micelles', 'Cucumber Extract'],
      'problematicIngredients': [],
      'beneficialFor': ['Hassas Cilt', 'Temizleme'],
    },
    {
      'name': 'Kiehl\'s Ultra Facial Cream',
      'brand': 'Kiehl\'s',
      'category': 'Nemlendirici',
      'size': '50ml',
      'ingredients': ['Glycerin', 'Squalane', 'Glacial Glycoprotein'],
      'problematicIngredients': [],
      'beneficialFor': ['Kuru Cilt', 'Nem'],
    },
    {
      'name': 'Clinique Dramatically Different Moisturizing Lotion+',
      'brand': 'Clinique',
      'category': 'Nemlendirici',
      'size': '125ml',
      'ingredients': ['Glycerin', 'Urea', 'Hyaluronic Acid'],
      'problematicIngredients': [],
      'beneficialFor': ['Kuru Cilt', 'Nem'],
    },
  ];

  void _selectProduct() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[900]!, Colors.black],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ürün Seç',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.1)),
              // Product List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _sampleProducts.length,
                  itemBuilder: (context, index) {
                    final product = _sampleProducts[index];
                    final isSelected = _selectedProduct == 
                        '${product['name']} (${product['size']})';
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.pink.withOpacity(0.15)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.pink.withOpacity(0.6)
                              : Colors.white.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedProduct = '${product['name']} (${product['size']})';
                              _result = null;
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Check icon
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.pink
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.pink
                                          : Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                      : null,
                                ),
                                SizedBox(width: 16),
                                // Product info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name']!,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.pink
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.pink.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              product['category']!,
                                              style: TextStyle(
                                                color: Colors.pink,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            product['brand']!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 13,
                                            ),
                                          ),
                                          Spacer(),
                                          Text(
                                            product['size']!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
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
                  },
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _runCompatibilityTest() async {
    if (_selectedAnalysisTimestamp == null || _selectedProduct == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    // TODO: n8n veya Supabase'e istek gönder
    await Future.delayed(const Duration(seconds: 2));

    final ts = _selectedAnalysisTimestamp;
    setState(() {
      _isLoading = false;
      if (ts.hashCode % 3 == 0) {
        _result = CompatibilityResult.NotCompatible;
      } else if (ts.hashCode % 3 == 1) {
        _result = CompatibilityResult.Compatible;
      } else {
        _result = CompatibilityResult.Neutral;
      }
    });
  }

  Widget _buildAnalysisSelector(List<LocalAnalysisEntry> entries) {
    String selectedAnalysisText = "Geçmiş bir analiz seçin...";
    Color textColor = Colors.white54;
    IconData iconData = Icons.analytics_outlined;
    Widget? leadingWidget;

    if (_selectedAnalysisTimestamp != null) {
      try {
        final selectedEntry = entries
            .firstWhere((a) => a.timestamp == _selectedAnalysisTimestamp);
        selectedAnalysisText = selectedEntry.displayText;
        textColor = Colors.white;
        iconData = Icons.check_circle_outline;
        
        // Seçili analizin resmini göster
        final hasLocalImage = selectedEntry.imagePath != null &&
            selectedEntry.imagePath!.isNotEmpty &&
            File(selectedEntry.imagePath!).existsSync();
        final hasNetworkImage = selectedEntry.imageUrl != null &&
            selectedEntry.imageUrl!.isNotEmpty;
        
        if (hasLocalImage || hasNetworkImage) {
          leadingWidget = Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.pink.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: hasLocalImage
                  ? Image.file(
                      File(selectedEntry.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      selectedEntry.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    ),
            ),
          );
        }
      } catch (e) {
        selectedAnalysisText = "Hata - Analiz bulunamadı";
        textColor = Colors.redAccent;
        iconData = Icons.error_outline;
      }
    }

    return _buildStepCard(
      step: "1. Adım",
      title: "Analiz Seç",
      content: InkWell(
        onTap: () => _showAnalysisPicker(entries),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                SizedBox(width: 12),
              ] else
                Icon(iconData, color: textColor, size: 20),
              if (leadingWidget == null) SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedAnalysisText,
                  style: TextStyle(color: textColor, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  // Placeholder resim widget'ı
  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[800],
      child: Icon(
        Icons.image_outlined,
        color: Colors.white54,
        size: 24,
      ),
    );
  }

  Widget _buildProductSelector() {
    return _buildStepCard(
      step: "2. Adım",
      title: "Ürün Seç",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text("Ürün Ara veya Seç"),
            onPressed: _selectProduct,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.1),
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_selectedProduct != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.check_box,
                      color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedProduct!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_result == null) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String title;
    String description;

    switch (_result!) {
      case CompatibilityResult.Compatible:
        icon = Icons.check_circle_outline;
        color = Colors.greenAccent[400]!;
        title = "UYUMLU";
        description =
            "Bu ürün, seçtiğiniz analiz sonucuna göre cildinizle uyumlu görünüyor.";
        break;
      case CompatibilityResult.NotCompatible:
        icon = Icons.highlight_off;
        color = Colors.redAccent[400]!;
        title = "UYUMLU DEĞİL";
        description =
            "Bu ürün, seçtiğiniz analizdeki hassasiyetlere (örn: Salisilik Asit) tetikleyici olabilir.";
        break;
      case CompatibilityResult.Neutral:
        icon = Icons.info_outline;
        color = Colors.amber[600]!;
        title = "NÖTR / BİLGİ YOK";
        description =
            "Bu ürünün içeriği veya seçtiğiniz analiz, net bir uyum bilgisi sağlamak için yetersiz.";
        break;
    }

    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
      {required String step,
      required String title,
      required Widget content}) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step,
              style: TextStyle(
                color: Colors.pink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTestReady =
        _selectedAnalysisTimestamp != null && _selectedProduct != null;

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
              child: FutureBuilder<List<LocalAnalysisEntry>>(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.pink),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.redAccent),
                            SizedBox(height: 16),
                            Text(
                              'Analizler yüklenemedi',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(color: Colors.white54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final entries = snapshot.data ?? [];

                  if (entries.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history,
                                size: 64, color: Colors.white.withOpacity(0.3)),
                            SizedBox(height: 16),
                            Text(
                              'Henüz kaydedilmiş bir analiziniz yok.',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AnalysisScreen(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.add),
                              label: Text('İlk Analizini Yap'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Ürün Uyum Testi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Geçmiş analizlerinizi seçerek ürünlerin cildinize uyumunu kontrol edin.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildAnalysisSelector(entries),
                          const SizedBox(height: 16),

                          _buildProductSelector(),
                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed:
                                isTestReady ? _runCompatibilityTest : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[700],
                              disabledForegroundColor: Colors.grey[400],
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Uyumu Kontrol Et'),
                          ),
                          const SizedBox(height: 24),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildResultCard(),
                          ),

                          const SizedBox(height: 300),
                        ],
                      ),
                    ),
                  );
                },
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
}
