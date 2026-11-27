import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Visual palette for a Play Store marketing slide backdrop, harmonized with
/// `docs/store_assets/feature_graphic_1024x500.png` and `AppTheme` (`#1A56DB`).
enum SlideBackdropStyle {
  royalBlue(
    gradientColors: [Color(0xFF092A82), Color(0xFF1A56DB), Color(0xFF1543BA)],
    headlineColor: Color(0xFFFFFFFF),
    subtitleColor: Color(0xFFD8E6FF),
    badgeBackground: Color(0x2EFFFFFF),
    badgeBorder: Color(0x47FFFFFF),
    badgeTextColor: Color(0xFFFFFFFF),
    waveColor: Color(0x16FFFFFF),
    glowColor: Color(0x3360A5FA),
  ),
  softIce(
    gradientColors: [Color(0xFFF3F7FF), Color(0xFFE5EEFF), Color(0xFFD8E5FF)],
    headlineColor: Color(0xFF0C2254),
    subtitleColor: Color(0xFF395082),
    badgeBackground: Color(0x181A56DB),
    badgeBorder: Color(0x301A56DB),
    badgeTextColor: Color(0xFF1648BD),
    waveColor: Color(0x121A56DB),
    glowColor: Color(0x281A56DB),
  ),
  midnight(
    gradientColors: [Color(0xFF070E1F), Color(0xFF102044), Color(0xFF0A1632)],
    headlineColor: Color(0xFFFFFFFF),
    subtitleColor: Color(0xFFB4C9F0),
    badgeBackground: Color(0x245B9DFF),
    badgeBorder: Color(0x447BB2FF),
    badgeTextColor: Color(0xFF96C4FF),
    waveColor: Color(0x127BAFFF),
    glowColor: Color(0x382563EB),
  );

  const SlideBackdropStyle({
    required this.gradientColors,
    required this.headlineColor,
    required this.subtitleColor,
    required this.badgeBackground,
    required this.badgeBorder,
    required this.badgeTextColor,
    required this.waveColor,
    required this.glowColor,
  });

  final List<Color> gradientColors;
  final Color headlineColor;
  final Color subtitleColor;
  final Color badgeBackground;
  final Color badgeBorder;
  final Color badgeTextColor;
  final Color waveColor;
  final Color glowColor;
}

/// Logical size of a portrait phone slide (`360 × 640` @ `3.0` DPR = `1080 × 1920`).
const Size kPortraitSlideLogicalSize = Size(360, 640);

/// Logical size of a landscape hero slide (`640 × 360` @ `3.0` DPR = `1920 × 1080`).
const Size kLandscapeSlideLogicalSize = Size(640, 360);

/// Standard modern Pixel-class logical viewport hosted inside [PixelDeviceFrame].
const Size kPhoneScreenLogicalSize = Size(390, 750);

/// Full-bleed opaque Play Store portrait marketing slide (`1080 × 1920` at 3x).
class PortraitMarketingSlide extends StatelessWidget {
  const PortraitMarketingSlide({
    super.key,
    required this.badge,
    required this.headline,
    required this.subtitle,
    required this.style,
    required this.statusBarBrightness,
    required this.child,
    this.screenLogicalSize = kPhoneScreenLogicalSize,
    this.deviceDisplayWidth = 266,
  });

