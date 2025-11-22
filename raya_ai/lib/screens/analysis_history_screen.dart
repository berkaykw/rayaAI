import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:raya_ai/screens/profilepage_screen.dart';
import 'package:raya_ai/theme/app_theme.dart';
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
      builder: (context) {
        final theme = Theme.of(context);
        final bool isDark = theme.brightness == Brightness.dark;
        final Color dialogColor =
            isDark ? const Color(0xFF2A2A2A) : theme.colorScheme.surface;
        final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

        return AlertDialog(
          backgroundColor: dialogColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Silinsin mi?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Bu analizi silmek istediğine emin misin?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: TextStyle(color: textColor.withOpacity(0.7)),
            ),
          ),
          TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(theme.colorScheme.error),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sil',
              style: TextStyle(
                color: theme.colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        );
      },
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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
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

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: SafeArea(
          child: FutureBuilder<List<_LocalAnalysisEntry>>(
            future: _entriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ));
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
                        icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                              style: theme.textTheme.headlineSmall?.copyWith(
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
                                      size: 48,
                                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Kayıtlı analiz bulunamadı',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                                      fontSize: 16,
                                    ),
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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor =
        isDark ? Colors.white.withOpacity(0.05) : theme.colorScheme.surface;
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);
    final Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

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
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              leadingImage ??
                  Icon(Icons.analytics_outlined,
                      color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatted,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.sectionCount} bölüm',
                      style: TextStyle(color: textColor.withOpacity(0.7)),
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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color pillColor = isDark
        ? Colors.redAccent.withOpacity(0.1)
        : theme.colorScheme.error.withOpacity(0.15);

    return Material(
      color: pillColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Colors.red, size: 18),
              const SizedBox(width: 6),
              Text(
                'Sil',
                style: TextStyle(
                  color: Colors.red,
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
  bool _isUrunOnerileriExpanded = false;
  bool _isMakyajOnerileriExpanded = false;
  bool _isNotlarIpuclariExpanded = false;
  bool _isKapanisNotuExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Analiz Detayı',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Resim gösterimi - Modern tasarım
                  if (widget.entry.imagePath != null ||
                      widget.entry.imageUrl != null)
                    _buildImageSection(theme),
                  
                  const SizedBox(height: 16),
                  
                  // Analiz sonuçları
                  if (widget.entry.analysis != null)
                    _buildAnalysisResults(widget.entry.analysis!, theme)
                  else if (widget.entry.sections != null)
                    ...widget.entry.sections!
                        .map((s) => _buildAnalysisCard(
                              title: s.title,
                              content: s.content,
                              icon: _getIconForSection(s.title),
                              theme: theme,
                            ))
                        .toList(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    final hasLocalFile = widget.entry.imagePath != null &&
        widget.entry.imagePath!.isNotEmpty &&
        File(widget.entry.imagePath!).existsSync();
    final hasNetworkImage =
        widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty;

    if (!hasLocalFile && !hasNetworkImage) return SizedBox.shrink();

    final bool isDark = theme.brightness == Brightness.dark;
    final Color primary = theme.colorScheme.primary;
    final Color secondary = theme.colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: secondary.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(isDark ? 0.1 : 0.85),
                  Colors.white.withOpacity(isDark ? 0.05 : 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            padding: EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
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
                                  color: isDark
                                      ? Colors.black26
                                      : Colors.grey.withOpacity(0.2),
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
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(18)),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(isDark ? 0.7 : 0.4),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.2 : 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(isDark ? 0.3 : 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
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
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    primary.withOpacity(0.15),
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

  Widget _buildAnalysisResults(SkinAnalysisResult result, ThemeData theme) {
    return Column(
      children: [
        // Giriş - AÇIK
        if (result.giris != null)
          _buildAnalysisCard(
            title: 'Hoş Geldiniz',
            content: result.giris!,
            icon: Icons.waving_hand,
            theme: theme,
          ),
        
        // Bütüncül Cilt Analizi - AÇIK
        if (result.butunculCiltAnalizi != null)
          _buildButunculCiltAnaliziCard(result.butunculCiltAnalizi!, theme),
        
        // Kişiselleştirilmiş Bakım Planı
        if (result.kisisellestirilmisBakimPlani != null)
          _buildBakimPlaniCard(result.kisisellestirilmisBakimPlani!, theme),
        
        // Ürün Önerileri - GENİŞLETİLEBİLİR
        if (result.outputUrun != null && result.outputUrun!.isNotEmpty)
          _buildExpandableRoutineCard(
            title: 'Ürün Önerileri',
            icon: Icons.shopping_bag_outlined,
            gradient: [Colors.pink.withOpacity(0.3), Colors.pinkAccent.withOpacity(0.2)],
            isExpanded: _isUrunOnerileriExpanded,
            onTap: () {
              setState(() {
                _isUrunOnerileriExpanded = !_isUrunOnerileriExpanded;
              });
            },
            content: _formatUrunOnerileri(result.outputUrun!),
            theme: theme,
          ),
        
        const SizedBox(height: 12),
        
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
            theme: theme,
          ),

          const SizedBox(height: 12),
        
        // Notlar ve İpuçları - GENİŞLETİLEBİLİR
        if (result.onemliNotlarIpuclari != null)
          _buildExpandableRoutineCard(
            title: result.onemliNotlarIpuclari!.baslik ?? 'Önemli Notlar ve İpuçları',
            icon: Icons.lightbulb_outline,
            gradient: [Colors.yellow.withOpacity(0.4), Colors.yellow.withOpacity(0.3)],
            isExpanded: _isNotlarIpuclariExpanded,
            onTap: () {
              setState(() {
                _isNotlarIpuclariExpanded = !_isNotlarIpuclariExpanded;
              });
            },
            content: _buildNotlarIpuclariContent(result.onemliNotlarIpuclari!),
            theme: theme,
            forceGradient: true,
          ),
          const SizedBox(height: 12),
        // Kapanış - GENİŞLETİLEBİLİR
        if (result.kapanisNotu != null)
          _buildExpandableRoutineCard(
            title: 'Kapanış',
            icon: Icons.favorite,
            gradient: [Colors.deepPurple.withOpacity(0.4), Colors.deepPurple.withOpacity(0.3)],
            isExpanded: _isKapanisNotuExpanded,
            onTap: () {
              setState(() {
                _isKapanisNotuExpanded = !_isKapanisNotuExpanded;
              });
            },
            content: result.kapanisNotu!,
            theme: theme,
            forceGradient: true,
            
          ),
      ],
    );
  }

  Widget _buildButunculCiltAnaliziCard(
      ButunculCiltAnalizi analiz, ThemeData theme) {
    return _buildAnalysisCard(
      title: analiz.baslik ?? 'Bütüncül Cilt Analizi',
      content: _buildButunculCiltAnaliziContent(analiz),
      icon: Icons.face_outlined,
      theme: theme,
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

  Widget _buildBakimPlaniCard(
      KisisellestirilmisBakimPlani plan, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Ana başlık kartı
          _buildAnalysisCard(
            title: plan.baslik ?? 'Kişiselleştirilmiş Bakım Planı',
            content: plan.oncelikliHedef != null 
                ? '🎯 Öncelikli Hedef:\n${plan.oncelikliHedef}' 
                : '',
            icon: Icons.spa_outlined,
            theme: theme,
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
              theme: theme,
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
              theme: theme,
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
    required ThemeData theme,
    Color? customContentBg, // YENİ: Özel arka plan rengi (Kapanış için mor olacak)
    bool forceGradient = false, // Artık her zaman gradient olduğu için etkisi yok ama hata vermemesi için bıraktım
  }) {
    // --- RENK VE STİL AYARLARI ---

    // Parlama Rengi (Gradientin baskın renginden otomatik alır)
    final Color glowColor = gradient[0].withOpacity(0.4);

    // İçerik Arka Planı (Açılan Metin Kutusu):
    // Eğer dışarıdan özel bir renk (mor gibi) gönderildiyse onu kullan,
    // gönderilmediyse varsayılan koyu siyah transparan rengi kullan.
    final Color contentBackground =
        customContentBg ?? Colors.black.withOpacity(0.5);

    // Metin rengi her zaman beyaz (Çünkü kart tasarımı artık hep koyu)
    final Color contentTextColor = Colors.white.withOpacity(0.95);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          // --- GLOW EFFECT (DIŞ PARLAMA) ---
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 25,
                    spreadRadius: -5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
          ),

          // --- ANA KART GÖVDESİ ---
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                // Her zaman gradient kullanıyoruz (Premium Stil)
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: gradient[0].withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // --- BAŞLIK KISMI ---
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.vertical(
                        top: const Radius.circular(24),
                        bottom: isExpanded
                            ? Radius.zero
                            : const Radius.circular(24),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // İkon Kutusu
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                  )
                                ],
                              ),
                              child: Icon(icon, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            // Başlık Metni
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Ok İkonu
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
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

                  // --- AÇILAN İÇERİK KISMI ---
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: isExpanded
                        ? Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: contentBackground, // Özel renk burada kullanılıyor
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(24)),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              content,
                              style: TextStyle(
                                color: contentTextColor,
                                fontSize: 15,
                                height: 1.6,
                                letterSpacing: 0.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
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
  required ThemeData theme,
}) {
  final bool isDark = theme.brightness == Brightness.dark;
  final Color accent = theme.colorScheme.primary;
  final Color accent2 = theme.colorScheme.secondary;

  // --- RENK PALETİ ---
  final Color glassCardBg = Colors.pink.shade400.withOpacity(0.25);
  final Color glassContentBoxBg = Colors.pink.shade50.withOpacity(0.4);
  final Color glassAccent = Colors.pink.shade600.withOpacity(0.6);
  final Color glassBorder = Colors.pink.shade700.withOpacity(0.2);

  // --- GLOW RENGİ ---
  final Color glowColor = isDark
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
                  color: glowColor.withOpacity(isDark ? 0.05 : 0.1),
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
              if (!isDark)
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
                  color: isDark ? null : glassCardBg,
                  gradient: isDark
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
                    color: isDark ? accent.withOpacity(0.3) : glassBorder,
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // --- YANSIMA EFEKTİ (DÜZENLENDİ) ---

                    // KOYU MOD İÇİN ESKİ YANSIMA (Sağ üst köşe)
                    if (isDark)
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
                    if (!isDark)
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
                                  color: isDark ? null : glassAccent,
                                  gradient: isDark
                                      ? LinearGradient(
                                          colors: [accent, accent2],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? accent.withOpacity(0.2)
                                          : Colors.pink.shade700.withOpacity(0.25),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color: Colors.black.withOpacity(0.4),
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
                                        color: isDark ? null : glassAccent,
                                        gradient: isDark
                                            ? LinearGradient(colors: [accent, accent2])
                                            : null,
                                        borderRadius: BorderRadius.circular(2),
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
                              color: isDark
                                  ? Colors.black.withOpacity(0.2)
                                  : glassContentBoxBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                  ? theme.dividerColor.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              content,
                              style: TextStyle(
                                color: isDark
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

  String _formatUrunOnerileri(String urunOnerileri) {
    // Markdown formatını daha okunabilir hale getir
    String formatted = urunOnerileri;
    
    // ### başlıkları için
    formatted = formatted.replaceAllMapped(RegExp(r'###\s+(\d+\.\s+[^\n]+)'), (match) => '\n📦 ${match.group(1)}\n');
    
    // ** kalın yazıları
    formatted = formatted.replaceAllMapped(RegExp(r'\*\*([^\*]+)\*\*'), (match) => match.group(1) ?? '');
    
    // * liste işaretlerini
    formatted = formatted.replaceAll(RegExp(r'^\s*\*\s+', multiLine: true), '• ');
    
    // Fazla boşlukları temizle
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return formatted.trim();
  }
}