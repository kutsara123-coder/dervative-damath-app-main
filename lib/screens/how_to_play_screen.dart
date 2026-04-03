// how_to_play_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:derivative_damath/models/chip_model.dart';
import 'package:derivative_damath/models/move_history_model.dart';
import 'package:derivative_damath/utils/score_calculator.dart';
import 'package:derivative_damath/widgets/chip_widget.dart';

/// A screen that explains how to play Derivative Damath.
/// Contains game objective, movement rules, capture rules,
/// must capture rule, timer system, derivative computation rules,
/// scoring system, and example scenarios.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background layer matching home screen style
          const _BackgroundLayer(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                _CustomAppBar(
                  title: 'How to Play',
                  onBack: () => Navigator.of(context).pop(),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    child: Column(
                      children: const [
                        // Game Objective
                        _SectionCard(
                          title: 'Game Objective',
                          icon: Icons.flag,
                          color: Color(0xFF1D5BFF),
                          content: _ObjectiveContent(),
                        ),
                        SizedBox(height: 14),

                        // Movement Rules
                        _SectionCard(
                          title: 'Movement and Dama',
                          icon: Icons.directions_walk,
                          color: Color(0xFF2E7BFF),
                          content: _MovementContent(),
                        ),
                        SizedBox(height: 14),

                        // Capture Rules
                        _SectionCard(
                          title: 'Capture Rules',
                          icon: Icons.gps_fixed,
                          color: Color(0xFFE94B4B),
                          content: _CaptureContent(),
                        ),
                        SizedBox(height: 14),

                        // Must Capture Rule
                        _SectionCard(
                          title: 'Mandatory Capture',
                          icon: Icons.lock,
                          color: Color(0xFFFF6B35),
                          content: _MustCaptureContent(),
                        ),
                        SizedBox(height: 14),

                        // Timer System
                        _SectionCard(
                          title: 'Timer Rules',
                          icon: Icons.timer,
                          color: Color(0xFF00BFA5),
                          content: _TimerContent(),
                        ),
                        SizedBox(height: 14),

                        // Derivative Computation Rules
                        _SectionCard(
                          title: 'Capture Computation',
                          icon: Icons.calculate,
                          color: Color(0xFF8B5CF6),
                          content: _DerivativeContent(),
                        ),
                        SizedBox(height: 14),

                        // Scoring System
                        _SectionCard(
                          title: 'Scoring and Winner',
                          icon: Icons.emoji_events,
                          color: Color(0xFFF6A000),
                          content: _ScoringContent(),
                        ),
                        SizedBox(height: 14),

                        // Example Scenarios
                        _SectionCard(
                          title: 'Worked Examples',
                          icon: Icons.lightbulb,
                          color: Color(0xFF17A85E),
                          content: _ExampleContent(),
                        ),
                        SizedBox(height: 20),

                        // Back to Menu Button
                        _BackButton(),
                        SizedBox(height: 16),
                      ],
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

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF3F7FF),
            Color(0xFFEAF2FF),
            Color(0xFFEFEFFF),
            Color(0xFFEBE8FF),
          ],
          stops: [0.0, 0.45, 0.78, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Soft blobs
          const _Blob(
            alignment: Alignment.topRight,
            size: 300,
            colors: [Color(0x3300B2FF), Color(0x0000B2FF)],
            offset: Offset(100, -60),
          ),
          const _Blob(
            alignment: Alignment.bottomLeft,
            size: 350,
            colors: [Color(0x332C63FF), Color(0x002C63FF)],
            offset: Offset(-120, 100),
          ),
          const _Blob(
            alignment: Alignment.bottomRight,
            size: 320,
            colors: [Color(0x332A8CFF), Color(0x002A8CFF)],
            offset: Offset(140, 180),
          ),

          // Faint symbols
          Positioned(
            left: 18,
            top: 100,
            child: Opacity(
              opacity: 0.10,
              child: Text(
                'dy\ndx',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade700,
                  height: 1.0,
                ),
              ),
            ),
          ),
          Positioned(
            right: 26,
            top: 180,
            child: Opacity(
              opacity: 0.08,
              child: Text(
                '∫',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final List<Color> colors;
  final Offset offset;

  const _Blob({
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
          imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: colors, stops: const [0.0, 1.0]),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _CustomAppBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          // Back button
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.90),
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
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget content;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2E5AAC),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x0F2E5AAC),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D2045),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            content,
          ],
        ),
      ),
    );
  }
}

