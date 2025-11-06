import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../models/analysis_model.dart';

class ApiService {
  final String _webhookUrl = 'https://n8n.barancaki.me/webhook/image-input';
  final String _imgbbApiKey = 'f7d35cc3ba4d440c5d85bb9e1a38faed';

  /// Galeriden seçilen resmi ImgBB'ye yükler ve URL döner
  Future<String> uploadImageToImgBB(File imageFile) async {
    // ... (Bu fonksiyonda değişiklik yok)
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': _imgbbApiKey,
          'image': base64Image,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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

  /// Resim URL'sini, kullanıcı ID'sini ve ürün tercihlerini analiz eder
  Future<SkinAnalysisResult> analyzeImageUrl(
    String imageUrl,
    String userId,
    bool includeProducts, // <-- YENİ PARAMETRE
    int productCount,     // <-- YENİ PARAMETRE
  ) async {
    
    // <-- YENİ: Gövdeye tüm parametreler eklendi
    final body = jsonEncode({
      'imageUrl': imageUrl,
      'userId': userId,
      'includeProducts': includeProducts, // Ürün önerisi istiyor mu?
      'productCount': productCount,       // Kaç adet istiyor?
    });

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
        
        // Yeni format: [{"output_urun": "...", "output_analiz": {...}}]
        if (decodedBody.isNotEmpty) {
          final Map<String, dynamic> responseData = decodedBody[0] as Map<String, dynamic>;
          
          // output_analiz içindeki veriyi al ve output_urun'u de ekle
          if (responseData['output_analiz'] != null) {
            final Map<String, dynamic> analizData = responseData['output_analiz'] as Map<String, dynamic>;
            // output_urun'u analizData'ya ekle
            analizData['output_urun'] = responseData['output_urun'] as String?;
            return SkinAnalysisResult.fromJson(analizData);
          } else if (responseData['output'] != null) {
            // Eski format desteği (geriye dönük uyumluluk)
            final Map<String, dynamic> outputData = responseData['output'] as Map<String, dynamic>;
            if (outputData['output'] != null) {
              final Map<String, dynamic> innerOutput = outputData['output'] as Map<String, dynamic>;
              return SkinAnalysisResult.fromJson(innerOutput);
            } else {
              return SkinAnalysisResult.fromJson(outputData);
            }
          } else {
            throw Exception('API yanıt formatı beklenmedik şekilde.');
          }
        } else {
          throw Exception('API yanıt formatı beklenmedik şekilde.');
        }
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
  Future<SkinAnalysisResult> analyzeImageFromGallery(
    File imageFile,
    String userId,
    bool includeProducts, // <-- YENİ PARAMETRE
    int productCount,     // <-- YENİ PARAMETRE
  ) async {
    
    // 1. Önce resmi ImgBB'ye yükle
    final imageUrl = await uploadImageToImgBB(imageFile);

    // 2. Dönen URL ve TÜM parametreler ile analiz yap
    return await analyzeImageUrl(
      imageUrl,
      userId,
      includeProducts, // <-- YENİ
      productCount,    // <-- YENİ
    );
  }
}