  final String badge;
  final String headline;
  final String subtitle;
  final SlideBackdropStyle style;
  final Brightness statusBarBrightness;
  final Widget child;
  final Size screenLogicalSize;
  final double deviceDisplayWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kPortraitSlideLogicalSize.width,
      height: kPortraitSlideLogicalSize.height,
      child: _MarketingBackdrop(
        style: style,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PillBadge(label: badge, style: style),
              const SizedBox(height: 8),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 22.5,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                  letterSpacing: -0.5,
                  color: style.headlineColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                  color: style.subtitleColor,
                ),
              ),
              const Spacer(),
              PixelDeviceFrame(
                displayWidth: deviceDisplayWidth,
                screenLogicalSize: screenLogicalSize,
                statusBarBrightness: statusBarBrightness,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-bleed opaque Play Store landscape hero slide (`1920 × 1080` at 3x).
class LandscapeMarketingSlide extends StatelessWidget {
  const LandscapeMarketingSlide({
    super.key,
    required this.primaryPhone,
    required this.secondaryPhone,
  });

  final Widget primaryPhone;
  final Widget secondaryPhone;

  @override
  Widget build(BuildContext context) {
    const style = SlideBackdropStyle.royalBlue;
    return SizedBox(
      width: kLandscapeSlideLogicalSize.width,
      height: kLandscapeSlideLogicalSize.height,
      child: _MarketingBackdrop(
        style: style,
        isLandscape: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 24, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x40000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/branding/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Postfolio',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Portfolio & Monthly\nLedger for Agents',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.14,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Track RD collections, plan Post Office lots,\nand project TD, MIS, NSC & KVP maturities.',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          height: 1.38,
                          color: Color(0xFFD8E6FF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _FeatureChip(label: 'RD Monthly Hub'),
                          _FeatureChip(label: 'PO Lot Planner'),
                          _FeatureChip(label: 'Light & Dark'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 14,
                child: SizedBox.expand(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: 4,
                        top: 8,
                        child: PixelDeviceFrame(
                          displayWidth: 162,
                          screenLogicalSize: kPhoneScreenLogicalSize,
                          statusBarBrightness: Brightness.dark,
                          child: secondaryPhone,
                        ),
                      ),
                      Positioned(
                        left: 4,
                        top: 22,
                        child: PixelDeviceFrame(
                          displayWidth: 164,
                          screenLogicalSize: kPhoneScreenLogicalSize,
                          statusBarBrightness: Brightness.light,
                          child: primaryPhone,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean Pixel-style hardware bezel with authentic Android status bar (`9:41`)
/// and bottom gesture navigation bar, scaling [screenLogicalSize] cleanly.
class PixelDeviceFrame extends StatelessWidget {
  const PixelDeviceFrame({
    super.key,
    required this.child,
    required this.statusBarBrightness,
    this.displayWidth = 280,
    this.screenLogicalSize = kPhoneScreenLogicalSize,
  });

  final Widget child;
  final Brightness statusBarBrightness;
  final double displayWidth;
  final Size screenLogicalSize;

  static const double _bezelThickness = 9.0;
  static const double _outerRadius = 38.0;
  static const double _innerRadius = 29.0;
  static const double _statusBarHeight = 32.0;
  static const double _gestureBarHeight = 16.0;

  @override
  Widget build(BuildContext context) {
    final fullFrameSize = Size(
      screenLogicalSize.width + _bezelThickness * 2,
      screenLogicalSize.height + _bezelThickness * 2,
    );
    final displayHeight =
        displayWidth * (fullFrameSize.height / fullFrameSize.width);

    final statusForeground = statusBarBrightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1A1C22);

    return Container(
      width: displayWidth,
      height: displayHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          _outerRadius * (displayWidth / fullFrameSize.width),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x42041133),
            blurRadius: 28,
            spreadRadius: -2,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x24041133),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: fullFrameSize.width,
          height: fullFrameSize.height,
          child: Container(
            padding: const EdgeInsets.all(_bezelThickness),
            decoration: BoxDecoration(
              color: const Color(0xFF171A23),
              borderRadius: BorderRadius.circular(_outerRadius),
              border: Border.all(color: const Color(0xFF3A4256), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_innerRadius),
              child: SizedBox(
                width: screenLogicalSize.width,
                height: screenLogicalSize.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: screenLogicalSize,
                        padding: const EdgeInsets.only(
                          top: _statusBarHeight,
                          bottom: _gestureBarHeight,
                        ),
                        viewPadding: const EdgeInsets.only(
                          top: _statusBarHeight,
                          bottom: _gestureBarHeight,
                        ),
                        viewInsets: EdgeInsets.zero,
                      ),
                      child: child,
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _statusBarHeight,
                      child: _AndroidStatusBar(foreground: statusForeground),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 5,
                      child: Center(
                        child: Container(
                          width: 108,
                          height: 4,
                          decoration: BoxDecoration(
                            color: statusForeground.withAlpha(110),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AndroidStatusBar extends StatelessWidget {
  const _AndroidStatusBar({required this.foreground});

  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            '9:41',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foreground,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: Color(0xFF0B0D12),
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          CustomPaint(
            size: const Size(48, 12),
            painter: _StatusIconsPainter(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _StatusIconsPainter extends CustomPainter {
  const _StatusIconsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;

    // 4-bar cellular signal
    const barWidth = 2.4;
    const barGap = 1.6;
    for (var i = 0; i < 4; i++) {
      final h = 3.5 + i * 2.2;
      final x = i * (barWidth + barGap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - 1.5 - h, barWidth, h),
          const Radius.circular(0.8),
        ),
        fill,
      );
    }

    // Wi-Fi arcs
    final wifiCenter = Offset(24.0, size.height - 2.0);
    canvas.drawCircle(wifiCenter, 1.3, fill);
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final r in [4.2, 7.2]) {
      canvas.drawArc(
        Rect.fromCircle(center: wifiCenter, radius: r),
        -math.pi * 0.78,
        math.pi * 0.56,
        false,
        arcPaint,
      );
    }

    // Battery body + terminal tip
    final batteryRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(34, 2, 11, 8),
      const Radius.circular(1.8),
    );
    canvas.drawRRect(
      batteryRect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35.6, 3.6, 7.8, 4.8),
        const Radius.circular(0.8),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(45.8, 4.2, 1.5, 3.6),
        const Radius.circular(0.5),
      ),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _StatusIconsPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.label, required this.style});

  final String label;
  final SlideBackdropStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
      decoration: BoxDecoration(
        color: style.badgeBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.badgeBorder, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 9.8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: style.badgeTextColor,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x40FFFFFF), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MarketingBackdrop extends StatelessWidget {
  const _MarketingBackdrop({
    required this.style,
    required this.child,
    this.isLandscape = false,
  });

  final SlideBackdropStyle style;
  final Widget child;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: style.gradientColors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _BackdropWavePainter(
              waveColor: style.waveColor,
              glowColor: style.glowColor,
              isLandscape: isLandscape,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BackdropWavePainter extends CustomPainter {
  const _BackdropWavePainter({
    required this.waveColor,
    required this.glowColor,
    required this.isLandscape,
  });

  final Color waveColor;
  final Color glowColor;
  final bool isLandscape;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft radial ambient glow behind the phone showcase
    final glowCenter = isLandscape
        ? Offset(size.width * 0.72, size.height * 0.56)
        : Offset(size.width * 0.5, size.height * 0.62);
    final glowRadius = isLandscape ? size.height * 0.72 : size.width * 0.68;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [glowColor, glowColor.withAlpha(0)],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    final wavePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(-size.width * 0.15, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.05,
        size.width * 1.15,
        size.height * 0.36,
      );
    canvas.drawPath(path1, wavePaint);

    final path2 = Path()
      ..moveTo(-size.width * 0.15, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.96,
        size.width * 1.15,
        size.height * 0.68,
      );
    canvas.drawPath(path2, wavePaint..strokeWidth = size.width * 0.18);
  }

  @override
  bool shouldRepaint(covariant _BackdropWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.isLandscape != isLandscape;
}
