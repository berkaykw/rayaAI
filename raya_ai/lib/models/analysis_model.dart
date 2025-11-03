// Yeni JSON formatına göre analiz modeli

class SkinAnalysisResult {
  final String? giris;
  final ButunculCiltAnalizi? butunculCiltAnalizi;
  final KisisellestirilmisBakimPlani? kisisellestirilmisBakimPlani;
  final MakyajRenkOnerileri? makyajRenkOnerileri;
  final OnemliNotlarIpuclari? onemliNotlarIpuclari;
  final String? kapanisNotu;

  SkinAnalysisResult({
    this.giris,
    this.butunculCiltAnalizi,
    this.kisisellestirilmisBakimPlani,
    this.makyajRenkOnerileri,
    this.onemliNotlarIpuclari,
    this.kapanisNotu,
  });

  factory SkinAnalysisResult.fromJson(Map<String, dynamic> json) {
    return SkinAnalysisResult(
      giris: json['Giris'] as String?,
      butunculCiltAnalizi: json['Butuncul_Cilt_Analizi'] != null
          ? ButunculCiltAnalizi.fromJson(json['Butuncul_Cilt_Analizi'] as Map<String, dynamic>)
          : null,
      kisisellestirilmisBakimPlani: json['Kisisellestirilmis_Bakim_Plani'] != null
          ? KisisellestirilmisBakimPlani.fromJson(json['Kisisellestirilmis_Bakim_Plani'] as Map<String, dynamic>)
          : null,
      makyajRenkOnerileri: json['Makyaj_ve_Renk_Onerileri'] != null
          ? MakyajRenkOnerileri.fromJson(json['Makyaj_ve_Renk_Onerileri'] as Map<String, dynamic>)
          : null,
      onemliNotlarIpuclari: json['Onemli_Notlar_ve_Ipuclari'] != null
          ? OnemliNotlarIpuclari.fromJson(json['Onemli_Notlar_ve_Ipuclari'] as Map<String, dynamic>)
          : null,
      kapanisNotu: json['Kapanis_Notu'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Giris': giris,
      'Butuncul_Cilt_Analizi': butunculCiltAnalizi?.toJson(),
      'Kisisellestirilmis_Bakim_Plani': kisisellestirilmisBakimPlani?.toJson(),
      'Makyaj_ve_Renk_Onerileri': makyajRenkOnerileri?.toJson(),
      'Onemli_Notlar_ve_Ipuclari': onemliNotlarIpuclari?.toJson(),
      'Kapanis_Notu': kapanisNotu,
    };
  }
}

class ButunculCiltAnalizi {
  final String? baslik;
  final GorselDegerlendirme? gorselDegerlendirme;
  final YasamTarziEtkileri? yasamTarziEtkileri;
  final MevcutRutinDegerlendirmesi? mevcutRutinDegerlendirmesi;

  ButunculCiltAnalizi({
    this.baslik,
    this.gorselDegerlendirme,
    this.yasamTarziEtkileri,
    this.mevcutRutinDegerlendirmesi,
  });

