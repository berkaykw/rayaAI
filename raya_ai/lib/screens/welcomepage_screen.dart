import 'dart:ui'; // ImageFiltered için gerekli
import 'package:flutter/material.dart';
import 'package:raya_ai/screens/loginpage_screen.dart';

// Tasarımda kullanılan renkleri sabit olarak tanımlayalım
const Color primaryColor = Color(0xFFEC1380);
const Color backgroundDarkColor = Color(0xFF221019);
const Color textColor = Color(0xFFD4D4D8); // Tailwind'deki zinc-300 rengine yakın

class WelcomepageScreen extends StatefulWidget {
  const WelcomepageScreen({super.key});

  @override
  State<WelcomepageScreen> createState() => _WelcomepageScreenState();
}

class _WelcomepageScreenState extends State<WelcomepageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDarkColor,
      body: Stack(
        // Stack, widget'ları üst üste koymamızı sağlar
        children: [
          // Arka plandaki bulanık daireler
          _buildBlurredBlobs(),

          // Ortalanmış ana içerik
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Başlık: "Cilt Analizi"
                  const Text(
                    'Cildinizi Keşfedin',
                    style: TextStyle(
                      fontFamily: 'Inter', // Manuel eklenen font ailesi
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

                  // Açıklama metni
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 320), // max-w-sm
                    child: Text(
                      'Cilt sağlığınızı analiz etmek ve kişiselleştirilmiş öneriler almak için bir fotoğraf yükleyin veya çekin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter', // Manuel eklenen font ailesi
                        fontSize: 16,
                        color: textColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // "Başla" düğmesi
                  _buildStartButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Arka plandaki bulanık renk damlalarını oluşturan widget.
  Widget _buildBlurredBlobs() {
    // State class içinde olduğumuz için 'context'e doğrudan erişebiliriz.
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

  /// Belirtilen boyut ve renkte bulanık bir daire oluşturan yardımcı widget.
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

  /// Tasarıma uygun stillendirilmiş "Başla" düğmesini oluşturan widget.
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
            fontFamily: 'Inter', // Manuel eklenen font ailesi
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}