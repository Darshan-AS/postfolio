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

/// Logical size of a 7" / 10" tablet landscape slide (`960 × 540` @ `2.0` DPR = `1920 × 1080`).
const Size kTabletSlideLogicalSize = Size(960, 540);

/// Logical size of the Google Play Feature Graphic (`512 × 250` @ `2.0` DPR = `1024 × 500`).
const Size kFeatureGraphicLogicalSize = Size(512, 250);

/// Tall 18:9 Play Store portrait canvas (`360 × 720` @ `3.0` DPR = `1080 × 2160`).
const Size kPortraitTallSlideLogicalSize = Size(360, 720);

/// Double-width panoramic canvas spanning two 18:9 slides (`720 × 720` @ `3.0` DPR = `2160 × 2160`).
const Size kPanoramicPairLogicalSize = Size(720, 720);

/// Pixel 11 Pro 20:9 logical viewport (`412 × 915` dp).
const Size kPixel11ProScreenSize = Size(412, 915);

/// Pixel Tablet 16:10 logical viewport (`1280 × 800` dp).
const Size kPixelTabletScreenSize = Size(1280, 800);

/// Vertical placement of marketing headline copy on a portrait slide.
enum CaptionPlacement { top, bottom }

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
                          const _BrandAppIconBadge(
                            size: 42,
                            radius: 10,
                            borderWidth: 1.2,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x48041133),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
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
                        child: PixelProDeviceFrame(
                          displayWidth: 152,
                          screenLogicalSize: kPixel11ProScreenSize,
                          statusBarBrightness: Brightness.dark,
                          child: secondaryPhone,
                        ),
                      ),
                      Positioned(
                        left: 4,
                        top: 22,
                        child: PixelProDeviceFrame(
                          displayWidth: 154,
                          screenLogicalSize: kPixel11ProScreenSize,
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
              border: Border.all(color: const Color(0xFF5C667E), width: 1.5),
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

/// Full-bleed opaque Play Store tablet landscape slide (`1920 × 1080` at 2x),
/// showcasing the responsive Navigation Rail layout (`>= 600dp`).
class TabletMarketingSlide extends StatelessWidget {
  const TabletMarketingSlide({
    super.key,
    required this.badge,
    required this.headline,
    required this.subtitle,
    required this.style,
    required this.statusBarBrightness,
    required this.screenLogicalSize,
    required this.child,
  });

  final String badge;
  final String headline;
  final String subtitle;
  final SlideBackdropStyle style;
  final Brightness statusBarBrightness;
  final Size screenLogicalSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kTabletSlideLogicalSize.width,
      height: kTabletSlideLogicalSize.height,
      child: _MarketingBackdrop(
        style: style,
        isLandscape: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 18, 32, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PillBadge(label: badge, style: style),
                  const SizedBox(width: 12),
                  Text(
                    headline,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: style.headlineColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: style.subtitleColor,
                ),
              ),
              const Spacer(),
              TabletDeviceFrame(
                displayWidth: 680,
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

/// Clean Android tablet landscape bezel with status bar (`9:41`) and gesture bar.
class TabletDeviceFrame extends StatelessWidget {
  const TabletDeviceFrame({
    super.key,
    required this.child,
    required this.statusBarBrightness,
    required this.screenLogicalSize,
    this.displayWidth = 680,
  });

  final Widget child;
  final Brightness statusBarBrightness;
  final Size screenLogicalSize;
  final double displayWidth;

  static const double _bezelThickness = 14.0;
  static const double _outerRadius = 30.0;
  static const double _innerRadius = 18.0;
  static const double _statusBarHeight = 28.0;
  static const double _gestureBarHeight = 14.0;

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
              border: Border.all(color: const Color(0xFF5C667E), width: 1.5),
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
                      child: _AndroidStatusBar(
                        foreground: statusForeground,
                        showCameraPunch: false,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 4,
                      child: Center(
                        child: Container(
                          width: 140,
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

/// Google Play Store Feature Graphic (`1024 × 500` at 2x), matching Postfolio's
/// royal-blue wave brand identity.
class FeatureGraphicBanner extends StatelessWidget {
  const FeatureGraphicBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kFeatureGraphicLogicalSize.width,
      height: kFeatureGraphicLogicalSize.height,
      child: _MarketingBackdrop(
        style: SlideBackdropStyle.royalBlue,
        isLandscape: true,
        child: Stack(
          children: [
            // Decorative layered passbook / ledger cards on the right edge.
            Positioned(
              right: -24,
              top: 26,
              child: Transform.rotate(
                angle: -0.14,
                child: _DecorPassbookCard(width: 96, height: 126, alpha: 42),
              ),
            ),
            Positioned(
              right: 22,
              top: 52,
              child: Transform.rotate(
                angle: 0.04,
                child: _DecorPassbookCard(width: 92, height: 122, alpha: 64),
              ),
            ),
            Positioned(
              right: -12,
              bottom: -24,
              child: Transform.rotate(
                angle: 0.09,
                child: _DecorPassbookCard(width: 96, height: 112, alpha: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 28, 120, 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _BrandAppIconBadge(
                    size: 82,
                    radius: 20,
                    borderWidth: 1.5,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x52041133),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  const SizedBox(width: 22),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Postfolio',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1.05,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Portfolio & Monthly Ledger\nfor Savings Agents',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: Color(0xFFD8E6FF),
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _FeatureChip(label: 'RD Monthly Hub'),
                            _FeatureChip(label: 'PO Lot Planner'),
                            _FeatureChip(label: 'TD · MIS · NSC · KVP'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandAppIconBadge extends StatelessWidget {
  const _BrandAppIconBadge({
    required this.size,
    required this.radius,
    required this.borderWidth,
    required this.boxShadow,
  });

  final double size;
  final double radius;
  final double borderWidth;
  final List<BoxShadow> boxShadow;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: const Color(0x4DFFFFFF),
                width: borderWidth,
              ),
            ),
            child: Image.asset(
              'assets/branding/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _DecorPassbookCard extends StatelessWidget {
  const _DecorPassbookCard({
    required this.width,
    required this.height,
    required this.alpha,
  });

  final double width;
  final double height;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(alpha),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(alpha + 28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(alpha + 40),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(alpha + 25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(alpha + 20),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(alpha + 30),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class _AndroidStatusBar extends StatelessWidget {
  const _AndroidStatusBar({
    required this.foreground,
    this.showCameraPunch = true,
  });

  final Color foreground;
  final bool showCameraPunch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            '10:00',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foreground,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          if (showCameraPunch) ...[
            Container(
              width: 11,
              height: 11,
              decoration: const BoxDecoration(
                color: Color(0xFF0B0D12),
                shape: BoxShape.circle,
              ),
            ),
            const Spacer(),
          ],
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

// ============================================================================
// Pixel 11 Pro (20:9), Continuous Multi-Slide Wave & Panoramic Split Primitives
// ============================================================================

/// Returns true when the continuous carousel gradient is light (Soft Ice) at [slideIndex].
bool continuousBackdropIsLight(int slideIndex, {int totalSlides = 8}) {
  final t = totalSlides <= 1 ? 0.0 : slideIndex / (totalSlides - 1);
  return t >= 0.24 && t <= 0.44;
}

/// Seamless multi-slide backdrop whose gradient and cubic Bézier waves span the
/// entire [totalSlides] carousel strip so adjacent slides align across edges.
class ContinuousCarouselBackdrop extends StatelessWidget {
  const ContinuousCarouselBackdrop({
    super.key,
    required this.slideIndex,
    required this.child,
    this.totalSlides = 8,
    this.spanSlides = 1,
  });

  final int slideIndex;
  final int totalSlides;
  final int spanSlides;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _ContinuousStripPainter(
            slideIndex: slideIndex,
            totalSlides: totalSlides,
            spanSlides: spanSlides,
          ),
        ),
        child,
      ],
    );
  }
}

class _ContinuousStripPainter extends CustomPainter {
  const _ContinuousStripPainter({
    required this.slideIndex,
    required this.totalSlides,
    required this.spanSlides,
  });

  final int slideIndex;
  final int totalSlides;
  final int spanSlides;

  @override
  void paint(Canvas canvas, Size size) {
    final unitWidth = size.width / spanSlides;
    final stripWidth = unitWidth * totalSlides;
    final offsetX = -slideIndex * unitWidth;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(offsetX, 0);

    final stripRect = Rect.fromLTWH(0, 0, stripWidth, size.height);
    const gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: [0.0, 0.22, 0.28, 0.46, 0.53, 0.72, 0.78, 1.0],
      colors: [
        Color(0xFF092A82),
        Color(0xFF1A56DB),
        Color(0xFFE8F0FF),
        Color(0xFFE3ECFF),
        Color(0xFF1A56DB),
        Color(0xFF133A9E),
        Color(0xFF0D1D3E),
        Color(0xFF070E1F),
      ],
    );
    canvas.drawRect(
      stripRect,
      Paint()..shader = gradient.createShader(stripRect),
    );

    // Subtle ambient glows behind odd/even slides across the strip.
    for (var i = 0; i < totalSlides; i++) {
      final light = continuousBackdropIsLight(i, totalSlides: totalSlides);
      final glowColor = light
          ? const Color(0x221A56DB)
          : const Color(0x3060A5FA);
      final center = Offset((i + 0.5) * unitWidth, size.height * 0.58);
      final radius = unitWidth * 0.78;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [glowColor, glowColor.withAlpha(0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    // Continuous sweeping ribbon curves crossing all slide seams smoothly.
    final wavePaint = Paint()
      ..color = const Color(0x1CFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = unitWidth * 0.22
      ..strokeCap = StrokeCap.round;

    final ribbon1 = Path()..moveTo(-unitWidth * 0.2, size.height * 0.34);
    for (var i = 0; i < totalSlides; i++) {
      final x0 = i * unitWidth;
      final dir = i.isEven ? -1.0 : 1.0;
      ribbon1.quadraticBezierTo(
        x0 + unitWidth * 0.5,
        size.height * (0.34 + 0.18 * dir),
        x0 + unitWidth,
        size.height * 0.36,
      );
    }
    canvas.drawPath(ribbon1, wavePaint);

    final ribbon2 = Path()..moveTo(-unitWidth * 0.2, size.height * 0.76);
    for (var i = 0; i < totalSlides; i++) {
      final x0 = i * unitWidth;
      final dir = i.isEven ? 1.0 : -1.0;
      ribbon2.quadraticBezierTo(
        x0 + unitWidth * 0.5,
        size.height * (0.76 + 0.14 * dir),
        x0 + unitWidth,
        size.height * 0.74,
      );
    }
    canvas.drawPath(
      ribbon2,
      wavePaint
        ..color = const Color(0x1493C5FD)
        ..strokeWidth = unitWidth * 0.15,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ContinuousStripPainter oldDelegate) =>
      oldDelegate.slideIndex != slideIndex ||
      oldDelegate.totalSlides != totalSlides ||
      oldDelegate.spanSlides != spanSlides;
}

/// Pixel 11 Pro 20:9 hardware frame with slim titanium-inspired rail, side power
/// and volume buttons, punch-hole camera, and Android `10:00` status bar.
class PixelProDeviceFrame extends StatelessWidget {
  const PixelProDeviceFrame({
    super.key,
    required this.child,
    required this.statusBarBrightness,
    this.displayWidth = 260,
    this.screenLogicalSize = kPixel11ProScreenSize,
    this.clockText = '10:00',
    this.showOuterShadow = true,
  });

  final Widget child;
  final Brightness statusBarBrightness;
  final double displayWidth;
  final Size screenLogicalSize;
  final String clockText;
  final bool showOuterShadow;

  static const double _bezel = 7.5;
  static const double _buttonOverhang = 2.5;
  static const double _outerRadius = 36.0;
  static const double _innerRadius = 29.0;
  static const double _statusBarHeight = 32.0;
  static const double _gestureBarHeight = 16.0;

  @override
  Widget build(BuildContext context) {
    final bodyWidth = screenLogicalSize.width + _bezel * 2;
    final bodyHeight = screenLogicalSize.height + _bezel * 2;
    final totalWidth = bodyWidth + _buttonOverhang;
    final displayHeight = displayWidth * (bodyHeight / totalWidth);

    final statusForeground = statusBarBrightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1A1C22);

    return Container(
      width: displayWidth,
      height: displayHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          _outerRadius * (displayWidth / totalWidth),
        ),
        boxShadow: showOuterShadow
            ? const [
                BoxShadow(
                  color: Color(0x4D041133),
                  blurRadius: 32,
                  spreadRadius: -2,
                  offset: Offset(0, 16),
                ),
                BoxShadow(
                  color: Color(0x28041133),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: totalWidth,
          height: bodyHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Right-side power & volume hardware buttons
              Positioned(
                right: 0,
                top: 175,
                child: Container(
                  width: 3.5,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B758F),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 242,
                child: Container(
                  width: 3.5,
                  height: 78,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B758F),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(
                width: bodyWidth,
                height: bodyHeight,
                child: Container(
                  padding: const EdgeInsets.all(_bezel),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF232938),
                        Color(0xFF141822),
                        Color(0xFF1E2433),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_outerRadius),
                    border: Border.all(
                      color: const Color(0xFF5C667E),
                      width: 1.5,
                    ),
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
                            child: _AndroidClockStatusBar(
                              foreground: statusForeground,
                              clockText: clockText,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 5,
                            child: Center(
                              child: Container(
                                width: 112,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: statusForeground.withAlpha(115),
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders [PixelProDeviceFrame] with a perspective 3D tilt and extruded brushed
/// titanium side-wall thickness so slanted devices read as physical hardware.
class ExtrudedPixelProDeviceFrame extends StatelessWidget {
  const ExtrudedPixelProDeviceFrame({
    super.key,
    required this.child,
    required this.statusBarBrightness,
    this.displayWidth = 270,
    this.screenLogicalSize = kPixel11ProScreenSize,
    this.clockText = '10:00',
    this.rotateY = -0.22,
    this.rotateZ = -0.055,
    this.perspective = 0.0011,
    this.chassisDepth = 36.0,
    this.extrusionSlices = 22,
  });

  final Widget child;
  final Brightness statusBarBrightness;
  final double displayWidth;
  final Size screenLogicalSize;
  final String clockText;
  final double rotateY;
  final double rotateZ;
  final double perspective;
  final double chassisDepth;
  final int extrusionSlices;

  Matrix4 _transformAtDepth(double z, {double dx = 0, double dy = 0}) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..rotateY(rotateY)
      ..rotateZ(rotateZ);
    matrix.multiply(Matrix4.translationValues(dx, dy, z));
    return matrix;
  }

  @override
  Widget build(BuildContext context) {
    final bodyWidth = screenLogicalSize.width + PixelProDeviceFrame._bezel * 2;
    final bodyHeight =
        screenLogicalSize.height + PixelProDeviceFrame._bezel * 2;
    final totalWidth = bodyWidth + PixelProDeviceFrame._buttonOverhang;
    final scale = displayWidth / totalWidth;
    final displayHeight = bodyHeight * scale;
    final scaledBodyWidth = bodyWidth * scale;
    final scaledRadius = PixelProDeviceFrame._outerRadius * scale;

    final shadowDx = -math.sin(rotateY) * 26.0;
    final shadowDy = 20.0;

    return SizedBox(
      width: displayWidth,
      height: displayHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Soft directional ambient drop shadow behind the backplate.
          Transform(
            alignment: Alignment.center,
            transform: _transformAtDepth(
              chassisDepth,
              dx: shadowDx,
              dy: shadowDy,
            ),
            child: Container(
              width: scaledBodyWidth,
              height: displayHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(scaledRadius),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x52030C26),
                    blurRadius: 38,
                    spreadRadius: -2,
                  ),
                  BoxShadow(color: Color(0x2E041133), blurRadius: 16),
                ],
              ),
            ),
          ),

          // 2. Extruded brushed-titanium chassis slices back-to-front.
          for (var i = extrusionSlices; i >= 1; i--)
            Builder(
              builder: (context) {
                final t = i / extrusionSlices;
                final z = chassisDepth * t;
                final isBackEdge = i == extrusionSlices;
                final isFrontChamfer = i <= 2;
                final hasButtonBand = t >= 0.30 && t <= 0.72;

                final colors = isBackEdge
                    ? const [
                        Color(0xFF1A202E),
                        Color(0xFF2B3447),
                        Color(0xFF141925),
                      ]
                    : isFrontChamfer
                    ? const [
                        Color(0xFF8D9BB5),
                        Color(0xFFB2C0DA),
                        Color(0xFF7785A0),
                      ]
                    : const [
                        Color(0xFF3E485E),
                        Color(0xFF8390AB),
                        Color(0xFF535F7A),
                        Color(0xFF93A1BD),
                        Color(0xFF333C4F),
                      ];

                return Transform(
                  alignment: Alignment.center,
                  transform: _transformAtDepth(z),
                  child: SizedBox(
                    width: displayWidth,
                    height: displayHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (hasButtonBand) ...[
                          Positioned(
                            right: 0,
                            top: 175 * scale,
                            child: Container(
                              width: 3.5 * scale,
                              height: 44 * scale,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9AA8C4),
                                borderRadius: BorderRadius.circular(2 * scale),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 242 * scale,
                            child: Container(
                              width: 3.5 * scale,
                              height: 78 * scale,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8C9AB5),
                                borderRadius: BorderRadius.circular(2 * scale),
                              ),
                            ),
                          ),
                        ],
                        Container(
                          width: scaledBodyWidth,
                          height: displayHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(scaledRadius),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: colors,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // 3. Front glass bezel + live app screen at z = 0.
          Transform(
            alignment: Alignment.center,
            transform: _transformAtDepth(0),
            child: PixelProDeviceFrame(
              displayWidth: displayWidth,
              screenLogicalSize: screenLogicalSize,
              clockText: clockText,
              statusBarBrightness: statusBarBrightness,
              showOuterShadow: false,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _AndroidClockStatusBar extends StatelessWidget {
  const _AndroidClockStatusBar({
    required this.foreground,
    required this.clockText,
  });

  final Color foreground;
  final String clockText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Text(
            clockText,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13.5,
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

class _ProHeaderBlock extends StatelessWidget {
  const _ProHeaderBlock({
    required this.badge,
    required this.headline,
    required this.subtitle,
    required this.isLightBackdrop,
    this.textAlign = TextAlign.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String badge;
  final String headline;
  final String? subtitle;
  final bool isLightBackdrop;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final style = isLightBackdrop
        ? SlideBackdropStyle.softIce
        : SlideBackdropStyle.royalBlue;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        _PillBadge(label: badge, style: style),
        const SizedBox(height: 8),
        Text(
          headline,
          textAlign: textAlign,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 23.5,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.5,
            color: style.headlineColor,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: style.subtitleColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// Option A: Full Pixel 11 Pro inside frame (`360 × 720` @ 3x = `1080 × 2160`).
class PortraitFlatProSlide extends StatelessWidget {
  const PortraitFlatProSlide({
    super.key,
    required this.badge,
    required this.headline,
    this.subtitle,
    required this.slideIndex,
    this.totalSlides = 8,
    this.captionPlacement = CaptionPlacement.top,
    required this.statusBarBrightness,
    required this.child,
  });

  final String badge;
  final String headline;
  final String? subtitle;
  final int slideIndex;
  final int totalSlides;
  final CaptionPlacement captionPlacement;
  final Brightness statusBarBrightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = continuousBackdropIsLight(
      slideIndex,
      totalSlides: totalSlides,
    );
    final header = _ProHeaderBlock(
      badge: badge,
      headline: headline,
      subtitle: subtitle,
      isLightBackdrop: isLight,
    );
    final phone = PixelProDeviceFrame(
      displayWidth: 256,
      statusBarBrightness: statusBarBrightness,
      child: child,
    );

    return SizedBox(
      width: kPortraitTallSlideLogicalSize.width,
      height: kPortraitTallSlideLogicalSize.height,
      child: ContinuousCarouselBackdrop(
        slideIndex: slideIndex,
        totalSlides: totalSlides,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: captionPlacement == CaptionPlacement.top
                ? [header, const Spacer(), phone]
                : [phone, const Spacer(), header],
          ),
        ),
      ),
    );
  }
}

/// Option B: Enlarged Pixel 11 Pro bleeding smoothly for maximum UI readability.
class PortraitBleedProSlide extends StatelessWidget {
  const PortraitBleedProSlide({
    super.key,
    required this.badge,
    required this.headline,
    this.subtitle,
    required this.slideIndex,
    this.totalSlides = 8,
    this.captionPlacement = CaptionPlacement.top,
    required this.statusBarBrightness,
    required this.child,
    this.callout,
    this.calloutAlignment = Alignment.bottomLeft,
  });

  final String badge;
  final String headline;
  final String? subtitle;
  final int slideIndex;
  final int totalSlides;
  final CaptionPlacement captionPlacement;
  final Brightness statusBarBrightness;
  final Widget child;
  final Widget? callout;
  final Alignment calloutAlignment;

  @override
  Widget build(BuildContext context) {
    final isLight = continuousBackdropIsLight(
      slideIndex,
      totalSlides: totalSlides,
    );
    final isMidnight = slideIndex >= totalSlides - 2;
    final header = _ProHeaderBlock(
      badge: badge,
      headline: headline,
      subtitle: subtitle,
      isLightBackdrop: isLight,
    );

    final bottomScrimColors = isLight
        ? const [Color(0x00E5EEFF), Color(0xDCE5EEFF), Color(0xFFE5EEFF)]
        : isMidnight
        ? const [Color(0x000A1632), Color(0xE60A1632), Color(0xFF070E1F)]
        : const [Color(0x00133A9E), Color(0xE0102F85), Color(0xFF0B236B)];

    return SizedBox(
      width: kPortraitTallSlideLogicalSize.width,
      height: kPortraitTallSlideLogicalSize.height,
      child: ContinuousCarouselBackdrop(
        slideIndex: slideIndex,
        totalSlides: totalSlides,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: captionPlacement == CaptionPlacement.top
              ? [
                  Positioned(
                    top: 22,
                    left: 20,
                    right: 20,
                    child: Center(child: header),
                  ),
                  Positioned(
                    top: 132,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: PixelProDeviceFrame(
                        displayWidth: 306,
                        statusBarBrightness: statusBarBrightness,
                        child: child,
                      ),
                    ),
                  ),
                  if (callout != null)
                    Positioned(
                      bottom: 28,
                      left: calloutAlignment.x <= 0 ? 16 : null,
                      right: calloutAlignment.x > 0 ? 16 : null,
                      child: callout!,
                    ),
                ]
              : [
                  Positioned(
                    top: 6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: PixelProDeviceFrame(
                        displayWidth: 256,
                        statusBarBrightness: statusBarBrightness,
                        child: child,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 160,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: bottomScrimColors,
                        ),
                      ),
                    ),
                  ),
                  if (callout != null)
                    Positioned(
                      bottom: 166,
                      left: calloutAlignment.x <= 0 ? 16 : null,
                      right: calloutAlignment.x > 0 ? 16 : null,
                      child: callout!,
                    ),
                  Positioned(
                    bottom: 22,
                    left: 20,
                    right: 20,
                    child: Center(child: header),
                  ),
                ],
        ),
      ),
    );
  }
}

/// Option C: 3D perspective-slanted Pixel 11 Pro with optional floating callout.
class PortraitSlantedProSlide extends StatelessWidget {
  const PortraitSlantedProSlide({
    super.key,
    required this.badge,
    required this.headline,
    this.subtitle,
    required this.slideIndex,
    this.totalSlides = 8,
    this.captionPlacement = CaptionPlacement.top,
    required this.statusBarBrightness,
    required this.child,
    this.callout,
  });

  final String badge;
  final String headline;
  final String? subtitle;
  final int slideIndex;
  final int totalSlides;
  final CaptionPlacement captionPlacement;
  final Brightness statusBarBrightness;
  final Widget child;
  final Widget? callout;

  @override
  Widget build(BuildContext context) {
    final isLight = continuousBackdropIsLight(
      slideIndex,
      totalSlides: totalSlides,
    );
    final header = _ProHeaderBlock(
      badge: badge,
      headline: headline,
      subtitle: subtitle,
      isLightBackdrop: isLight,
    );

    final tiltedPhone = ExtrudedPixelProDeviceFrame(
      displayWidth: 270,
      rotateY: -0.22,
      rotateZ: -0.055,
      chassisDepth: 36,
      statusBarBrightness: statusBarBrightness,
      child: child,
    );

    return SizedBox(
      width: kPortraitTallSlideLogicalSize.width,
      height: kPortraitTallSlideLogicalSize.height,
      child: ContinuousCarouselBackdrop(
        slideIndex: slideIndex,
        totalSlides: totalSlides,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (captionPlacement == CaptionPlacement.top)
              Positioned(
                top: 22,
                left: 20,
                right: 20,
                child: Center(child: header),
              ),
            Positioned(
              top: captionPlacement == CaptionPlacement.top ? 136 : 10,
              left: 44,
              right: 14,
              child: Center(child: tiltedPhone),
            ),
            if (callout != null)
              Positioned(left: 16, bottom: 42, child: callout!),
            if (captionPlacement == CaptionPlacement.bottom)
              Positioned(
                bottom: 22,
                left: 20,
                right: 20,
                child: Center(child: header),
              ),
          ],
        ),
      ),
    );
  }
}

/// Option D: Panoramic 2-Slide Split Hero (`720 × 720` @ 3x = `2160 × 2160`,
/// sliced into `01` and `02`) with extruded 3D phones bridging across the
/// carousel seam without slicing floating callout text mid-word.
class PanoramicSplitHeroSlide extends StatelessWidget {
  const PanoramicSplitHeroSlide({
    super.key,
    required this.leftBadge,
    required this.leftHeadline,
    required this.leftSubtitle,
    required this.leftPhone,
    required this.rightBadge,
    required this.rightHeadline,
    required this.rightSubtitle,
    required this.rightPhone,
    required this.bridgeCallout,
    this.slideIndex = 0,
    this.totalSlides = 8,
  });

  final String leftBadge;
  final String leftHeadline;
  final String leftSubtitle;
  final Widget leftPhone;
  final String rightBadge;
  final String rightHeadline;
  final String rightSubtitle;
  final Widget rightPhone;
  final Widget bridgeCallout;
  final int slideIndex;
  final int totalSlides;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kPanoramicPairLogicalSize.width,
      height: kPanoramicPairLogicalSize.height,
      child: ContinuousCarouselBackdrop(
        slideIndex: slideIndex,
        totalSlides: totalSlides,
        spanSlides: 2,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Slide 1 (Left half: top caption + extruded 3D Pixel 11 Pro cleanly inside Slide 1)
            Positioned(
              top: 22,
              left: 20,
              width: 320,
              child: _ProHeaderBlock(
                badge: leftBadge,
                headline: leftHeadline,
                subtitle: leftSubtitle,
                isLightBackdrop: false,
                textAlign: TextAlign.left,
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
            Positioned(
              top: 146,
              left: 48,
              child: ExtrudedPixelProDeviceFrame(
                displayWidth: 274,
                rotateY: -0.20,
                rotateZ: -0.055,
                chassisDepth: 36,
                statusBarBrightness: Brightness.light,
                child: leftPhone,
              ),
            ),

            // Slide 2 (Right half: counter-angled extruded Pixel 11 Pro + alternating bottom caption)
            Positioned(
              top: -28,
              right: 22,
              child: ExtrudedPixelProDeviceFrame(
                displayWidth: 274,
                rotateY: 0.20,
                rotateZ: 0.045,
                chassisDepth: 36,
                statusBarBrightness: Brightness.light,
                child: rightPhone,
              ),
            ),
            Positioned(
              left: 360,
              right: 0,
              bottom: 0,
              height: 162,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x001A56DB),
                      Color(0xE6143FB0),
                      Color(0xFF103596),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 22,
              left: 380,
              width: 320,
              child: _ProHeaderBlock(
                badge: rightBadge,
                headline: rightHeadline,
                subtitle: rightSubtitle,
                isLightBackdrop: false,
                textAlign: TextAlign.right,
                crossAxisAlignment: CrossAxisAlignment.end,
              ),
            ),

            // Keep floating callout card strictly inside Slide 2 (no mid-word seam cut)
            Positioned(left: 376, top: 446, width: 238, child: bridgeCallout),
          ],
        ),
      ),
    );
  }
}

/// Crisp elevated floating callout card for pop-out / panoramic bridges.
class FloatingMetricCallout extends StatelessWidget {
  const FloatingMetricCallout({
    super.key,
    required this.eyebrow,
    required this.value,
    required this.detail,
    this.accentColor = const Color(0xFF1A56DB),
  });

  final String eyebrow;
  final String value;
  final String detail;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE7FF), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D041133),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                eyebrow,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: accentColor,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0C2254),
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