  factory ButunculCiltAnalizi.fromJson(Map<String, dynamic> json) {
    return ButunculCiltAnalizi(
      baslik: json['Baslik'] as String?,
      gorselDegerlendirme: json['Gorsel_Degerlendirme'] != null
          ? GorselDegerlendirme.fromJson(json['Gorsel_Degerlendirme'] as Map<String, dynamic>)
          : null,
      yasamTarziEtkileri: json['Yasam_Tarzi_Etkileri'] != null
          ? YasamTarziEtkileri.fromJson(json['Yasam_Tarzi_Etkileri'] as Map<String, dynamic>)
          : null,
      mevcutRutinDegerlendirmesi: json['Mevcut_Rutin_Degerlendirmesi'] != null
          ? MevcutRutinDegerlendirmesi.fromJson(json['Mevcut_Rutin_Degerlendirmesi'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Baslik': baslik,
      'Gorsel_Degerlendirme': gorselDegerlendirme?.toJson(),
      'Yasam_Tarzi_Etkileri': yasamTarziEtkileri?.toJson(),
      'Mevcut_Rutin_Degerlendirmesi': mevcutRutinDegerlendirmesi?.toJson(),
    };
  }
}

class GorselDegerlendirme {
  final String? ciltTonu;
  final String? ciltAltTonu;
  final String? tespitEdilenDurumlar;

  GorselDegerlendirme({
    this.ciltTonu,
    this.ciltAltTonu,
    this.tespitEdilenDurumlar,
  });

  factory GorselDegerlendirme.fromJson(Map<String, dynamic> json) {
    return GorselDegerlendirme(
      ciltTonu: json['Cilt_Tonu'] as String?,
      ciltAltTonu: json['Cilt_Alt_Tonu'] as String?,
      tespitEdilenDurumlar: json['Tespit_Edilen_Durumlar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Cilt_Tonu': ciltTonu,
      'Cilt_Alt_Tonu': ciltAltTonu,
      'Tespit_Edilen_Durumlar': tespitEdilenDurumlar,
    };
  }
}

class YasamTarziEtkileri {
  final String? uykuEtkisi;
  final String? sigaraVeDigerEtkiler;

  YasamTarziEtkileri({
    this.uykuEtkisi,
    this.sigaraVeDigerEtkiler,
  });

  factory YasamTarziEtkileri.fromJson(Map<String, dynamic> json) {
    return YasamTarziEtkileri(
      uykuEtkisi: json['Uyku_Etkisi'] as String?,
      sigaraVeDigerEtkiler: json['Sigara_ve_Diger_Etkiler'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Uyku_Etkisi': uykuEtkisi,
      'Sigara_ve_Diger_Etkiler': sigaraVeDigerEtkiler,
    };
  }
}

class MevcutRutinDegerlendirmesi {
  final String? ciltTipiVeTemizlikYorumu;
  final String? mevcutAdimlarVeEksikler;

  MevcutRutinDegerlendirmesi({
    this.ciltTipiVeTemizlikYorumu,
    this.mevcutAdimlarVeEksikler,
  });

  factory MevcutRutinDegerlendirmesi.fromJson(Map<String, dynamic> json) {
    return MevcutRutinDegerlendirmesi(
      ciltTipiVeTemizlikYorumu: json['Cilt_Tipi_ve_Temizlik_Yorumu'] as String?,
      mevcutAdimlarVeEksikler: json['Mevcut_Adimlar_ve_Eksikler'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Cilt_Tipi_ve_Temizlik_Yorumu': ciltTipiVeTemizlikYorumu,
      'Mevcut_Adimlar_ve_Eksikler': mevcutAdimlarVeEksikler,
    };
  }
}

class KisisellestirilmisBakimPlani {
  final String? baslik;
  final String? oncelikliHedef;
  final SabahRutini? sabahRutini;
  final AksamRutini? aksamRutini;

  KisisellestirilmisBakimPlani({
    this.baslik,
    this.oncelikliHedef,
    this.sabahRutini,
    this.aksamRutini,
  });

  factory KisisellestirilmisBakimPlani.fromJson(Map<String, dynamic> json) {
    return KisisellestirilmisBakimPlani(
      baslik: json['Baslik'] as String?,
      oncelikliHedef: json['Oncelikli_Hedef'] as String?,
      sabahRutini: json['Sabah_Rutini'] != null
          ? SabahRutini.fromJson(json['Sabah_Rutini'] as Map<String, dynamic>)
          : null,
      aksamRutini: json['Aksam_Rutini'] != null
          ? AksamRutini.fromJson(json['Aksam_Rutini'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Baslik': baslik,
      'Oncelikli_Hedef': oncelikliHedef,
      'Sabah_Rutini': sabahRutini?.toJson(),
      'Aksam_Rutini': aksamRutini?.toJson(),
    };
  }
}

class SabahRutini {
  final String? baslik;
  final String? adim1Temizleme;
  final String? adim2Serum;
  final String? adim3Nemlendirme;
  final String? adim4Koruma;

  SabahRutini({
    this.baslik,
    this.adim1Temizleme,
    this.adim2Serum,
    this.adim3Nemlendirme,
    this.adim4Koruma,
  });

  factory SabahRutini.fromJson(Map<String, dynamic> json) {
    return SabahRutini(
      baslik: json['Baslik'] as String?,
      adim1Temizleme: json['Adim_1_Temizleme'] as String?,
      adim2Serum: json['Adim_2_Serum'] as String?,
      adim3Nemlendirme: json['Adim_3_Nemlendirme'] as String?,
      adim4Koruma: json['Adim_4_Koruma'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Baslik': baslik,
      'Adim_1_Temizleme': adim1Temizleme,
      'Adim_2_Serum': adim2Serum,
      'Adim_3_Nemlendirme': adim3Nemlendirme,
      'Adim_4_Koruma': adim4Koruma,
    };
  }
}

class AksamRutini {
  final String? baslik;
  final String? adim1CiftAsamaliTemizlemeYag;
  final String? adim1CiftAsamaliTemizlemeSu;
  final String? adim2Tonik;
  final String? adim3TedaviSerumu;
  final String? adim4Nemlendirme;
  final String? ekAdimGozKremi;

  AksamRutini({
    this.baslik,
    this.adim1CiftAsamaliTemizlemeYag,
    this.adim1CiftAsamaliTemizlemeSu,
    this.adim2Tonik,
    this.adim3TedaviSerumu,
    this.adim4Nemlendirme,
    this.ekAdimGozKremi,
  });

  factory AksamRutini.fromJson(Map<String, dynamic> json) {
    return AksamRutini(
      baslik: json['Baslik'] as String?,
      adim1CiftAsamaliTemizlemeYag: json['Adim_1_Cift_Asamali_Temizleme_Yag'] as String?,
      adim1CiftAsamaliTemizlemeSu: json['Adim_1_Cift_Asamali_Temizleme_Su'] as String?,
      adim2Tonik: json['Adim_2_Tonik'] as String?,
      adim3TedaviSerumu: json['Adim_3_Tedavi_Serumu'] as String?,
      adim4Nemlendirme: json['Adim_4_Nemlendirme'] as String?,
      ekAdimGozKremi: json['Ek_Adim_Goz_Kremi'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Baslik': baslik,
      'Adim_1_Cift_Asamali_Temizleme_Yag': adim1CiftAsamaliTemizlemeYag,
      'Adim_1_Cift_Asamali_Temizleme_Su': adim1CiftAsamaliTemizlemeSu,
      'Adim_2_Tonik': adim2Tonik,
      'Adim_3_Tedavi_Serumu': adim3TedaviSerumu,
      'Adim_4_Nemlendirme': adim4Nemlendirme,
      'Ek_Adim_Goz_Kremi': ekAdimGozKremi,
    };
  }
}

class MakyajRenkOnerileri {
  final String? baslik;
  final String? altTonPaleti;
  final OnerilerErkekIcin? onerilerErkekIcin;

  MakyajRenkOnerileri({
    this.baslik,
    this.altTonPaleti,
    this.onerilerErkekIcin,
  });

  factory MakyajRenkOnerileri.fromJson(Map<String, dynamic> json) {
    return MakyajRenkOnerileri(
      baslik: json['Baslik'] as String?,
      altTonPaleti: json['Alt_Ton_Paleti'] as String?,
      onerilerErkekIcin: json['Oneriler_Erkek_Icin'] != null
          ? OnerilerErkekIcin.fromJson(json['Oneriler_Erkek_Icin'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Baslik': baslik,
      'Alt_Ton_Paleti': altTonPaleti,
      'Oneriler_Erkek_Icin': onerilerErkekIcin?.toJson(),
    };
  }
}

class OnerilerErkekIcin {
  final String? tenUrunu;
  final String? kapatici;

  OnerilerErkekIcin({
    this.tenUrunu,
    this.kapatici,
  });

  factory OnerilerErkekIcin.fromJson(Map<String, dynamic> json) {
    return OnerilerErkekIcin(
      tenUrunu: json['Ten_Urunu'] as String?,
      kapatici: json['Kapatici'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Ten_Urunu': tenUrunu,
      'Kapatici': kapatici,
    };
  }
}

class OnemliNotlarIpuclari {
  final String? baslik;
  final String? alerjilerNotu;
  final String? icerikUyarisi;
  final String? yasamTarziIpucu;

  OnemliNotlarIpuclari({
    this.baslik,
    this.alerjilerNotu,
    this.icerikUyarisi,
    this.yasamTarziIpucu,
  });

  factory OnemliNotlarIpuclari.fromJson(Map<String, dynamic> json) {
    return OnemliNotlarIpuclari(
      baslik: json['Baslik'] as String?,
      alerjilerNotu: json['Alerjiler_Notu'] as String?,
      icerikUyarisi: json['Icerik_Uyarisi'] as String?,
      yasamTarziIpucu: json['Yasam_Tarzi_Ipucu'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Baslik': baslik,
      'Alerjiler_Notu': alerjilerNotu,
      'Icerik_Uyarisi': icerikUyarisi,
      'Yasam_Tarzi_Ipucu': yasamTarziIpucu,
    };
  }
}

// Geriye dönük uyumluluk için eski AnalysisSection sınıfı
class AnalysisSection {
  final String title;
  final String content;

  AnalysisSection({required this.title, required this.content});

  factory AnalysisSection.fromJson(Map<String, dynamic> json) {
    return AnalysisSection(
      title: json['title'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}
