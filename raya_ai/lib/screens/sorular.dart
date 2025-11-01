import 'package:flutter/material.dart';
import 'package:raya_ai/screens/analysis_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SkinOnboardingScreen extends StatefulWidget {
  final Map<String, dynamic>? existingData;

  const SkinOnboardingScreen({
    super.key,
    this.existingData,
  });

  @override
  State<SkinOnboardingScreen> createState() => _SkinOnboardingScreenState();
}

class _SkinOnboardingScreenState extends State<SkinOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  bool _isEditMode = false;

  final supabase = Supabase.instance.client;

  String? gender;
  String? ageRange;
  String? skinType;
  List<String> skinProblems = [];
  List<String> allergies = [];
  String? washFrequency;
  List<String> routineSteps = [];
  String? sunscreenFrequency;
  String? smokingStatus;
  String? sleepPattern;
  String? stressLevel;

  final ageRanges = ["18 - 24", "25 - 34", "35 - 44", "45 - 54", "55+"];
  final skinTypes = [
    "Normal",
    "Kuru",
    "Yağlı",
    "Karma (T bölgesi yağlı, yanaklar kuru)",
    "Hassas",
    "Emin değilim / Bilmiyorum",
  ];
  final skinProblemsList = [
    "Akne / sivilce",
    "Siyah nokta",
    "Geniş gözenek",
    "Kızarıklık / Rozasea",
    "Pigmentasyon / Lekeler",
    "Göz altı morluğu",
    "İnce çizgiler / kırışıklık",
    "Egzama",
    "Pullanma / kuruluk",
    "Seboreik dermatit",
    "Alerjik reaksiyonlar",
    "Hiçbiri",
  ];
  final allergiesList = [
    "Parfüm / kokuya karşı hassasiyet",
    "Alkol bazlı ürünlere tepki",
    "Sülfatlara karşı alerji",
    "Parabenlere alerji",
    "Renklendirici katkılara alerji",
    "Güneş kremine tepki",
    "Kozmetik ürünlere genel hassasiyet",
    "Yok",
  ];
  final washFrequencies = [
    "Sabah / Akşam (2 kez)",
    "Sadece akşam",
    "Sadece sabah",
    "Çok nadiren",
  ];
  final routineStepsList = [
    "Temizleyici",
    "Tonik",
    "Serum",
    "Nemlendirici",
    "Güneş kremi",
    "Maske (haftalık)",
    "Kimyasal peeling (AHA/BHA vb.)",
    "Makyaj temizleyici",
    "Hiçbiri / bilmiyorum",
  ];
  final sunscreenFrequencies = ["Her gün", "Sadece yazın", "Nadiren", "Hiç kullanmam"];
  final smokingOptions = ["Evet", "Hayır","Az Miktarda", "Bıraktım"];
  final sleepPatterns = ["Her gün 7+ saat", "Düzensiz", "Genellikle az uyurum"];
  final stressLevels = ["Düşük", "Orta", "Yüksek"];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _isEditMode = true;
      _loadExistingData(widget.existingData!);
    }
  }

  void _loadExistingData(Map<String, dynamic> data) {
    setState(() {
      // Tip dönüşümlerine dikkat ederek verileri ata
      gender = data['gender'] as String?;
      ageRange = data['age_range'] as String?;
      skinType = data['skin_type'] as String?;
      washFrequency = data['wash_frequency'] as String?;
      sunscreenFrequency = data['sunscreen_frequency'] as String?;
      smokingStatus = data['smoking_status'] as String?;
      sleepPattern = data['sleep_pattern'] as String?;
      stressLevel = data['stress_level'] as String?;

      // Veritabanından List<dynamic> olarak gelen verileri List<String>'e çevir
      skinProblems = (data['skin_problems'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          [];

      allergies = (data['allergies'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          [];

      routineSteps = (data['routine_steps'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          [];
    });
  }

  void _nextPage() {
    if (_currentPage < 8) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _completeOnboarding() async {
  // Butonu devre dışı bırak ve yükleniyor animasyonu göster
  setState(() => _isLoading = true); 

  // 1. Mevcut giriş yapmış kullanıcının ID'sini al
  // Bu ID, bizim SQL tablomuzdaki 'id' sütununa karşılık gelecek.
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    // Kullanıcı bir şekilde çıkış yapmışsa işlemi durdur
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın."),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
    return;
  }

  try {
    // 2. Toplanan tüm verileri bir map'e koy 
    final skinProfileData = {
      'id': userId, // <-- EN ÖNEMLİSİ: Kullanıcı ID'sini ekle
      'gender': gender, 
      'age_range': ageRange, 
      'skin_type': skinType, 
      'skin_problems': skinProblems, 
      'allergies': allergies, 
      'wash_frequency': washFrequency, 
      'routine_steps': routineSteps, 
      'sunscreen_frequency': sunscreenFrequency, 
      'smoking_status': smokingStatus, 
      'sleep_pattern': sleepPattern, 
      'stress_level': stressLevel, 
      'has_completed_onboarding': true, // <-- Bayrağı da buraya ekliyoruz
    };

    // 3. Supabase 'user_skin_profiles' tablosuna 'upsert' yap
    // 'upsert', eğer bu ID'ye sahip bir kayıt varsa günceller, yoksa yeni kayıt ekler.
    // Bu, kullanıcının bilgilerini daha sonra değiştirmesine de olanak tanır.
    await supabase.from('user_skin_profiles').upsert(skinProfileData);

    await supabase.auth.updateUser(
      UserAttributes(
        data: {
          'has_completed_onboarding': true,
        },
      ),
    );
    
    if (!mounted) return; 

    if (_isEditMode) {
        // Eğer düzenleme modundaysa, bir önceki sayfaya (Profile)
        // 'true' sonucuyla dön. (Kaydettiğini bilsin)
        Navigator.pop(context, true); // <-- 'true' DÖNDÜR
      } else {
        // Yeni kullanıcıysa, Ana Ekrana yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AnalysisScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profil kaydedilirken hata oluştu: $e"), 
          backgroundColor: Colors.red, 
        ),
      );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

 Widget _buildSelectableOption<T>({
  required T value,
  required T? groupValue,
  required String label,
  required void Function(T) onSelect,
}) {
  final bool isSelected = value == groupValue;

  return GestureDetector(
    onTap: () => onSelect(value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.pink : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.pinkAccent : Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          AnimatedOpacity(
            opacity: isSelected ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.check_circle, color: Colors.white),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildChipGroup(List<String> options, List<String> selectedList) {
    return Wrap(
      spacing: 8,
      children: options.map((label) {
        final selected = selectedList.contains(label);
        return FilterChip(
          label: Text(label),
          selected: selected,
          selectedColor: Colors.pink,
          backgroundColor: Colors.grey[800],
          labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
          onSelected: (val) {
            setState(() {
              if (val) {
                selectedList.add(label);
              } else {
                selectedList.remove(label);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = 9;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Üst kısım: Geri butonu + progress bar
            Row(
              children: [
                if (_isEditMode || _currentPage > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      if (_isEditMode && _currentPage == 0) {
                        // Düzenleme modunda ve ilk sayfadaysa, kaydetmeden çık
                        Navigator.pop(context, false); // <-- 'false' DÖNDÜR
                      } else {
                        // Diğer durumlarda bir önceki soruya git
                        _previousPage();
                      }
                    },
                  )
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: TweenAnimationBuilder<double>(
  tween: Tween<double>(begin: 0, end: (_currentPage + 1) / totalPages),
  duration: const Duration(milliseconds: 400),
  builder: (context, value, child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.grey[800],
        color: Colors.pinkAccent,
        minHeight: 8,
      ),
    );
  },
)
                ),
                const SizedBox(width: 48),
              ],
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Cinsiyet
                  _questionWrapper(
                    question: "Cinsiyetinizi Seçin",
                    child: Column(
                      children: ["Kadın", "Erkek", "Belirtmek istemiyorum"]
                          .map(
                            (option) => _buildSelectableOption<String>(
                              value: option,
                              groupValue: gender,
                              label: option,
                              onSelect: (val) => setState(() => gender = val),
                            ),
                          )
                          .toList(),
                    ),
                    onNext: gender != null ? _nextPage : null,
                  ),
                  // Yaş
                  _questionWrapper(
                    question: "Yaş Aralığınızı Seçin",
                    child: Column(
                      children: ageRanges
                          .map(
                            (option) => _buildSelectableOption<String>(
                              value: option,
                              groupValue: ageRange,
                              label: option,
                              onSelect: (val) => setState(() => ageRange = val),
                            ),
                          )
                          .toList(),
                    ),
                    onNext: ageRange != null ? _nextPage : null,
                  ),
                  // Cilt Tipi
                  _questionWrapper(
                    question: "Cilt Tipinizi Seçin",
                    child: Column(
                      children: skinTypes
                          .map(
                            (option) => _buildSelectableOption<String>(
                              value: option,
                              groupValue: skinType,
                              label: option,
                              onSelect: (val) => setState(() => skinType = val),
                            ),
                          )
                          .toList(),
                    ),
                    onNext: skinType != null ? _nextPage : null,
                  ),
                  // Cilt Problemleri
                  _questionWrapper(
                    question: "Cilt Problemleriniz Var mı?",
                    child: _buildChipGroup(skinProblemsList, skinProblems),
                    onNext: skinProblems.isNotEmpty ? _nextPage : null,
                  ),
                  // Alerjiler
                  _questionWrapper(
                    question: "Alerjileriniz veya hassasiyetleriniz var mı?",
                    child: _buildChipGroup(allergiesList, allergies),
                    onNext: allergies.isNotEmpty ? _nextPage : null,
                  ),
                  // Yıkama Sıklığı
                  _questionWrapper(
                    question: "Günde kaç kez yüzünüzü yıkarsınız?",
                    child: Column(
                      children: washFrequencies
                          .map(
                            (option) => _buildSelectableOption<String>(
                              value: option,
                              groupValue: washFrequency,
                              label: option,
                              onSelect: (val) => setState(() => washFrequency = val),
                            ),
                          )
                          .toList(),
                    ),
                    onNext: washFrequency != null ? _nextPage : null,
                  ),
                  // Rutin Adımları
                  _questionWrapper(
                    question: "Cilt bakım rutininizde hangi adımlar var?",
                    child: _buildChipGroup(routineStepsList, routineSteps),
                    onNext: routineSteps.isNotEmpty ? _nextPage : null,
                  ),
                  // Güneş kremi
                  _questionWrapper(
                    question: "Güneş koruyucu kullanım sıklığınız?",
                    child: Column(
                      children: sunscreenFrequencies
                          .map(
                            (option) => _buildSelectableOption<String>(
                              value: option,
                              groupValue: sunscreenFrequency,
                              label: option,
                              onSelect: (val) => setState(() => sunscreenFrequency = val),
                            ),
                          )
                          .toList(),
                    ),
                    onNext: sunscreenFrequency != null ? _nextPage : null,
                  ),
                  // Yaşam Tarzı
                  _questionWrapper(
                    question: "Yaşam Tarzı Faktörleri",
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const Text("Sigara kullanıyor musunuz?", style: TextStyle(color: Colors.white, fontSize: 18)),
                        Column(
                          children: smokingOptions
                              .map((option) => _buildSelectableOption<String>(
                                    value: option,
                                    groupValue: smokingStatus,
                                    label: option,
                                    onSelect: (val) => setState(() => smokingStatus = val),
                                  ))
                              .toList(),
                        ),
                        const Divider(color: Colors.white24),
                        const Text("Uyku düzeniniz nasıl?", style: TextStyle(color: Colors.white, fontSize: 18)),
                        Column(
                          children: sleepPatterns
                              .map((option) => _buildSelectableOption<String>(
                                    value: option,
                                    groupValue: sleepPattern,
                                    label: option,
                                    onSelect: (val) => setState(() => sleepPattern = val),
                                  ))
                              .toList(),
                        ),
                        const Divider(color: Colors.white24),
                        const Text("Stres düzeyiniz?", style: TextStyle(color: Colors.white, fontSize: 18)),
                        Column(
                          children: stressLevels
                              .map((option) => _buildSelectableOption<String>(
                                    value: option,
                                    groupValue: stressLevel,
                                    label: option,
                                    onSelect: (val) => setState(() => stressLevel = val),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                    onNext: (smokingStatus != null &&
                            sleepPattern != null &&
                            stressLevel != null &&
                            !_isLoading) // Yükleniyorsa tekrar basılmasın
                        ? _completeOnboarding // <-- Yeni fonksiyonumuzu çağır
                        : null,
                    isLoading: _isLoading, // <-- Yükleniyor durumunu widget'a ilet
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionWrapper({
    required String question,
    required Widget child,
    VoidCallback? onNext,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            question,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(child: SingleChildScrollView(child: child)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      _currentPage == 8 ? "Tamamla" : "İleri",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
