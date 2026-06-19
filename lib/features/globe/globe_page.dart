import 'dart:math' as math;

import 'package:bhitte_patro/core/providers/calendar_provider.dart';
import 'package:bhitte_patro/core/utils/nepali_date_converter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bhitte_patro/core/router/route_page.dart';

// ─── Constants ─────────────────────────────────────────────────────────────────

const _kBg1 = Color(0xFF060B1A);
const _kBg2 = Color(0xFF0D1B3E);
const _kGold = Color(0xFFFFD166);
const _kMoonSilver = Color(0xFFCDD5E0);

const List<String> _tithiNames = [
  'प्रतिपदा',
  'द्वितीया',
  'तृतीया',
  'चतुर्थी',
  'पञ्चमी',
  'षष्ठी',
  'सप्तमी',
  'अष्टमी',
  'नवमी',
  'दशमी',
  'एकादशी',
  'द्वादशी',
  'त्रयोदशी',
  'चतुर्दशी',
  'पूर्णिमा / औंसी',
];

// ─── Helpers ───────────────────────────────────────────────────────────────────

int? _getTodayTithiId(Map<String, dynamic> data) {
  final now = DateTime.now();
  final monthDays = data['monthDaysData'];
  if (monthDays == null) return null;
  final bsDate = NepaliDateConverter.convertToBs(now, monthDays);
  final bsYear = bsDate['year'];
  final bsMonth = bsDate['month'];
  final bsDay = bsDate['day'];
  if (bsYear == null || bsMonth == null || bsDay == null) return null;
  final list = data['tithi']?['$bsYear']?['$bsMonth'];
  if (list == null || list is! List || bsDay > list.length) return null;
  final id = list[bsDay - 1] as int?;
  return (id != null && id >= 1 && id <= 15) ? id : null;
}

/// Derive synodic paksha from current UTC time.
bool _computeIsShukla() {
  final now = DateTime.now();
  final refNewMoon = DateTime.utc(1970, 1, 7, 20, 35);
  final diffDays = now.toUtc().difference(refNewMoon).inSeconds / 86400.0;
  const synodicMonth = 29.530588853;
  final lunarAge = diffDays % synodicMonth;
  return lunarAge < 14.765;
}

String _lunarPhase(int? tid, bool isShukla) {
  if (tid == null) return '—';
  if (isShukla) {
    if (tid == 1) return 'New Moon';
    if (tid <= 7) return 'Waxing Crescent';
    if (tid == 8) return 'First Quarter';
    if (tid <= 14) return 'Waxing Gibbous';
    return 'Full Moon';
  } else {
    if (tid == 1) return 'Full Moon';
    if (tid <= 7) return 'Waning Gibbous';
    if (tid == 8) return 'Last Quarter';
    if (tid <= 14) return 'Waning Crescent';
    return 'New Moon';
  }
}

String _phaseEmoji(int? tid, bool isShukla) {
  if (tid == null) return '🌑';
  if (isShukla) {
    const e = [
      '🌑',
      '🌒',
      '🌒',
      '🌒',
      '🌒',
      '🌒',
      '🌒',
      '🌓',
      '🌔',
      '🌔',
      '🌔',
      '🌔',
      '🌔',
      '🌔',
      '🌕',
    ];
    return e[tid - 1];
  } else {
    const e = [
      '🌕',
      '🌖',
      '🌖',
      '🌖',
      '🌖',
      '🌖',
      '🌖',
      '🌗',
      '🌘',
      '🌘',
      '🌘',
      '🌘',
      '🌘',
      '🌘',
      '🌑',
    ];
    return e[tid - 1];
  }
}

// ─── Page ──────────────────────────────────────────────────────────────────────

class GlobePage extends ConsumerStatefulWidget {
  const GlobePage({super.key});

  @override
  ConsumerState<GlobePage> createState() => _GlobePageState();
}

