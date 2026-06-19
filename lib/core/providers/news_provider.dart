import 'package:bhitte_patro/core/models/news/news_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final newsProvider = FutureProvider<NewsResponse>((ref) async {
  final response = await http.get(Uri.parse(
      'https://raw.githubusercontent.com/gaurovgiri/newsapi/refs/heads/master/data/today.json'));
  if (response.statusCode == 200) {
    return NewsResponse.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load news');
  }
});
