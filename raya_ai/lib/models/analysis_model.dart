class AnalysisSection {
  final String title;
  final String content;

  AnalysisSection({required this.title, required this.content});

  // JSON'dan AnalysisSection oluşturmak için
  factory AnalysisSection.fromJson(Map<String, dynamic> json) {
    return AnalysisSection(
      title: json['title'],
      content: json['content'],
    );
  }

  // AnalysisSection'u JSON formatına çevirmek için
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}
