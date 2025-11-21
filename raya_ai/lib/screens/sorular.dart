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
  final sunscreenFrequencies = [
    "Her gün",
    "Sadece yazın",
    "Nadiren",
    "Hiç kullanmam"
  ];
  final smokingOptions = ["Evet", "Hayır", "Az Miktarda", "Bıraktım"];
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
      gender = data['gender'] as String?;
      ageRange = data['age_range'] as String?;
      skinType = data['skin_type'] as String?;
      washFrequency = data['wash_frequency'] as String?;
      sunscreenFrequency = data['sunscreen_frequency'] as String?;
      smokingStatus = data['smoking_status'] as String?;
      sleepPattern = data['sleep_pattern'] as String?;
      stressLevel = data['stress_level'] as String?;

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
    setState(() => _isLoading = true);

    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Kullanıcı oturumu bulunamadı. Lütfen tekrar giriş yapın."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final skinProfileData = {
        'id': userId,
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
        'has_completed_onboarding': true,
      };

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
        Navigator.pop(context, true);
      } else {
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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isSelected = value == groupValue;

    // Arka plan rengi (Seçili değilse: Koyu modda koyu gri, açık modda açık gri)
    final Color unselectedBg = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    // Metin rengi
    final Color unselectedText = isDark ? Colors.white70 : Colors.black87;
    // Kenarlık rengi
    final Color unselectedBorder =
        isDark ? Colors.white24 : Colors.black12;

    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : unselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.pinkAccent : unselectedBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : unselectedText,
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
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color unselectedBg = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final Color unselectedText = isDark ? Colors.white70 : Colors.black87;

    return Wrap(
      spacing: 8,
      runSpacing: 8, // Chip'ler alt satıra geçince boşluk olsun
      children: options.map((label) {
        final selected = selectedList.contains(label);
        return FilterChip(
          label: Text(label),
          selected: selected,
          selectedColor: Colors.pink,
          backgroundColor: unselectedBg,
          checkmarkColor: Colors.white,
          // Kenarlık kaldırılıyor veya temaya uygun hale getiriliyor
          side: BorderSide(
            color: selected
                ? Colors.pink
                : (isDark ? Colors.white12 : Colors.black12),
          ),
          labelStyle: TextStyle(
            color: selected ? Colors.white : unselectedText,
          ),
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

  Widget _questionWrapper({
    required String question,
    required Widget child,
    VoidCallback? onNext,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color titleColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20), // Üst boşluk biraz azaltıldı
          Text(
            question,
            style: TextStyle(
              color: titleColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: isDark
                    ? Colors.grey[800]
                    : Colors.grey[300], // Buton pasifken renk
                disabledForegroundColor:
                    isDark ? Colors.white38 : Colors.black38,
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
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final totalPages = 9;

    // Alt başlıklar için renk (Yaşam tarzı sayfasındaki sorular)
    final Color subQuestionColor = isDark ? Colors.white : Colors.black87;
    final Color dividerColor = theme.dividerColor;

    return Scaffold(
      // Scaffold arka planı temadan gelir
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Üst kısım: Geri butonu + progress bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  if (_isEditMode || _currentPage > 0)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        // İkon rengi temaya göre değişir
                        color: theme.iconTheme.color ??
                            (isDark ? Colors.white : Colors.black),
                      ),
                      onPressed: () {
                        if (_isEditMode && _currentPage == 0) {
                          Navigator.pop(context, false);
                        } else {
                          _previousPage();
                        }
                      },
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                          begin: 0, end: (_currentPage + 1) / totalPages),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: value,
                            // Arka plan rengi temaya uygun
                            backgroundColor:
                                isDark ? Colors.grey[800] : Colors.grey[300],
                            color: Colors.pinkAccent,
                            minHeight: 8,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
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
                              onSelect: (val) =>
                                  setState(() => washFrequency = val),
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
                              onSelect: (val) =>
                                  setState(() => sunscreenFrequency = val),
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
                        Text("Sigara kullanıyor musunuz?",
                            style: TextStyle(
                                color: subQuestionColor, fontSize: 18)),
                        const SizedBox(height: 8),
                        Column(
                          children: smokingOptions
                              .map((option) => _buildSelectableOption<String>(
                                    value: option,
                                    groupValue: smokingStatus,
                                    label: option,
                                    onSelect: (val) =>
                                        setState(() => smokingStatus = val),
                                  ))
                              .toList(),
                        ),
                        Divider(color: dividerColor, height: 32),
                        Text("Uyku düzeniniz nasıl?",
                            style: TextStyle(
                                color: subQuestionColor, fontSize: 18)),
                        const SizedBox(height: 8),
                        Column(
                          children: sleepPatterns
                              .map((option) => _buildSelectableOption<String>(
                                    value: option,
                                    groupValue: sleepPattern,
                                    label: option,
                                    onSelect: (val) =>
                                        setState(() => sleepPattern = val),
                                  ))
                              .toList(),
                        ),
                        Divider(color: dividerColor, height: 32),
                        Text("Stres düzeyiniz?",
                            style: TextStyle(
                                color: subQuestionColor, fontSize: 18)),
                        const SizedBox(height: 8),
                        Column(
                          children: stressLevels
                              .map((option) => _buildSelectableOption<String>(
                                    value: option,
                                    groupValue: stressLevel,
                                    label: option,
                                    onSelect: (val) =>
                                        setState(() => stressLevel = val),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                    onNext: (smokingStatus != null &&
                            sleepPattern != null &&
                            stressLevel != null &&
                            !_isLoading)
                        ? _completeOnboarding
                        : null,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}