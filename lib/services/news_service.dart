/// One news item for the list on Home.
class NewsItem {
  final String category;
  final String title;
  final String source;
  final String age;
  final String url;

  const NewsItem({required this.category, required this.title, required this.source, required this.age, this.url = ''});
}

/// Source of the news. Later a server loads the news from a news API, stores them
/// and every app reads them from there. Until then this placeholder is used.
abstract class NewsSource {
  Future<List<NewsItem>> latest();
}

/// Fixed placeholder items. Marked as placeholder in the UI.
class PlaceholderNewsSource implements NewsSource {
  const PlaceholderNewsSource();

  @override
  Future<List<NewsItem>> latest() async {
    return const <NewsItem>[
      NewsItem(category: 'Training', title: 'Platzhalter: Wie viele Sätze pro Woche?', source: 'Beispielquelle', age: 'vor 2 Std.'),
      NewsItem(category: 'Ernährung', title: 'Platzhalter: Eiweiß über den Tag verteilen', source: 'Beispielquelle', age: 'vor 5 Std.'),
      NewsItem(category: 'Regeneration', title: 'Platzhalter: Schlaf und Muskelaufbau', source: 'Beispielquelle', age: 'gestern'),
      NewsItem(category: 'Forschung', title: 'Platzhalter: Kurze oder lange Pausen?', source: 'Beispielquelle', age: 'gestern'),
      NewsItem(category: 'Training', title: 'Platzhalter: Mobilität für Schreibtischtage', source: 'Beispielquelle', age: 'vor 2 Tagen'),
    ];
  }
}

const NewsSource newsSource = PlaceholderNewsSource();