class _ObjectiveContent extends StatelessWidget {
  const _ObjectiveContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Derivative Damath combines Damath with derivatives. The app uses the standard opening setup, then decides the first player with a coin toss.',
          style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
        ),
        const SizedBox(height: 12),
        const _BulletPoint(
          text: 'Start from the standard 12-vs-12 board setup',
        ),
        const _BulletPoint(
          text: 'The app performs the coin toss automatically before the match',
        ),
        const _BulletPoint(
          text: 'Players move alternately and pass is not allowed',
        ),
        const _BulletPoint(
          text:
              'The app records moves in move history instead of a paper scoresheet',
        ),
        const _BulletPoint(
          text: 'Win by finishing with the greater accumulated total score',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD4E6FF)),
          ),
          child: Text(
            'A game can end when the 20-minute match clock expires, moves repeat, a player has no legal move, or an opponent chip is cornered.',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _MovementContent extends StatelessWidget {
  const _MovementContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SubHeader(text: 'Regular Chips'),
        const SizedBox(height: 8),
        Text(
          'Regular chips slide diagonally forward by one tile when making a normal move.',
          style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 14),
        ),
        const SizedBox(height: 10),
        const _BulletPoint(
          text: 'A regular move must end on an empty diagonal tile',
        ),
        const _BulletPoint(
          text: 'Regular chips do not slide backward on normal moves',
        ),
        const _BulletPoint(
          text:
              'A chip becomes Dama when it stops on (1,0), (3,0), (5,0), (7,0), (0,7), (2,7), (4,7), or (6,7)',
        ),
        const SizedBox(height: 16),
        const _SubHeader(text: 'Dama Chips'),
        const SizedBox(height: 8),
        Text(
          'A Dama uses the same chip design as the game board, with the gold star badge shown on the live pieces.',
          style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ChipShowcase(
              label: 'Regular',
              chip: ChipModel(owner: 1, id: 9001, x: 0, y: 0, terms: {4: -1}),
            ),
            _ChipShowcase(
              label: 'Dama',
              chip: ChipModel(
                owner: 1,
                id: 9002,
                x: 0,
                y: 0,
                terms: {3: -3},
                isDama: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _BulletPoint(
          text:
              'A Dama can slide diagonally forward or backward through any number of empty squares',
        ),
        const _BulletPoint(
          text:
              'A Dama cannot pass through another chip while sliding or while choosing a landing square',
        ),
      ],
    );
  }
}

class _CaptureContent extends StatelessWidget {
  const _CaptureContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Captures follow the thesis rule set used by the app:',
          style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
        ),
        const SizedBox(height: 12),
        const _BulletPoint(
          text:
              'The taker chip jumps diagonally over exactly one opponent chip',
        ),
        const _BulletPoint(
          text: 'The landing square after the jump must be empty',
        ),
        const _BulletPoint(text: 'The captured chip is removed from the board'),
        const _BulletPoint(
          text:
              'Chain captures are allowed when another capture remains available',
        ),
        const _BulletPoint(
          text:
              'Regular chips may capture as the board position allows, even though normal movement is forward only',
        ),
        const _BulletPoint(
          text:
              'A Dama may choose any empty landing square after the captured chip, as long as no other chip blocks the path',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F2FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD4E6FF)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D5BFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1D5BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Example: a chip at (2,1) can capture a chip at (3,2) by landing at (4,3).',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MustCaptureContent extends StatelessWidget {
  const _MustCaptureContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The "Must Capture" rule is enforced in Derivative Damath:',
          style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
        ),
        const SizedBox(height: 12),
        const _BulletPoint(
          text: 'If any of your chips can capture, you MUST capture',
        ),
        const _BulletPoint(
          text: 'You cannot make regular moves when capture is available',
        ),
        const _BulletPoint(text: 'Only chips that can capture are selectable'),
        const _BulletPoint(
          text: 'Chain captures must be completed if possible',
        ),
        const _BulletPoint(
          text:
              'If a Dama capture and a regular-chip capture are both available, the Dama capture prevails',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFE0B2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock,
                  color: Color(0xFFFF6B35),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Capturing chips glow green. If the glowing chip is a Dama, the regular capture options are locked out.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimerContent extends StatelessWidget {
  const _TimerContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Before a match starts, players can choose the 20-minute game timer or untimed play, and they can also choose the 2-minute move timer or untimed moves.',
          style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
        ),
        const SizedBox(height: 12),
        const _BulletPoint(
          text: 'You can enable either timer, both timers, or neither timer',
        ),
        const _BulletPoint(text: '2 minutes (120 seconds) per turn'),
        const _BulletPoint(
          text:
              'The move timer pauses while a mandatory capture or capture chain is in progress',
        ),
        const _BulletPoint(text: 'The full match clock lasts 20 minutes total'),
        const _BulletPoint(
          text:
              'When the 20-minute match clock expires, the game ends and the higher final score wins',
        ),
        const SizedBox(height: 12),
        const _SubHeader(text: 'App Behavior:'),
        const SizedBox(height: 8),
        Text(
          'The app keeps the move timer and match timer visible in the center HUD. If a player lets the 2-minute move timer expire, the app makes one random legal auto-move, shows a short 3-second notice, and then the opponent takes the next turn.',
          style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F7F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB2DFDB)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timer,
                  color: Color(0xFF00BFA5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Timed Mode now matches the thesis better: captures pause the move timer, but the 20-minute match clock keeps running.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DerivativeContent extends StatelessWidget {
  const _DerivativeContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Each chip contains a polynomial. Capture scores are computed like this:',
          style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
        ),
        const SizedBox(height: 12),
        const _BulletPoint(
          text:
              'Combine the taker chip and taken chip using the landing tile operation',
        ),
        const _BulletPoint(text: 'Take the derivative of the combined result'),
        const _BulletPoint(text: 'Evaluate the derivative at x = |x - y|'),
        const _BulletPoint(
          text: 'Apply the Dama multiplier if the taker or taken chip is Dama',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4EEFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3D6FF)),
          ),
          child: Text(
            'Rule 6 in the thesis is the exact capture computation used by the game: landing tile operation first, derivative second, evaluation at |x - y| third.',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _SubHeader(text: 'Basic Derivative Rules:'),
        const SizedBox(height: 10),
        _RuleExample(
          formula: 'd/dx(x^n) = n*x^(n-1)',
          example: 'd/dx(x^3) = 3x^2',
        ),
        _RuleExample(formula: 'd/dx(c) = 0', example: 'd/dx(5) = 0'),
        _RuleExample(formula: 'd/dx(cx) = c', example: 'd/dx(4x) = 4'),
        const SizedBox(height: 14),
        const _SubHeader(text: 'Scoring Formula:'),
        const SizedBox(height: 8),
        Text(
          '1. Combine taker chip with taken chip using operation (+, -, x, /)\n'
          '2. Take derivative of the resulting combination\n'
          '3. Evaluate at x = |x_coord - y_coord| (1, 3, 5, or 7)\n'
          '4. Double the score if either the taker or taken chip is Dama\n'
          '5. Quadruple the score if both chips are Dama',
          style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 13),
        ),
      ],
    );
  }
}

