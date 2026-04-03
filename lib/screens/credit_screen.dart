import 'dart:ui';

import 'package:flutter/material.dart';

class CreditScreen extends StatelessWidget {
  const CreditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _CreditsBackground(),
          SafeArea(
            child: Column(
              children: [
                _CreditsAppBar(
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: const _CreditsCard(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditsBackground extends StatelessWidget {
  const _CreditsBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF6F9FF),
            Color(0xFFEAF1FF),
            Color(0xFFFFF6E8),
            Color(0xFFFFFDF8),
          ],
        ),
      ),
      child: Stack(
        children: [
          const _BlurBlob(
            alignment: Alignment.topRight,
            size: 280,
            colors: [Color(0x33FFD166), Color(0x00FFD166)],
            offset: Offset(100, -80),
          ),
          const _BlurBlob(
            alignment: Alignment.centerLeft,
            size: 260,
            colors: [Color(0x331D5BFF), Color(0x001D5BFF)],
            offset: Offset(-120, 10),
          ),
          const _BlurBlob(
            alignment: Alignment.bottomRight,
            size: 320,
            colors: [Color(0x33FF7B54), Color(0x00FF7B54)],
            offset: Offset(100, 150),
          ),
          Positioned(
            left: 28,
            top: 120,
            child: Opacity(
              opacity: 0.08,
              child: Text(
                'f\'(x)',
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: 120,
            child: Opacity(
              opacity: 0.08,
              child: Text(
                'x^2',
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final List<Color> colors;
  final Offset offset;

  const _BlurBlob({
    required this.alignment,
    required this.size,
    required this.colors,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: colors,
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditsAppBar extends StatelessWidget {
  final VoidCallback onBack;

  const _CreditsAppBar({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x142E5AAC),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1D5BFF),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Credits',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D2045),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditsCard extends StatelessWidget {
  const _CreditsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFE9EEFF),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2E5AAC),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x0F2E5AAC),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          _HeroBadge(),
          SizedBox(height: 20),
          Text(
            'Derivative Damath',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0D2045),
              letterSpacing: -0.8,
              height: 1.05,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'A strategy board game built to make learning derivatives more engaging, competitive, and memorable.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF5F6F8F),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 26),
          _CreditSection(
            title: 'Original Concept by',
            accent: Color(0xFFFFB238),
            names: ['Jonwille Mark Castro'],
          ),
          SizedBox(height: 18),
          _AccentDivider(),
          SizedBox(height: 18),
          _CreditSection(
            title: 'Developers',
            accent: Color(0xFF1D5BFF),
            names: [
              'Cliff John Mapula',
              'Christian Awanin',
              'Jessa Benitez',
            ],
          ),
          SizedBox(height: 22),
          Text(
            'Thank you for playing and supporting the project.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B778C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD166),
            Color(0xFFFF9F43),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33FFB238),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.workspace_premium_rounded,
          color: Colors.white,
          size: 42,
        ),
      ),
    );
  }
}

class _CreditSection extends StatelessWidget {
  final String title;
  final Color accent;
  final List<String> names;

  const _CreditSection({
    required this.title,
    required this.accent,
    required this.names,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...names.map(
          (name) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF13213F),
                letterSpacing: -0.3,
                height: 1.15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccentDivider extends StatelessWidget {
  const _AccentDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [
                  Color(0x001D5BFF),
                  Color(0x661D5BFF),
                  Color(0xFFFFD166),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFFFFB238),
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFD166),
                  Color(0x661D5BFF),
                  Color(0x001D5BFF),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
