import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:raya_ai/screens/loginpage_screen.dart';
import 'package:raya_ai/screens/analysis_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color primaryColor = Color(0xFFEC1380);
const Color backgroundDarkColor = Color(0xFF221019);
const Color textColor = Color(0xFFD4D4D8);

class WelcomepageScreen extends StatefulWidget {
  const WelcomepageScreen({super.key});

  @override
  State<WelcomepageScreen> createState() => _WelcomepageScreenState();
}

class _WelcomepageScreenState extends State<WelcomepageScreen> {
  bool _checkingSession = true; // ✅ kontrol yapılıyor mu?

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('rememberMe') ?? false;

    final session = supabase.auth.currentSession;

    if (remember && session != null) {
      // ✅ Giriş yapılmış → direkt AnalysisScreen'e yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AnalysisScreen()),
      );
    } else {
      // ⏳ Kontrol bitti → Welcome ekranı göster
      setState(() {
        _checkingSession = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDarkColor,
      body: Stack(
        children: [
          _buildBlurredBlobs(),

          // Eğer kontrol yapılıyorsa loading spinner göster
          if (_checkingSession)
            const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Cildinizi Keşfedin',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black38,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: const Text(
                        'Cilt sağlığınızı analiz etmek ve kişiselleştirilmiş öneriler almak için bir fotoğraf yükleyin veya çekin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildStartButton(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlurredBlobs() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Positioned(
          top: -screenHeight * 0.10,
          left: -screenWidth * 0.20,
          child: _buildBlurCircle(
            size: 288,
            color: primaryColor.withOpacity(0.4),
          ),
        ),
        Positioned(
          bottom: -screenHeight * 0.15,
          right: -screenWidth * 0.25,
          child: _buildBlurCircle(
            size: 320,
            color: primaryColor.withOpacity(0.28),
          ),
        ),
      ],
    );
  }

  Widget _buildBlurCircle({required double size, required Color color}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginpageScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          elevation: 0,
        ),
        child: const Text(
          'Başla',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