class _ScoringContent extends StatelessWidget {
  const _ScoringContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Points are earned based on your move:',
          style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 14),
        ),
        const SizedBox(height: 12),
        const _ScoreItem(
          points: 'Calculated',
          description:
              'Each capture uses the derivative result from the landing tile',
        ),
        const _ScoreItem(
          points: '2x / 4x',
          description:
              'A Dama capture is doubled, and Dama versus Dama is quadrupled',
        ),
        const _ScoreItem(
          points: 'No +1',
          description: 'Chain captures do not get extra bonus points',
        ),
        const _ScoreItem(
          points: 'Endgame',
          description:
              'Remaining chips add the absolute value of their coefficients, with Dama chips doubled',
        ),
        const _ScoreItem(
          points: 'Winner',
          description:
              'After adding the endgame chip bonuses, the higher total score wins',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFE4B3)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6A000).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(0xFFF6A000),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The thesis bonuses now match the game: Dama multipliers and remaining-chip bonuses are included, but there is no extra chain-capture bonus.',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExampleContent extends StatelessWidget {
  const _ExampleContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WorkedCaptureExample(
          number: 1,
          title: 'Simple Capture',
          description:
              'This matches the thesis example where -x^4 captures -x^4 and lands on a multiplication tile at (4,5).',
          movingChip: ChipModel(owner: 1, id: 9101, x: 2, y: 3, terms: {4: -1}),
          targetChip: ChipModel(owner: 2, id: 9102, x: 3, y: 4, terms: {4: -1}),
          operationSymbol: 'x',
          landingX: 4,
          landingY: 5,
        ),
        const SizedBox(height: 14),
        _WorkedCaptureExample(
          number: 2,
          title: 'Dama Multiplier',
          description:
              'This follows the thesis Dama example where a Dama -3x^3 captures 66x^3 on a plus tile at (1,4).',
          movingChip: ChipModel(
            owner: 1,
            id: 9103,
            x: 4,
            y: 7,
            terms: {3: -3},
            isDama: true,
          ),
          targetChip: ChipModel(owner: 2, id: 9104, x: 3, y: 6, terms: {3: 66}),
          operationSymbol: '+',
          landingX: 1,
          landingY: 4,
        ),
        const SizedBox(height: 14),
        _EndgameBonusExample(number: 3),
      ],
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7, right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1D5BFF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String text;

  const _SubHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: Color(0xFF0D2045),
      ),
    );
  }
}

class _RuleExample extends StatelessWidget {
  final String formula;
  final String example;

