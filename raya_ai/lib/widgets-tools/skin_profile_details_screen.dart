import 'package:flutter/material.dart';
import 'package:raya_ai/screens/sorular.dart';
import 'package:raya_ai/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SkinProfileDetailsScreen extends StatefulWidget {
  const SkinProfileDetailsScreen({super.key});

  @override
  State<SkinProfileDetailsScreen> createState() =>
      _SkinProfileDetailsScreenState();
}

class _SkinProfileDetailsScreenState extends State<SkinProfileDetailsScreen> {
  final supabase = Supabase.instance.client;

  // Veri çekme işlemini tutacak Future
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    // Sayfa açılır açılmaz veri çekme işlemini başlat
    _profileFuture = _fetchProfileData();
  }

  /// Veritabanından kullanıcının cilt profili verilerini çeken fonksiyon
  Future<Map<String, dynamic>?> _fetchProfileData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception("Kullanıcı oturumu bulunamadı.");
    }

    try {
      final data =
          await supabase
              .from('user_skin_profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

      return data;
    } catch (e) {
      throw Exception("Veri çekilirken bir hata oluştu: $e");
    }
  }

  /// GÜNCELLENMİŞ: Düzenleme sayfasına yönlendirme ve geri dönüldüğünde yenileme
  Future<void> _navigateToEdit() async {
    // 1. Kullanıcıya bir yüklenme animasyonu göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(color: Colors.pink),
          ),
    );

    Map<String, dynamic>? currentData;
    try {
      // 2. Mevcut veriyi veritabanından çek
      currentData = await _fetchProfileData();

      if (mounted) {
        Navigator.pop(context); // Yüklenme animasyonunu kapat
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Yüklenme animasyonunu kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Veri çekilirken hata oluştu: $e")),
        );
      }
      return; // Hata varsa devam etme
    }

    if (currentData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil verisi bulunamadı.")),
        );
      }
      return; // Veri yoksa devam etme
    }

    if (!mounted) return;

    // 3. Veriyi SkinOnboardingScreen'e 'existingData' olarak yolla
    final bool? didSaveChanges = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => SkinOnboardingScreen(
              existingData: currentData, // <-- VERİYİ BURADA YOLLA
            ),
      ),
    );

    // 4. SkinOnboardingScreen'den 'true' değeriyle döndüysek
    //    (yani kullanıcı "Tamamla" butonuna bastıysa),
    //    bu sayfadaki verileri yenile.
    if (didSaveChanges == true && mounted) {
      setState(() {
        _profileFuture = _fetchProfileData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final LinearGradient backgroundGradient =
        isDark
            ? AppGradients.darkBackground
            : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDFBFF), Color(0xFFEFE8F4)],
            );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Özel Geri ve Düzenle Butonları (AppBar yerine)
              _buildCustomAppBar(theme),
              // Ana içerik
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.pink),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Hata: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final profileData = snapshot.data;
                    if (profileData == null) {
                      // Hata ekranı tasarımı da temaya uyarlandı
                      return _buildEmptyState(theme);
                    }

                    // Verileri liste yerine kartlar halinde göster
                    return _buildProfileDetailsCards(profileData, theme);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AppBar yerine özel üst kısım
  Widget _buildCustomAppBar(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color onSurface = theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Geri Butonu
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            color: onSurface.withOpacity(0.7),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // Başlık
          Text(
            "Cilt Profilim",
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          // Düzenle Butonu
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 24),
            color: onSurface.withOpacity(0.7),
            onPressed: _navigateToEdit,
          ),
        ],
      ),
    );
  }

  /// Veri bulunamadığında gösterilecek ekran
  Widget _buildEmptyState(ThemeData theme) {
    final Color onSurface = theme.colorScheme.onSurface;
    final Color secondary =
        theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
        onSurface.withOpacity(0.7);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.tertiary,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              "Cilt profili veriniz bulunamadı.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: onSurface,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Lütfen profil anketini tamamladığınızdan emin olun.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Verileri gruplanmış kartlar olarak gösteren Widget
  Widget _buildProfileDetailsCards(Map<String, dynamic> data, ThemeData theme) {
    // List<dynamic> olanları List<String>'e çevir ve birleştir
    String formatList(List? list) {
      if (list == null || list.isEmpty) return "Yok";
      // .cast<String>() yerine .map kullanmak daha güvenli
      return list.map((item) => item.toString()).join(', ');
    }

    final skinProblems = formatList(data['skin_problems'] as List?);
    final allergies = formatList(data['allergies'] as List?);
    final routineSteps = formatList(data['routine_steps'] as List?);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          _buildInfoCard("Temel Bilgiler", [
            MapEntry("Cilt Tipi", data['skin_type'] as String?),
            MapEntry("Yaş Aralığı", data['age_range'] as String?),
            MapEntry("Cinsiyet", data['gender'] as String?),
          ], theme),
          _buildInfoCard("Cilt Detayları", [
            MapEntry("Cilt Sorunları", skinProblems),
            MapEntry("Alerjiler", allergies),
            MapEntry("Rutin Adımları", routineSteps),
          ], theme),
          _buildInfoCard("Yaşam Tarzı", [
            MapEntry("Yıkama Sıklığı", data['wash_frequency'] as String?),
            MapEntry("Güneş Kremi", data['sunscreen_frequency'] as String?),
            MapEntry("Sigara Durumu", data['smoking_status'] as String?),
            MapEntry("Uyku Düzeni", data['sleep_pattern'] as String?),
            MapEntry("Stres Seviyesi", data['stress_level'] as String?),
          ], theme),
        ],
      ),
    );
  }

  /// ProfileScreen'deki gibi bir bilgi kartı Widget'ı
  Widget _buildInfoCard(
    String title,
    List<MapEntry<String, String?>> items,
    ThemeData theme,
  ) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor =
        isDark ? Colors.white.withOpacity(0.05) : theme.colorScheme.surface;
    final Color borderColor =
        isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(
            color: theme.dividerColor.withOpacity(0.2),
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          // Bilgi satırlarını oluştur
          ListView.separated(
            physics:
                const NeverScrollableScrollPhysics(), // İç içe scroll'u engelle
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildDetailRow(item.key, item.value, theme);
            },
            separatorBuilder: (context, index) {
              // Satırlar arasına ince bir ayırıcı
              return Divider(
                color: theme.dividerColor.withOpacity(0.15),
                height: 1,
                indent: 20,
              );
            },
          ),
        ],
      ),
    );
  }

  /// (Kart içine girmesi için Dividersız)
  Widget _buildDetailRow(String title, String? value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value ?? "Belirtilmemiş",
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
