import 'dart:math';
import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/models/gold_silver/gold_silver_model.dart';
import 'package:bhitte_patro/core/providers/gold_silver_price_provider.dart';
import 'package:bhitte_patro/core/providers/news_provider.dart';
import 'package:bhitte_patro/core/router/route_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis/areainsights/v1.dart';

class NewsPage extends ConsumerStatefulWidget {
  const NewsPage({super.key});

  @override
  ConsumerState<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage> {
  late FlutterTts _flutterTts;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();

    _flutterTts.setStartHandler(() {
      setState(() => _isPlaying = true);
    });

    _flutterTts.setCompletionHandler(() {
      setState(() => _isPlaying = false);
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() => _isPlaying = false);
    });
  }

  Future<void> _speakNews(List<dynamic> articles) async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() => _isPlaying = false);
      return;
    }

    // Configure language settings

    await _flutterTts.setLanguage("ne-NP");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); // Smooth conversational pacing

    // Compile text blocks to read sequentially
    StringBuffer buffer = StringBuffer();

    if (articles.isNotEmpty) {
      buffer.write("In other breaking news: ");
      final totalBreakingCount = articles.length;
      for (int i = 0; i < totalBreakingCount; i++) {
        buffer.write("${articles[i].title} ");
      }
    } else {
      buffer.write("No breaking news available.");
    }

    if (articles.length > 3) {
      buffer.write("...and ${articles.length - 3} more.");
    }

    await _flutterTts.speak(buffer.toString());
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsAsyncValue = ref.watch(newsProvider);
    final goldSilverAsyncValue = ref.watch(goldSilverProvider);

    return newsAsyncValue.when(
      data: (news) {
        if (news.articles.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text("No news available")),
          );
        }

        final shuffledArticles = List.from(news.articles);
        final heroArticle = shuffledArticles.first;
        final otherArticles = shuffledArticles.skip(1).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => ref.refresh(newsProvider),
              color: AppColors.darkBlue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // 1. Detailed Gold/Silver Market Tracker
                  _buildDetailedMarketTracker(
                    data: goldSilverAsyncValue,
                    onTap: () => context.push(RoutePage.goldSilver),
                  ),
                  const SizedBox(height: 16),

                  // 2. Premium Image-Overlay Hero Card
                  InkWell(
                    onTap: () => context.push(
                      RoutePage.newsDetail,
                      extra: {
                        'url': heroArticle.sourceUrl,
                        'title': heroArticle.source,
                      },
                    ),
                    borderRadius: BorderRadius.circular(24),
                    child: _buildImageOverlayHero(heroArticle),
                  ),
                  const SizedBox(height: 28),

                  // 3. Horizontal "Breaking News" Grid Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Breaking News",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                          letterSpacing: -0.4,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          "See All",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4. Horizontal Scrolling Breaking Grid
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: min(otherArticles.length, 5),
                      itemBuilder: (context, index) {
                        final article = otherArticles[index];
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.44,
                          margin: const EdgeInsets.only(right: 14),
                          child: InkWell(
                            onTap: () => context.push(
                              RoutePage.newsDetail,
                              extra: {
                                'url': article.sourceUrl,
                                'title': article.source,
                              },
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: _buildHorizontalGridItem(article),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Divider(thickness: 0.5, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // 5. General Feed Section
                  const Text(
                    "Latest Updates",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: otherArticles.length > 5
                        ? otherArticles.length - 5
                        : otherArticles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final article =
                          otherArticles[index +
                              (otherArticles.length > 5 ? 5 : 0)];
                      return InkWell(
                        onTap: () => context.push(
                          RoutePage.newsDetail,
                          extra: {
                            'url': article.sourceUrl,
                            'title': article.source,
                          },
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: _buildFeedItem(article),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _speakNews(shuffledArticles),
            backgroundColor: _isPlaying ? AppColors.red : AppColors.darkBlue,
            elevation: 4,
            shape: CircleBorder(),
            label: Icon(
              _isPlaying ? Icons.stop_rounded : Icons.headphones_rounded,
              color: Colors.white,
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.darkBlue,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Error loading feed: $err', style: AppTypography.body),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Sub-widgets below remain unchanged for UI consistency
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildDetailedMarketTracker({
    required AsyncValue<List<GoldSilverResponse>> data,
    required VoidCallback onTap,
  }) {
    return data.when(
      loading: () => _buildTrackerShimmer(),
      error: (_, __) => _buildTrackerError(onTap: onTap),
      data: (list) {
        if (list.isEmpty) return _buildTrackerError(onTap: onTap);

        final latest = list.last;
        final goldPrice = latest.rates.fineGold9999;
        final silverPrice = latest.rates.silver;
        final currency = latest.currency;
        final unit = latest.unit;

        double? goldChange;
        double? goldPct;
        double? silverChange;
        double? silverPct;
        if (list.length >= 2) {
          final prev = list[list.length - 2];

          final goldCur = double.tryParse(goldPrice.replaceAll(',', ''));
          final goldOld = double.tryParse(
            prev.rates.fineGold9999.replaceAll(',', ''),
          );
          if (goldCur != null && goldOld != null && goldOld != 0) {
            goldChange = goldCur - goldOld;
            goldPct = (goldChange / goldOld) * 100;
          }

          final silverCur = double.tryParse(silverPrice.replaceAll(',', ''));
          final silverOld = double.tryParse(
            prev.rates.silver.replaceAll(',', ''),
          );
          if (silverCur != null && silverOld != null && silverOld != 0) {
            silverChange = silverCur - silverOld;
            silverPct = (silverChange / silverOld) * 100;
          }
        }
        final bool isGoldPositive = (goldChange ?? 0) >= 0;
        final Color goldTrendColor = isGoldPositive
            ? AppColors.green
            : AppColors.red;
        final String goldChangeTxt = goldChange != null
            ? '${isGoldPositive ? '+' : ''}${goldChange.toStringAsFixed(0)}'
            : '—';
        final String goldPctTxt = goldPct != null
            ? '${isGoldPositive ? '+' : ''}${goldPct.toStringAsFixed(2)}%'
            : '—';

        final bool isSilverPositive = (silverChange ?? 0) >= 0;
        final Color silverTrendColor = isSilverPositive
            ? AppColors.green
            : AppColors.red;
        final String silverChangeTxt = silverChange != null
            ? '${isSilverPositive ? '+' : ''}${silverChange.toStringAsFixed(0)}'
            : '—';
        final String silverPctTxt = silverPct != null
            ? '${isSilverPositive ? '+' : ''}${silverPct.toStringAsFixed(2)}%'
            : '—';

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.darkBlue.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkBlue.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        'Market Rates',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black.withOpacity(0.55),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• $currency / $unit',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.black.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _buildMetalRow(
                    label: 'Fine Gold 999.9',
                    price: goldPrice,
                    currency: currency,
                    svgAsset: 'assets/gold.svg',
                    iconBg: AppColors.gold.withOpacity(0.12),
                    iconColor: AppColors.gold,
                    changeTxt: goldChangeTxt,
                    pctTxt: goldPctTxt,
                    trendColor: goldTrendColor,
                    isPositive: isGoldPositive,
                    showChange: goldChange != null,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _buildMetalRow(
                    label: 'Silver',
                    price: silverPrice,
                    currency: currency,
                    svgAsset: 'assets/gold.svg',
                    iconBg: AppColors.silver.withOpacity(0.15),
                    iconColor: AppColors.grey,
                    changeTxt: silverChangeTxt,
                    pctTxt: silverPctTxt,
                    trendColor: silverTrendColor,
                    isPositive: isSilverPositive,
                    showChange: silverChange != null,
                    isSilver: true,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Check out all details',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkBlue.withOpacity(0.55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: AppColors.darkBlue.withOpacity(0.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetalRow({
    required String label,
    required String price,
    required String currency,
    required String svgAsset,
    required Color iconBg,
    required Color iconColor,
    required String changeTxt,
    required String pctTxt,
    required Color trendColor,
    required bool isPositive,
    required bool showChange,
    bool isSilver = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            svgAsset,
            width: 22,
            height: 22,
            colorFilter: isSilver
                ? const ColorFilter.mode(AppColors.grey, BlendMode.srcIn)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black.withOpacity(0.5),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                price.isNotEmpty ? 'रू $price' : '—',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        if (showChange)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 13,
                      color: trendColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      pctTxt,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  changeTxt,
                  style: TextStyle(
                    fontSize: 10,
                    color: trendColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Today',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrackerShimmer() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.darkBlue,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildTrackerError({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.red.withOpacity(0.2)),
        ),
        child: const Text(
          'Could not load market rates. Tap to retry.',
          style: TextStyle(
            color: AppColors.red,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildImageOverlayHero(dynamic article) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          if (article.imageUrl.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(article.imageUrl, fit: BoxFit.cover),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                article.source.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      article.source,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Just Now",
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalGridItem(dynamic article) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: article.imageUrl.isNotEmpty
              ? Image.network(
                  article.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Container(height: 120, color: const Color(0xFFF1F5F9)),
        ),
        const SizedBox(height: 8),
        Text(
          article.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "1 hour ago • 3 min read",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildFeedItem(dynamic article) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: article.imageUrl.isNotEmpty
              ? Image.network(
                  article.imageUrl,
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 84,
                  height: 84,
                  color: const Color(0xFFF1F5F9),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.source,
                style: const TextStyle(
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
