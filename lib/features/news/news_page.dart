import 'dart:math';
import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/providers/news_provider.dart';
import 'package:bhitte_patro/core/router/route_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsyncValue = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: newsAsyncValue.when(
          data: (news) {
            if (news.articles.isEmpty) return const Center(child: Text("No news available"));

            // Create a copy and shuffle the articles
            final shuffledArticles = List.from(news.articles)..shuffle(Random());
            final heroArticle = shuffledArticles.first;
            final otherArticles = shuffledArticles.skip(1).toList();

            return RefreshIndicator(
              onRefresh: () async {
                return ref.refresh(newsProvider);
              },
              color: AppColors.darkBlue,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // Hero Section
                  InkWell(
                    onTap: () => context.push(RoutePage.newsDetail,
                        extra: {'url': heroArticle.sourceUrl, 'title': heroArticle.source}),
                    child: _buildHeroArticle(heroArticle),
                  ),
                  const SizedBox(height: 24),
                  const Divider(thickness: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),
                  const Text("Latest",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black)),
                  const SizedBox(height: 16),
                  // List Section
                  ...otherArticles.map((article) => Column(
                        children: [
                          InkWell(
                              onTap: () => context.push(RoutePage.newsDetail,
                                  extra: {'url': article.sourceUrl, 'title': article.source}),
                              child: _buildArticleItem(article)),
                          const Divider(thickness: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 16),
                        ],
                      )),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkBlue)),
          error: (err, stack) => Center(child: Text('Error: $err', style: AppTypography.body)),
        ),
      ),
    );
  }

  Widget _buildHeroArticle(dynamic article) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: article.imageUrl.isNotEmpty
              ? Image.network(article.imageUrl, width: double.infinity, height: 200, fit: BoxFit.cover)
              : Container(height: 200, color: const Color(0xFFF1F5F9)),
        ),
        const SizedBox(height: 16),
        Text(article.source.toUpperCase(), style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(article.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
      ],
    );
  }

  Widget _buildArticleItem(dynamic article) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.source, style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                Text(article.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: article.imageUrl.isNotEmpty
                ? Image.network(article.imageUrl, width: 100, height: 70, fit: BoxFit.cover)
                : Container(width: 100, height: 70, color: const Color(0xFFF1F5F9)),
          ),
        ],
      ),
    );
  }
}
