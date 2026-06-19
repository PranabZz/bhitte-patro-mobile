class Article {
  final String title;
  final String summary;
  final String source;
  final String language;
  final String sourceUrl;
  final String imageUrl;

  Article({
    required this.title,
    required this.summary,
    required this.source,
    required this.language,
    required this.sourceUrl,
    required this.imageUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      source: json['source'] ?? '',
      language: json['language'] ?? '',
      sourceUrl: json['source_url'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class NewsResponse {
  final DateTime scrapedAt;
  final String date;
  final int totalArticles;
  final List<String> sources;
  final List<Article> articles;

  NewsResponse({
    required this.scrapedAt,
    required this.date,
    required this.totalArticles,
    required this.sources,
    required this.articles,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      scrapedAt: DateTime.parse(json['scraped_at']),
      date: json['date'],
      totalArticles: json['total_articles'],
      sources: List<String>.from(json['sources']),
      articles: List<Article>.from(
        json['articles'].map((x) => Article.fromJson(x)),
      ),
    );
  }
}
