import 'package:bhitte_patro/core/consts/app_colors.dart';
import 'package:bhitte_patro/core/consts/app_font_size.dart';
import 'package:bhitte_patro/core/consts/app_space.dart';
import 'package:bhitte_patro/core/consts/app_typography.dart';
import 'package:bhitte_patro/core/providers/gold_silver_price_provider.dart';
import 'package:bhitte_patro/core/models/gold_silver/gold_silver_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class GoldSilverWidget extends ConsumerWidget {
  const GoldSilverWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(goldSilverProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: ratesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.darkBlue,
              strokeWidth: 1.5,
            ),
          ),
          error: (e, _) =>
              _ErrorState(onRetry: () => ref.invalidate(goldSilverProvider)),
          data: (rates) => _GoldSilverBody(
            rates: rates,
            onRefresh: () async => ref.invalidate(goldSilverProvider),
          ),
        ),
      ),
    );
  }
}

class _GoldSilverBody extends StatefulWidget {
  final List<GoldSilverResponse> rates;
  final Future<void> Function() onRefresh;

  const _GoldSilverBody({required this.rates, required this.onRefresh});

  @override
  State<_GoldSilverBody> createState() => _GoldSilverBodyState();
}

class _GoldSilverBodyState extends State<_GoldSilverBody> {
  int _selectedChartTab = 0; // 0 for Gold, 1 for Silver

