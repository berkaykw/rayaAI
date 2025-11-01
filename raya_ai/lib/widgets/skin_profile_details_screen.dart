import 'package:flutter/material.dart';
import 'package:raya_ai/screens/sorular.dart';
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
      final data = await supabase
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
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.pink)),
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
        builder: (context) => SkinOnboardingScreen(
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
    return Scaffold(
      body: Container(
        // ProfileScreen ile aynı arkaplan gradient'ı
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[900]!, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Özel Geri ve Düzenle Butonları (AppBar yerine)
              _buildCustomAppBar(),
              // Ana içerik
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.pink));
                    }

                    if (snapshot.hasError) {
                      return Center(
                          child: Text(
                        "Hata: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ));
                    }

                    final profileData = snapshot.data;
                    if (profileData == null) {
                      // Hata ekranı tasarımı da koyu temaya uyarlandı
                      return _buildEmptyState();
                    }

                    // Verileri liste yerine kartlar halinde göster
                    return _buildProfileDetailsCards(profileData);
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
  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Geri Butonu
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white70, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // Başlık
          const Text(
            "Cilt Profilim",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Düzenle Butonu
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Colors.white70, size: 24),
            onPressed: _navigateToEdit,
          ),
        ],
      ),
    );
  }

  /// Veri bulunamadığında gösterilecek ekran
  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.yellowAccent, size: 60),
            SizedBox(height: 16),
            Text(
              "Cilt profili veriniz bulunamadı.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              "Lütfen profil anketini tamamladığınızdan emin olun.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Verileri gruplanmış kartlar olarak gösteren Widget
  Widget _buildProfileDetailsCards(Map<String, dynamic> data) {
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
          _buildInfoCard(
            "Temel Bilgiler",
            [
              MapEntry("Cilt Tipi", data['skin_type'] as String?),
              MapEntry("Yaş Aralığı", data['age_range'] as String?),
              MapEntry("Cinsiyet", data['gender'] as String?),
            ],
          ),
          _buildInfoCard(
            "Cilt Detayları",
            [
              MapEntry("Cilt Sorunları", skinProblems),
              MapEntry("Alerjiler", allergies),
              MapEntry("Rutin Adımları", routineSteps),
            ],
          ),
          _buildInfoCard(
            "Yaşam Tarzı",
            [
              MapEntry("Yıkama Sıklığı", data['wash_frequency'] as String?),
              MapEntry("Güneş Kremi", data['sunscreen_frequency'] as String?),
              MapEntry("Sigara Durumu", data['smoking_status'] as String?),
              MapEntry("Uyku Düzeni", data['sleep_pattern'] as String?),
              MapEntry("Stres Seviyesi", data['stress_level'] as String?),
            ],
          ),
        ],
      ),
    );
  }

  /// ProfileScreen'deki gibi bir bilgi kartı Widget'ı
  Widget _buildInfoCard(String title, List<MapEntry<String, String?>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.pinkAccent, // Vurgu rengi
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1, indent: 20, endIndent: 20),
          // Bilgi satırlarını oluştur
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(), // İç içe scroll'u engelle
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildDetailRow(item.key, item.value);
            },
            separatorBuilder: (context, index) {
              // Satırlar arasına ince bir ayırıcı
              return const Divider(color: Colors.white24, height: 1, indent: 20);
            },
          ),
        ],
      ),
    );
  }

  /// (Kart içine girmesi için Dividersız)
  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value ?? "Belirtilmemiş",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}