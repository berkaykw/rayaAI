import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../models/analysis_model.dart';

class ApiService {
  final String _webhookUrl = 'https://n8n.barancaki.me/webhook/image-input';
  
  // ImgBB API Key - imgbb.com'dan ücretsiz alabilirsiniz
  final String _imgbbApiKey = 'f7d35cc3ba4d440c5d85bb9e1a38faed';

  /// Galeriden seçilen resmi ImgBB'ye yükler ve URL döner
  Future<String> uploadImageToImgBB(File imageFile) async {
    try {
      // Resmi base64'e çevir
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // ImgBB'ye POST isteği gönder
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': _imgbbApiKey,
          'image': base64Image,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // ImgBB'den dönen resim URL'sini al
        return data['data']['url'];
      } else {
        throw Exception('Resim yüklenemedi: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Resim yükleme zaman aşımına uğradı.');
    } catch (e) {
      throw Exception('Resim yüklenirken hata oluştu: $e');
    }
  }

  /// Resim URL'sini analiz eder
  Future<List<AnalysisSection>> analyzeImageUrl(String imageUrl) async {
    final body = jsonEncode({'imageUrl': imageUrl});

    try {
      final response = await http
          .post(
            Uri.parse(_webhookUrl),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: body,
          )
          .timeout(const Duration(seconds: 500));

      if (response.statusCode == 200) {
        final List<dynamic> decodedBody = jsonDecode(response.body);
        final Map<String, dynamic> outputMap = decodedBody[0]['output'];

        return outputMap.entries
            .map((entry) => AnalysisSection(
                title: entry.key, content: entry.value.toString()))
            .toList();
      } else {
        throw Exception('API Hatası: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Sunucudan yanıt alınamadı (Zaman aşımı).');
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }

  /// Galeriden seçilen resmi yükleyip analiz eder (tek fonksiyon)
  Future<List<AnalysisSection>> analyzeImageFromGallery(File imageFile) async {
    // 1. Önce resmi ImgBB'ye yükle
    final imageUrl = await uploadImageToImgBB(imageFile);
    
    // 2. Dönen URL ile analiz yap
    return await analyzeImageUrl(imageUrl);
  }
}