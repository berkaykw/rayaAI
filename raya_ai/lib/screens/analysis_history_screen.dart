import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:raya_ai/screens/profilepage_screen.dart';
import 'package:raya_ai/widgets-tools/full_screen_image_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analysis_model.dart';

class AnalysisHistoryScreen extends StatefulWidget {
  const AnalysisHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen> {
  late Future<List<_LocalAnalysisEntry>> _entriesFuture;


  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadEntries();
  }

  Future<List<_LocalAnalysisEntry>> _loadEntries() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'analyses_${user.id}';
    final List<String> encodedList = prefs.getStringList(storageKey) ?? [];

    return encodedList.reversed.map((encoded) {
      final Map<String, dynamic> map = jsonDecode(encoded) as Map<String, dynamic>;
      return _LocalAnalysisEntry.fromJson(map);
    }).toList();
  }

  Future<void> _deleteEntry(_LocalAnalysisEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Silinsin mi?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Bu analizi silmek istediğine emin misin?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'analyses_${user.id}';
    final List<String> encodedList = prefs.getStringList(storageKey) ?? [];

    final int indexToRemove = encodedList.indexWhere((encoded) {
      try {
        final Map<String, dynamic> map = jsonDecode(encoded) as Map<String, dynamic>;
        return map['timestamp'] == entry.timestamp;
      } catch (_) {
        return false;
      }
    });

    if (indexToRemove != -1) {
      encodedList.removeAt(indexToRemove);
      await prefs.setStringList(storageKey, encodedList);
    }

    setState(() {
      _entriesFuture = _loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<_LocalAnalysisEntry>>(
            future: _entriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent));
              }
              final entries = snapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Geçmiş Analizler',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (entries.isEmpty)
                      Column(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history,
                                      size: 48, color: Colors.white.withOpacity(0.6)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Kayıtlı analiz bulunamadı',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _AnalysisTile(
                            entry: entry,
                            onDelete: () => _deleteEntry(entry),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => _AnalysisDetailPage(entry: entry),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  final _LocalAnalysisEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  
  const _AnalysisTile({
    required this.entry,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(entry.timestamp);
    final formatted = date != null
        ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : entry.timestamp;

    Widget? leadingImage;
    if (entry.imagePath != null &&
        entry.imagePath!.isNotEmpty &&
        File(entry.imagePath!).existsSync()) {
      leadingImage = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(entry.imagePath!),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leadingImage ?? const Icon(Icons.analytics_outlined, color: Colors.pinkAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatted,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.sectionCount} bölüm',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _DeletePillButton(onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalAnalysisEntry {
  final String timestamp;
  final String? imagePath;
  final String? imageUrl;
  final List<_LocalSection>? sections;
  final SkinAnalysisResult? analysis;

  _LocalAnalysisEntry({
    required this.timestamp,
    this.imagePath,
    this.imageUrl,
    this.sections,
    this.analysis,
  });

  factory _LocalAnalysisEntry.fromJson(Map<String, dynamic> json) {
    if (json['analysis'] != null) {
      return _LocalAnalysisEntry(
        timestamp: json['timestamp'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
        imageUrl: json['imageUrl'] as String?,
        analysis: SkinAnalysisResult.fromJson(json['analysis'] as Map<String, dynamic>),
      );
    }
    
    final List sectionsJson = json['sections'] as List? ?? [];
    return _LocalAnalysisEntry(
      timestamp: json['timestamp'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      imageUrl: json['imageUrl'] as String?,
      sections: sectionsJson
          .map((e) => _LocalSection.fromJson(e as Map<String, dynamic>))
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
}

class _LocalSection {
  final String title;
  final String content;

  _LocalSection({required this.title, required this.content});

  factory _LocalSection.fromJson(Map<String, dynamic> json) {
    return _LocalSection(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

class _DeletePillButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _DeletePillButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.redAccent.withOpacity(0.18),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              SizedBox(width: 6),
              Text(
                'Sil',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisDetailPage extends StatefulWidget {
  final _LocalAnalysisEntry entry;
  const _AnalysisDetailPage({required this.entry});

  @override
  State<_AnalysisDetailPage> createState() => _AnalysisDetailPageState();
}

class _AnalysisDetailPageState extends State<_AnalysisDetailPage> {
  // Genişletme state'leri
  bool _isSabahRutiniExpanded = false;
  bool _isAksamRutiniExpanded = false;
  bool _isMakyajOnerileriExpanded = false;
  bool _isNotlarIpuclariExpanded = false;
  bool _isKapanisNotuExpanded = false;

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
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Analiz Detayı',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Resim gösterimi - Modern tasarım
                  if (widget.entry.imagePath != null || widget.entry.imageUrl != null)
                    _buildImageSection(),
                  
                  const SizedBox(height: 16),
                  
                  // Analiz sonuçları
                  if (widget.entry.analysis != null)
                    _buildAnalysisResults(widget.entry.analysis!)
                  else if (widget.entry.sections != null)
                    ...widget.entry.sections!.map((s) => _buildAnalysisCard(
                      title: s.title,
                      content: s.content,
                      icon: _getIconForSection(s.title),
                    )).toList(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final hasLocalFile = widget.entry.imagePath != null && 
                         widget.entry.imagePath!.isNotEmpty && 
                         File(widget.entry.imagePath!).existsSync();
    final hasNetworkImage = widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty;

    if (!hasLocalFile && !hasNetworkImage) return SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          // Glow effect
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
                            imageUrl: widget.entry.imageUrl,
                            imagePath: widget.entry.imagePath,
                            isLocalFile: hasLocalFile,
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: widget.entry.imagePath ?? widget.entry.imageUrl ?? '',
                      child: hasLocalFile
                          ? Image.file(
                              File(widget.entry.imagePath!),
                              height: 240,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.network(
                              widget.entry.imageUrl!,
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
                  
                  // Sağ üst badge
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
                                  imageUrl: widget.entry.imageUrl,
                                  imagePath: widget.entry.imagePath,
                                  isLocalFile: hasLocalFile,
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
          
          // Üst sağ accent glow
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
    );
  }

  Widget _buildAnalysisResults(SkinAnalysisResult result) {
    return Column(
      children: [
        // Giriş - AÇIK
        if (result.giris != null)
          _buildAnalysisCard(
            title: 'Hoş Geldiniz',
            content: result.giris!,
            icon: Icons.waving_hand,
          ),
        
        // Bütüncül Cilt Analizi - AÇIK
        if (result.butunculCiltAnalizi != null)
          _buildButunculCiltAnaliziCard(result.butunculCiltAnalizi!),
        
        // Kişiselleştirilmiş Bakım Planı
        if (result.kisisellestirilmisBakimPlani != null)
          _buildBakimPlaniCard(result.kisisellestirilmisBakimPlani!),
        
        // Makyaj Önerileri - GENİŞLETİLEBİLİR
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
        
        // Notlar ve İpuçları - GENİŞLETİLEBİLİR
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
        
        // Kapanış - GENİŞLETİLEBİLİR
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
          
          // Sabah Rutini
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
          
          // Akşam Rutini
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
                  // Tıklanabilir başlık
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

  Widget _buildAnalysisCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // Glow effect
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
                color: Colors.pink.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Gradient overlay
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
                        Row(
                          children: [
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

  IconData _getIconForSection(String title) {
    final titleLower = title.toLowerCase();

    if (titleLower.contains('cilt tipi') || titleLower.contains('skin type')) {
      return Icons.face_outlined;
    } else if (titleLower.contains('nem') || titleLower.contains('hydration')) {
      return Icons.water_drop_outlined;
    } else if (titleLower.contains('akne') || titleLower.contains('acne')) {
      return Icons.healing_outlined;
    } else if (titleLower.contains('kırışıklık') || titleLower.contains('wrinkle')) {
      return Icons.auto_fix_high;
    } else if (titleLower.contains('gözenek') || titleLower.contains('pore')) {
      return Icons.lens_blur_outlined;
    } else if (titleLower.contains('leke') || titleLower.contains('spot')) {
      return Icons.brightness_medium;
    } else if (titleLower.contains('ton') || titleLower.contains('tone')) {
      return Icons.palette_outlined;
    } else if (titleLower.contains('öneri') || titleLower.contains('recommendation')) {
      return Icons.lightbulb_outline;
    } else if (titleLower.contains('ürün') || titleLower.contains('product')) {
      return Icons.shopping_bag_outlined;
    } else {
      return Icons.auto_awesome_outlined;
    }
  }
}