  const _RuleExample({required this.formula, required this.example});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.functions,
              color: Color(0xFF8B5CF6),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                children: [
                  TextSpan(
                    text: formula,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: Color(0xFF0D2045),
                    ),
                  ),
                  const TextSpan(text: '  →  '),
                  TextSpan(text: example),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String points;
  final String description;

  const _ScoreItem({required this.points, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF6A000), Color(0xFFE69500)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF6A000).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              points,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipShowcase extends StatelessWidget {
  final String label;
  final ChipModel chip;

  const _ChipShowcase({required this.label, required this.chip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChipWidget(chip: chip, size: 62),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Color(0xFF0D2045),
          ),
        ),
      ],
    );
  }
}

class _WorkedCaptureExample extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final ChipModel movingChip;
  final ChipModel targetChip;
  final String operationSymbol;
  final int landingX;
  final int landingY;

  const _WorkedCaptureExample({
    required this.number,
    required this.title,
    required this.description,
    required this.movingChip,
    required this.targetChip,
    required this.operationSymbol,
    required this.landingX,
    required this.landingY,
  });

  @override
  Widget build(BuildContext context) {
    final breakdown = ScoreCalculator.generateCalculationBreakdown(
      movingChipTerms: movingChip.terms,
      targetChipTerms: targetChip.terms,
      operationSymbol: operationSymbol,
      targetX: landingX,
      targetY: landingY,
      isMovingChipDama: movingChip.isDama,
      isTargetChipDama: targetChip.isDama,
    );

    if (breakdown == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF17A85E), Color(0xFF148F4D)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF0D2045),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF17A85E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  breakdown.finalScore.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Color(0xFF17A85E),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChipWidget(chip: movingChip, size: 52),
              const SizedBox(width: 10),
              _OperationBadge(symbol: breakdown.operation),
              const SizedBox(width: 10),
              ChipWidget(chip: targetChip, size: 52),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Landing square: ($landingX,$landingY)  ->  x = |$landingX - $landingY| = ${breakdown.evaluationPoint}',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...breakdown.steps.map((step) => _WorkedStep(step: step)),
        ],
      ),
    );
  }
}

class _WorkedStep extends StatelessWidget {
  final CalculationStep step;

  const _WorkedStep({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${step.stepNumber}: ${step.title}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Color(0xFF0D2045),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            step.description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.expression,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF334E7D),
            ),
          ),
          if (step.result != null) ...[
            const SizedBox(height: 4),
            Text(
              'Result: ${step.result}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Color(0xFF17A85E),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OperationBadge extends StatelessWidget {
  final String symbol;

  const _OperationBadge({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC24A), Color(0xFFFF8C2A)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EndgameBonusExample extends StatelessWidget {
  final int number;

  const _EndgameBonusExample({required this.number});

  @override
  Widget build(BuildContext context) {
    final total = ScoreCalculator.calculateRemainingChipsScore([
      {
        'terms': {4: 78},
        'isDama': false,
      },
      {
        'terms': {1: -55},
        'isDama': false,
      },
      {
        'terms': {3: -3},
        'isDama': true,
      },
    ]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF17A85E), Color(0xFF148F4D)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Endgame Bonus',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF0D2045),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF17A85E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  total.toStringAsFixed(2),
                  style: const TextStyle(
                    color: Color(0xFF17A85E),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'At game end, every remaining chip adds the absolute value of its coefficient. A remaining Dama is doubled.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ChipShowcase(
                label: '78x^4 -> 78',
                chip: ChipModel(owner: 1, id: 9201, x: 0, y: 0, terms: {4: 78}),
              ),
              _ChipShowcase(
                label: '-55x -> 55',
                chip: ChipModel(
                  owner: 1,
                  id: 9202,
                  x: 0,
                  y: 0,
                  terms: {1: -55},
                ),
              ),
              _ChipShowcase(
                label: '-3x^3 Dama -> 6',
                chip: ChipModel(
                  owner: 1,
                  id: 9203,
                  x: 0,
                  y: 0,
                  terms: {3: -3},
                  isDama: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Total = 78 + 55 + (3 x 2) = 139',
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: Color(0xFF334E7D),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipDisplay extends StatelessWidget {
  final String chip;
  final bool isDama;

  const _ChipDisplay({required this.chip, this.isDama = false});

  @override
  Widget build(BuildContext context) {
    return ChipWidget(
      chip: ChipModel(
        owner: 1,
        id: 9999,
        x: 0,
        y: 0,
        terms: _parseExampleTerms(chip),
        isDama: isDama,
      ),
      size: 48,
    );
  }

  Map<int, int> _parseExampleTerms(String label) {
    if (label == '2x³') return {3: 2};
    if (label == '4x²') return {2: 4};
    if (label == 'x³') return {3: 1};
    return {1: 1};
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7BFF), Color(0xFF0D49E9)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7BFF).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Back to Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