class _GlobePageState extends ConsumerState<GlobePage>
    with SingleTickerProviderStateMixin {
  late FlutterEarthGlobeController _controller;
  late AnimationController _anim;

  // ── Edit-mode state ──────────────────────────────────────────────────────────
  bool _editMode = false;

  /// Moon angle in radians measured CCW from the positive-X axis (3 o'clock).
  /// Sun is always locked at 0 rad (3 o'clock).
  double _moonAngleRad = math.pi / 2; // start at 90° = Tithi 7 approx.

  // ── Drag state ───────────────────────────────────────────────────────────────
  bool _draggingMoon = false;

  @override
  void initState() {
    super.initState();
    _controller = FlutterEarthGlobeController(
      zoom: 0.0,
      rotationSpeed: 0.04,
      isRotating: true,
      showAtmosphere: true,
      atmosphereColor: const Color(0xFF4FC3F7),
      atmosphereOpacity: 0.45,
    );
    _controller.onLoaded = () =>
        _controller.loadSurface(const AssetImage('assets/earth_day.jpg'));

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ── Derived quantities ───────────────────────────────────────────────────────

  /// Elongation = angular distance from Sun (0°) to Moon, always 0–360°.
  double _elongation(double moonRad) {
    // Normalize to 0..2pi relative to sun at 0 rad.
    double angle = moonRad % (2 * math.pi);
    if (angle < 0) angle += 2 * math.pi;
    // Convert to degrees, sun is at 0°.
    return angle * 180.0 / math.pi;
  }

  /// Tithi id 1–30 from elongation. 1–15 = Shukla, 16–30 = Krishna.
  /// Each tithi = 12°.
  int _tithiFromElongation(double elongationDeg) {
    final raw = (elongationDeg / 12.0).floor() + 1;
    return raw.clamp(1, 30);
  }

  /// Is this tithi in Shukla paksha?
  bool _isShuklaFromTithi(int tid30) => tid30 <= 15;

  /// Tithi 1–15 within the paksha from the 1–30 scale.
  int _pakshaLocalTithi(int tid30) => tid30 <= 15 ? tid30 : tid30 - 15;

  // ── Helpers to sync today's data into edit-mode angle ────────────────────────
  void _syncTodayAngle(int? tithiId, bool isShukla) {
    final elongationDeg = (tithiId ?? 8) * 12.0;
    setState(() {
      _moonAngleRad = isShukla
          ? elongationDeg * math.pi / 180.0
          : (360.0 - elongationDeg) * math.pi / 180.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(calendarProvider);
    final todayTithiId = calendarAsync.whenOrNull(
      data: (d) => _getTodayTithiId(d),
    );
    final todayIsShukla = _computeIsShukla();

    return WillPopScope(
      onWillPop: () async {
        context.go(RoutePage.home);
        return false;
      },
      child: Scaffold(
        backgroundColor: _kBg1,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: GestureDetector(
            onTap: () => context.go(RoutePage.home),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          title: Text(
            _editMode ? 'Explore Tithis' : 'Earth & Sky',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          actions: [
            // ── Edit / Done toggle ──────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                if (_editMode) {
                  // Entering view mode → reset
                  setState(() => _editMode = false);
                } else {
                  // Entering edit mode → seed angle from today
                  _syncTodayAngle(todayTithiId, todayIsShukla);
                  setState(() => _editMode = true);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _editMode
                      ? _kGold.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _editMode
                        ? _kGold
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _editMode ? Icons.check_rounded : Icons.edit_rounded,
                      color: _editMode ? _kBg1 : Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _editMode ? 'Done' : 'Explore',
                      style: TextStyle(
                        color: _editMode ? _kBg1 : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;

            // Geometry
            final double globeR = w * 0.26;
            final double orbitR = (w / 2) - 46;
            final Offset centre = Offset(w / 2, h * 0.44);

            // ── Resolve active tithi / elongation ───────────────────────────────
            late final int? activeTithiId;
            late final double elongation;
            late final bool isShukla;
            late final int tithiDisplay; // 1-15

            if (_editMode) {
              elongation = _elongation(_moonAngleRad);
              final tid30 = _tithiFromElongation(elongation);
              isShukla = _isShuklaFromTithi(tid30);
              tithiDisplay = _pakshaLocalTithi(tid30);
              activeTithiId = tithiDisplay;
            } else {
              activeTithiId = todayTithiId;
              elongation = (activeTithiId != null)
                  ? activeTithiId * 12.0
                  : 90.0;
              isShukla = todayIsShukla;
              tithiDisplay = activeTithiId ?? 8;
            }

            // ── Positions ──────────────────────────────────────────────────────
            // Sun is always at 3 o'clock (angle = 0 rad in Flutter coords where Y is down)
            const double sunRad = 0.0;

            // Moon angle in Flutter coords (Y-down).
            final double moonRad = _editMode
                ? _moonAngleRad
                : (isShukla
                      ? elongation * math.pi / 180.0
                      : (360.0 - elongation) * math.pi / 180.0);

            final Offset sunPos = Offset(
              centre.dx + orbitR * math.cos(sunRad),
              centre.dy + orbitR * math.sin(sunRad),
            );
            final Offset moonPos = Offset(
              centre.dx + orbitR * math.cos(moonRad),
              centre.dy + orbitR * math.sin(moonRad),
            );

            return Stack(
              children: [
                // ── Space background ──
                Positioned.fill(child: CustomPaint(painter: _SpacePainter())),

                // ── Orbit ring (highlighted in edit mode) ──
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OrbitRingPainter(
                      centre: centre,
                      radius: orbitR,
                      editMode: _editMode,
                    ),
                  ),
                ),

                // ── Angle arc ──
                Positioned.fill(
                  child: CustomPaint(
                    painter: _AnglePainter(
                      centre: centre,
                      sunPos: sunPos,
                      moonPos: moonPos,
                      angleDeg: elongation,
                    ),
                  ),
                ),

                // ── Globe ──
                Positioned(
                  left: centre.dx - globeR * 1.9,
                  top: centre.dy - globeR * 1.9,
                  width: globeR * 3.8,
                  height: globeR * 3.8,
                  child: MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(size: Size(globeR * 3.8, globeR * 3.8)),
                    child: FlutterEarthGlobe(
                      controller: _controller,
                      radius: globeR,
                    ),
                  ),
                ),

                // ── Sun (always at 3 o'clock) ──
                // In edit mode, absorb all pointer events on the Sun so the user
                // cannot accidentally drag it or trigger the moon orbit.
                Positioned(
                  left: sunPos.dx - 30,
                  top: sunPos.dy - 30,
                  child: AbsorbPointer(
                    absorbing: _editMode,
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (context, child) => _SunBody(pulse: _anim.value),
                    ),
                  ),
                ),

                // ── Moon (draggable only in edit mode) ──
                // The GestureDetector is placed directly on the Moon widget so
                // only dragging the Moon moves it; the Sun is never affected.
                Positioned(
                  left: moonPos.dx - 30,
                  top: moonPos.dy - 30,
                  child: GestureDetector(
                    // Only wire up drag callbacks when we are in edit mode.
                    onPanStart: _editMode
                        ? (d) {
                            // Accept the drag from anywhere on/near the moon body.
                            setState(() => _draggingMoon = true);
                          }
                        : null,
                    onPanUpdate: _editMode
                        ? (d) {
                            if (!_draggingMoon) return;
                            // Map the local pan delta to Stack coordinates and
                            // compute the angle of the Moon relative to the centre.
                            final moonStackTL = Offset(
                              moonPos.dx - 30,
                              moonPos.dy - 30,
                            );
                            final stackPos = moonStackTL + d.localPosition;
                            final vec = stackPos - centre;
                            setState(() {
                              _moonAngleRad = math.atan2(vec.dy, vec.dx);
                            });
                          }
                        : null,
                    onPanEnd: _editMode
                        ? (_) => setState(() => _draggingMoon = false)
                        : null,
                    child: AnimatedScale(
                      scale: (_editMode && _draggingMoon) ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          _MoonBody(tithiId: tithiDisplay, isShukla: isShukla),
                          // Hint badge shown only in edit mode while NOT dragging
                          if (_editMode && !_draggingMoon)
                            Positioned(
                              bottom: -26,
                              child: AnimatedOpacity(
                                opacity: 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kGold.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _kGold.withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.drag_indicator_rounded,
                                        color: _kGold,
                                        size: 10,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'drag me',
                                        style: TextStyle(
                                          color: _kGold,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom info card ──
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _InfoCard(
                    tithiId: activeTithiId,
                    elongation: elongation,
                    isShukla: isShukla,
                    editMode: _editMode,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Space background ──────────────────────────────────────────────────────────

class _SpacePainter extends CustomPainter {
  static final List<Offset> _stars = List.generate(120, (i) {
    final rng = math.Random(i * 7 + 13);
    return Offset(rng.nextDouble(), rng.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kBg1, _kBg2, Color(0xFF091428)],
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < _stars.length; i++) {
      final rng = math.Random(i);
      final r = 0.5 + rng.nextDouble() * 1.5;
      final opacity = 0.3 + rng.nextDouble() * 0.7;
      starPaint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(_stars[i].dx * size.width, _stars[i].dy * size.height),
        r,
        starPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpacePainter _) => false;
}

// ─── Orbit ring ────────────────────────────────────────────────────────────────

class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter({
    required this.centre,
    required this.radius,
    this.editMode = false,
  });
  final Offset centre;
  final double radius;
  final bool editMode;

  @override
  void paint(Canvas canvas, Size size) {
    if (editMode) {
      // Glowing dashed orbit ring in edit mode
      final paint = Paint()
        ..color = _kGold.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(centre, radius, paint);
      // Inner subtle ring
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..color = _kGold.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20,
      );
    } else {
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitRingPainter o) =>
      o.centre != centre || o.radius != radius || o.editMode != editMode;
}

// ─── Angle arc ─────────────────────────────────────────────────────────────────

class _AnglePainter extends CustomPainter {
  const _AnglePainter({
    required this.centre,
    required this.sunPos,
    required this.moonPos,
    required this.angleDeg,
  });
  final Offset centre;
  final Offset sunPos;
  final Offset moonPos;
  final double angleDeg;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(centre, sunPos, linePaint);
    canvas.drawLine(centre, moonPos, linePaint);

    final arcR = 44.0;
    final sunAngle = math.atan2(sunPos.dy - centre.dy, sunPos.dx - centre.dx);
    final moonAngle = math.atan2(
      moonPos.dy - centre.dy,
      moonPos.dx - centre.dx,
    );
    double sweep = moonAngle - sunAngle;
    if (sweep > math.pi) sweep -= 2 * math.pi;
    if (sweep < -math.pi) sweep += 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: arcR),
      sunAngle,
      sweep,
      false,
      Paint()
        ..color = _kGold.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final midAngle = sunAngle + sweep / 2;
    final labelPos = Offset(
      centre.dx + (arcR + 18) * math.cos(midAngle),
      centre.dy + (arcR + 18) * math.sin(midAngle),
    );
    _drawText(
      canvas,
      '${angleDeg.toStringAsFixed(0)}°',
      labelPos,
      const TextStyle(color: _kGold, fontSize: 10, fontWeight: FontWeight.bold),
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_AnglePainter o) =>
      o.angleDeg != angleDeg || o.sunPos != sunPos || o.moonPos != moonPos;
}

// ─── Sun body ──────────────────────────────────────────────────────────────────

class _SunBody extends StatelessWidget {
  const _SunBody({required this.pulse});
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final glowRadius = 22.0 + pulse * 8;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: glowRadius * 2,
            height: glowRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kGold.withValues(alpha: 0.12 + pulse * 0.08),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFF9C4), _kGold, Color(0xFFFF8F00)],
                stops: [0.0, 0.55, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: _kGold.withValues(alpha: 0.7),
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Moon body ─────────────────────────────────────────────────────────────────

class _MoonBody extends StatelessWidget {
  const _MoonBody({required this.tithiId, required this.isShukla});
  final int? tithiId;
  final bool isShukla;

  @override
  Widget build(BuildContext context) {
    final double phase = ((tithiId ?? 8) - 1) / 14.0;
    const glowColor = _kMoonSilver;

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glowColor.withValues(alpha: 0.15),
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glowColor.withValues(alpha: 0.25),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 38,
            height: 38,
            child: CustomPaint(painter: _MoonPainter(phase, isShukla)),
          ),
        ],
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  final double phase;
  final bool isShukla;
  _MoonPainter(this.phase, this.isShukla);

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final center = Offset(r, r);

    if (!isShukla) {
      canvas.translate(r, 0);
      canvas.scale(-1, 1);
      canvas.translate(-r, 0);
    }

    final darkPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF1B2230), Color(0xFF0F141D)],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, darkPaint);

    final litPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, _kMoonSilver, Color(0xFF9EA7B5)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    final path = Path();
    if (phase >= 0.5) {
      path.addArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        math.pi,
      );
      final ellipseWidth = (phase - 0.5) * 2.0 * r;
      path.addOval(
        Rect.fromLTRB(
          center.dx - ellipseWidth,
          center.dy - r,
          center.dx + ellipseWidth,
          center.dy + r,
        ),
      );
    } else {
      final ellipseWidth = (0.5 - phase) * 2.0 * r;
      final path1 = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: r),
          -math.pi / 2,
          math.pi,
        );
      final path2 = Path()
        ..addOval(
          Rect.fromLTRB(
            center.dx - ellipseWidth,
            center.dy - r,
            center.dx + ellipseWidth,
            center.dy + r,
          ),
        );
      path.addPath(
        Path.combine(PathOperation.difference, path1, path2),
        Offset.zero,
      );
    }

    canvas.drawPath(path, litPaint);

    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
        stops: const [0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, shadowPaint);
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.phase != phase || old.isShukla != isShukla;
}

// ─── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.tithiId,
    required this.elongation,
    required this.isShukla,
    required this.editMode,
  });
  final int? tithiId;
  final double elongation;
  final bool isShukla;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    final name = tithiId != null ? _tithiNames[tithiId! - 1] : '—';
    final phase = _lunarPhase(tithiId, isShukla);
    final emoji = _phaseEmoji(tithiId, isShukla);

    // Illumination: (1 − cos θ) / 2 — exact photometric formula
    final double rad = elongation * math.pi / 180.0;
    final double illumination = (1.0 - math.cos(rad)) / 2.0;
    final String illuminationStr =
        '${(illumination * 100).toStringAsFixed(0)}%';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        // Flat, non-glowing backgrounds
        color: editMode
            ? const Color(
                0xFF2D1A04,
              ) // Dark solid amber/gold tint instead of alpha transparency
            : const Color(
                0xFF1E1E1E,
              ), // Solid dark grey to prevent background bleeding
        border: Border.all(
          color: editMode
              ? _kGold.withValues(alpha: 0.4) // Kept clean and crisp
              : Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        // Removed the deep, blurry shadow that caused the glow
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top row ──────────────────────────────────────────────────────────
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phase,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Tithi badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: editMode
                        ? [const Color(0xFFFF8F00), _kGold]
                        : [const Color(0xFF7B2FF7), const Color(0xFF4A90D9)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Tithi ${tithiId ?? "—"}',
                  style: TextStyle(
                    color: editMode ? _kBg1 : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),
          // ── Stats row ────────────────────────────────────────────────────────
          Row(
            children: [
              _StatTile(
                icon: Icons.wb_sunny_outlined,
                iconColor: _kGold,
                label: 'Sun-Moon angle',
                value: '${elongation.toStringAsFixed(1)}°',
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.brightness_2_outlined,
                iconColor: _kMoonSilver,
                label: 'Illumination',
                value: illuminationStr,
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: Icons.calendar_today_outlined,
                iconColor: Colors.greenAccent.shade200,
                label: 'Paksha',
                value: isShukla ? 'Shukla' : 'Krishna',
              ),
            ],
          ),
          // ── Edit-mode label ──────────────────────────────────────────────────
          if (editMode) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Drag the moon · exploring ${isShukla ? "Shukla" : "Krishna"} Paksha',
                style: TextStyle(
                  color: _kGold.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          // Changed from translucent white alpha to a flat, solid dark surface
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(14),
          // Clean, defined border without bleeding transparency
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
