import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:raya_ai/screens/profilepage_screen.dart';
import 'package:raya_ai/widgets-tools/full_screen_image_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            child: const Text('Sil', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
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

    // Remove first item that matches timestamp (unique per save)
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
                          return _AnalysisTile(entry: entry, onDelete: () => _deleteEntry(entry));
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
  const _AnalysisTile({required this.entry, required this.onDelete});

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
        onTap: () {
          Navigator.push(
            (context),
            MaterialPageRoute(
              builder: (context) => _AnalysisDetailPage(entry: entry),
            ),
          );
        },
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
                      '${entry.sections.length} bölüm',
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

// ❌ SİLİNDİ: Eski _SectionCard widget'ı buradan kaldırıldı.

class _LocalAnalysisEntry {
  final String timestamp;
  final String? imagePath;
  final String? imageUrl;
  final List<_LocalSection> sections;

  _LocalAnalysisEntry(
      {required this.timestamp, this.imagePath, this.imageUrl, required this.sections});

  factory _LocalAnalysisEntry.fromJson(Map<String, dynamic> json) {
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

class _AnalysisDetailPage extends StatelessWidget {
  final _LocalAnalysisEntry entry;
  const _AnalysisDetailPage({required this.entry});

  // ✅ YENİ: Icon helper fonksiyonu buraya eklendi
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

  // ✅ YENİ: Yeni kart tasarımı fonksiyonu buraya eklendi
  // ℹ️ DEĞİŞTİRİLDİ: Parametresi `_LocalSection` olarak güncellendi
  Widget _buildAnalysisCard(_LocalSection section) {
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
                                _getIconForSection(section.title), // ℹ️ Değişiklik
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
                                    section.title, // ℹ️ Değişiklik
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
                            section.content, // ℹ️ Değişiklik
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
                  // Image first (tap to open full screen viewer)
                  if (entry.imagePath != null && entry.imagePath!.isNotEmpty && File(entry.imagePath!).existsSync())
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imagePath: entry.imagePath!,
                              isLocalFile: true,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Hero(
                          tag: entry.imagePath!,
                          child: Image.file(
                            File(entry.imagePath!),
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  else if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imageUrl: entry.imageUrl!,
                              isLocalFile: false,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Hero(
                          tag: entry.imageUrl!,
                          child: Image.network(
                            entry.imageUrl!,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // ✅ DEĞİŞTİRİLDİ: Eski kart listesi yeni fonksiyonla değiştirildi
                  ...entry.sections.map((s) => _buildAnalysisCard(s)).toList(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}