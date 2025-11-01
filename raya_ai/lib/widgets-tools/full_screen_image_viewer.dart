import 'dart:io';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String? imagePath;      // Artık imagePath ve imageUrl olarak ayrıldı
  final String? imageUrl;
  final bool isLocalFile;       // Hangisinin gösterileceğini belirler

  const FullScreenImageViewer({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.isLocalFile = false,
  }) : assert(isLocalFile ? imagePath != null : imageUrl != null); // Hata kontrolü

  @override
  Widget build(BuildContext context) {
    // Hero tag için benzersiz bir değer oluştur
    final String heroTag = isLocalFile ? imagePath! : imageUrl!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Hero(
                tag: heroTag,
                child: isLocalFile
                    ? Image.file(File(imagePath!))   // Yerel dosyayı göster
                    : Image.network(imageUrl!),      // İnternet URL'sini göster
              ),
            ),
          ),

          // 🔙 Sol üstte geri butonu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Geri',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