  @override
  Widget build(BuildContext context) {
    if (widget.rates.isEmpty) return const SizedBox();

    final latest = widget.rates.last;
    final prev = widget.rates.length > 1
        ? widget.rates[widget.rates.length - 2]
        : null;

    final goldNow = double.tryParse(latest.rates.fineGold9999) ?? 0;
    final silverNow = double.tryParse(latest.rates.silver) ?? 0;

    final goldDiff =
        goldNow - (double.tryParse(prev?.rates.fineGold9999 ?? '0') ?? 0);
    final silverDiff =
        silverNow - (double.tryParse(prev?.rates.silver ?? '0') ?? 0);

    final allGold = widget.rates
        .map((r) => double.tryParse(r.rates.fineGold9999) ?? 0)
        .toList();
    final allSilver = widget.rates
        .map((r) => double.tryParse(r.rates.silver) ?? 0)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isNarrow = screenWidth < 360;
        final hPad = isNarrow ? AppSpace.small : AppSpace.medium;

        return RefreshIndicator(
          color: AppColors.darkBlue,
          backgroundColor: AppColors.white,
          onRefresh: widget.onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.white,
                surfaceTintColor: Colors.transparent,
                expandedHeight: 92,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: hPad, bottom: 12),
                  title: Text(
                    'Gold & Silver',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.darkBlue,
                    ),
                    onPressed: widget.onRefresh,
                  ),
                  SizedBox(width: hPad / 2),
                ],
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Timestamp subtext
                    Text(
                      '${latest.source} · Updated ${latest.timestamp}',
                      style: AppTypography.body.copyWith(
                        color: AppColors.grey,
                        fontSize: AppFontSize.small,
                      ),
                    ),
                    const SizedBox(height: AppSpace.medium),

                    // Gold & Silver Performance Summary Cards
                    _MetalCard(
                      label: 'Fine Gold',
                      value: goldNow,
                      diff: goldDiff,
                      allValues: allGold,
                      accentColor: AppColors.gold,
                      currency: latest.currency,
                      unit: latest.unit,
                      screenWidth: screenWidth,
                    ),
                    const SizedBox(height: AppSpace.medium),
                    _MetalCard(
                      label: 'Silver',
                      value: silverNow,
                      diff: silverDiff,
                      allValues: allSilver,
                      accentColor: AppColors.silver,
                      currency: latest.currency,
                      unit: latest.unit,
                      screenWidth: screenWidth,
                    ),
                    const SizedBox(height: AppSpace.large),

                    // Interactive Trend Segments
                    Row(
                      children: [
                        const _SectionTitle('Market Trends'),
                        const Spacer(),
                        _SegmentControl(
                          selectedIndex: _selectedChartTab,
                          onChanged: (val) =>
                              setState(() => _selectedChartTab = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.medium),

                    // Responsive Dynamic Chart Render
                    _LineChart(
                      rates: widget.rates,
                      screenWidth: screenWidth,
                      isGold: _selectedChartTab == 0,
                    ),
                    const SizedBox(height: AppSpace.large),

                    const _SectionTitle('History'),
                    const SizedBox(height: AppSpace.small),
                    _HistoryList(rates: widget.rates, screenWidth: screenWidth),

                    const SizedBox(height: AppSpace.large),
                    Center(
                      child: Text(
                        'All values are displayed in ${latest.currency} per ${latest.unit}',
                        style: AppTypography.hint.copyWith(
                          fontSize: AppFontSize.small,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.large),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Minimal Metallic Card Implementation ──────────────────────────────────────
class _MetalCard extends StatelessWidget {
  final String label;
  final double value, diff;
  final List<double> allValues;
  final Color accentColor;
  final String currency, unit;
  final double screenWidth;

  const _MetalCard({
    required this.label,
    required this.value,
    required this.diff,
    required this.allValues,
    required this.accentColor,
    required this.currency,
    required this.unit,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final isUp = diff >= 0;
    final base = value - diff;
    final pct = base != 0 ? (diff.abs() / base.abs() * 100) : 0.0;

    // Safety handling for min/max array bounds checks
    final high = allValues.isEmpty
        ? 0.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final low = allValues.isEmpty
        ? 0.0
        : allValues.reduce((a, b) => a < b ? a : b);
    final cardPad = screenWidth < 360 ? AppSpace.small : AppSpace.medium;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.darkBlue.withOpacity(0.12),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(cardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              _ChangePill(
                isUp: isUp,
                valueLabel: fmt.format(diff.abs()),
                pctLabel: '${pct.toStringAsFixed(2)}%',
              ),
            ],
          ),
          const SizedBox(height: AppSpace.small),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                fmt.format(value),
                style: AppTypography.caption.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currency,
                style: AppTypography.hint.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: AppFontSize.small,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.medium),
          Container(height: 0.5, color: AppColors.darkBlue.withOpacity(0.08)),
          const SizedBox(height: AppSpace.small),
          Row(
            children: [
              _Stat(label: '7D High', value: '${fmt.format(high)} $currency'),
              const SizedBox(width: AppSpace.large),
              _Stat(label: '7D Low', value: '${fmt.format(low)} $currency'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  final bool isUp;
  final String valueLabel;
  final String pctLabel;

  const _ChangePill({
    required this.isUp,
    required this.valueLabel,
    required this.pctLabel,
  });

  @override
  Widget build(BuildContext context) {
    final targetColor = isUp ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: targetColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 14,
            color: targetColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$valueLabel ($pctLabel)',
            style: TextStyle(
              fontSize: AppFontSize.small - 1,
              color: targetColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSize.small - 1,
            color: AppColors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppFontSize.small,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}

// ── Segment Controller Design Variant ─────────────────────────────────────────
class _SegmentControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentControl({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.darkBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_buildSegment(0, 'Gold'), _buildSegment(1, 'Silver')],
      ),
    );
  }

  Widget _buildSegment(int index, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.small,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.black : AppColors.grey,
          ),
        ),
      ),
    );
  }
}

// ── Dynamic Custom Trend Chart Implementation ─────────────────────────────────
class _LineChart extends StatelessWidget {
  final List<GoldSilverResponse> rates;
  final double screenWidth;
  final bool isGold;

  const _LineChart({
    required this.rates,
    required this.screenWidth,
    required this.isGold,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final values = rates
        .map(
          (r) =>
              double.tryParse(isGold ? r.rates.fineGold9999 : r.rates.silver) ??
              0,
        )
        .toList();

    if (values.isEmpty) return const SizedBox();

    final rawMinY = values.reduce((a, b) => a < b ? a : b);
    final rawMaxY = values.reduce((a, b) => a > b ? a : b);
    final margin = (rawMaxY - rawMinY == 0) ? 10.0 : (rawMaxY - rawMinY) * 0.15;

    final minY = rawMinY - margin;
    final maxY = rawMaxY + margin;

    final spots = values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final chartHeight = (screenWidth * 0.52).clamp(160.0, 220.0);
    final activeThemeColor = isGold ? AppColors.gold : AppColors.silver;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.darkBlue.withOpacity(0.12),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 10),
      height: chartHeight,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 3,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    v >= 1000
                        ? '${(v / 1000).toStringAsFixed(0)}k'
                        : v.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: AppFontSize.extraSmall,
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= rates.length) return const SizedBox();

                  // FIXED: Only show first, middle, and last to prevent text crowding/overlapping
                  final isFirst = idx == 0;
                  final isLast = idx == rates.length - 1;
                  final isMiddle = idx == (rates.length / 2).floor();

                  if (!isFirst && !isLast && (!isMiddle || rates.length <= 3)) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      rates[idx].timestamp,
                      style: TextStyle(
                        fontSize: AppFontSize.extraSmall,
                        color: isLast ? activeThemeColor : AppColors.grey,
                        fontWeight: isLast
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.white,
              tooltipBorder: BorderSide(
                color: AppColors.darkBlue.withOpacity(0.12),
                width: 0.5,
              ),
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      fmt.format(s.y),
                      TextStyle(
                        color: activeThemeColor,
                        fontSize: AppFontSize.small,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: activeThemeColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, idx) => FlDotCirclePainter(
                  radius: idx == spots.length - 1 ? 4.5 : 2.5,
                  color: activeThemeColor,
                  strokeWidth: 1.5,
                  strokeColor: AppColors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    activeThemeColor.withOpacity(0.08),
                    activeThemeColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Clean Periodic Logs ──────────────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  final List<GoldSilverResponse> rates;
  final double screenWidth;
  const _HistoryList({required this.rates, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_US');
    final recent = rates.reversed.take(6).toList();

    final isNarrow = screenWidth < 360;
    final goldColWidth = isNarrow ? 80.0 : 90.0;
    final silverColWidth = isNarrow ? 62.0 : 70.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.darkBlue.withOpacity(0.12),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  ),
                ),
                SizedBox(
                  width: goldColWidth,
                  child: const Text(
                    'Gold',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ),
                SizedBox(
                  width: silverColWidth,
                  child: const Text(
                    'Silver',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppFontSize.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: AppColors.darkBlue.withOpacity(0.08),
            height: 0,
            thickness: 0.5,
          ),
          ...recent.asMap().entries.map((e) {
            final r = e.value;
            final isLast = e.key == recent.length - 1;
            final gold = double.tryParse(r.rates.fineGold9999) ?? 0;
            final silver = double.tryParse(r.rates.silver) ?? 0;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.timestamp,
                          style: const TextStyle(
                            fontSize: AppFontSize.medium,
                            color: AppColors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: goldColWidth,
                        child: Text(
                          fmt.format(gold),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: AppFontSize.medium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: silverColWidth,
                        child: Text(
                          fmt.format(silver),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: AppFontSize.medium,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    color: AppColors.darkBlue.withOpacity(0.06),
                    height: 0,
                    thickness: 0.5,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: AppFontSize.medium,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.grey, size: 40),
            const SizedBox(height: AppSpace.medium),
            const Text(
              'Failed to sync market rates',
              style: TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w500,
                fontSize: AppFontSize.medium,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Check your connection and try again.',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: AppFontSize.small,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpace.large),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: AppFontSize.medium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
