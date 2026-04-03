// home_screen.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/dexter_engine.dart';
import '../utils/lan_multiplayer_session.dart';
import '../utils/sound_service.dart';
import 'credit_screen.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';

const int _lanDefaultPort = 4040;
bool get _showQuitButton =>
    !kIsWeb && defaultTargetPlatform != TargetPlatform.iOS;

Future<void> _closeApp() async {
  await SystemNavigator.pop();
}

Future<void> _settleUiTransition() async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await Future<void>.delayed(const Duration(milliseconds: 140));
  await WidgetsBinding.instance.endOfFrame;
}

class _GameStartSelection {
  final bool useGameTimer;
  final bool useMoveTimer;
  final String player1Name;
  final String player2Name;

  const _GameStartSelection({
    required this.useGameTimer,
    required this.useMoveTimer,
    this.player1Name = 'Player 1',
    this.player2Name = 'Player 2',
  });
}

enum _PvpSetupMode { samePhone, hostLan, joinLan }

class _LanHostSelection {
  final bool useGameTimer;
  final bool useMoveTimer;
  final String playerName;

  const _LanHostSelection({
    required this.useGameTimer,
    required this.useMoveTimer,
    required this.playerName,
  });
}

class _LanJoinSelection {
  final String playerName;
  final String hostAddress;

  const _LanJoinSelection({
    required this.playerName,
    required this.hostAddress,
  });
}

/// Shows difficulty selection for PvC mode
Future<void> _showDifficultyModal(BuildContext context, String mode) async {
  if (mode == 'PvP') {
    final pvpMode = await _showPvpSetupModeModal(context);
    if (pvpMode == null || !context.mounted) {
      return;
    }
    await _settleUiTransition();
    if (!context.mounted) {
      return;
    }

    switch (pvpMode) {
      case _PvpSetupMode.samePhone:
        final selection = await _showGameStartModal(context, mode, null);
        if (selection == null || !context.mounted) {
          return;
        }
        await _settleUiTransition();
        if (!context.mounted) {
          return;
        }

        final startingPlayer = await _showFirstMoveModal(
          context,
          mode: mode,
          player1Name: selection.player1Name,
          opponentName: selection.player2Name,
        );

        if (startingPlayer == null || !context.mounted) {
          return;
        }
        await _settleUiTransition();
        if (!context.mounted) {
          return;
        }

        _startGame(
          context,
          mode: mode,
          useGameTimer: selection.useGameTimer,
          useMoveTimer: selection.useMoveTimer,
          startingPlayer: startingPlayer,
          player1Name: selection.player1Name,
          player2Name: selection.player2Name,
        );
        return;
      case _PvpSetupMode.hostLan:
        final hostSelection = await _showLanHostSetupModal(context);
        if (hostSelection == null || !context.mounted) {
          return;
        }
        await _settleUiTransition();
        if (!context.mounted) {
          return;
        }

        final startingPlayer = await _showFirstMoveModal(
          context,
          mode: 'LAN',
          player1Name: hostSelection.playerName,
          opponentName: 'Player 2',
        );

        if (startingPlayer == null || !context.mounted) {
          return;
        }
        await _settleUiTransition();
        if (!context.mounted) {
          return;
        }

        _showBusyDialog(context, 'Starting host...');
        try {
          final lanSession = await LanMultiplayerSession.host(
            playerName: hostSelection.playerName,
            port: _lanDefaultPort,
          );
          if (!context.mounted) {
            await lanSession.close();
            return;
          }

          Navigator.of(context, rootNavigator: true).pop();
          _startGame(
            context,
            mode: 'LAN',
            useGameTimer: hostSelection.useGameTimer,
            useMoveTimer: hostSelection.useMoveTimer,
            startingPlayer: startingPlayer,
            player1Name: hostSelection.playerName,
            player2Name: 'Waiting...',
            lanSession: lanSession,
          );
        } catch (error) {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showSetupError(context, 'Could not start the local host.\n$error');
          }
        }
        return;
      case _PvpSetupMode.joinLan:
        final joinSelection = await _showLanJoinSetupModal(context);
        if (joinSelection == null || !context.mounted) {
          return;
        }
        await _settleUiTransition();
        if (!context.mounted) {
          return;
        }

        _showBusyDialog(context, 'Connecting to host...');
        try {
          final lanSession = await LanMultiplayerSession.join(
            playerName: joinSelection.playerName,
            hostAddress: joinSelection.hostAddress,
            port: _lanDefaultPort,
          );
          if (!context.mounted) {
            await lanSession.close();
            return;
          }

          Navigator.of(context, rootNavigator: true).pop();
          _startGame(
            context,
            mode: 'LAN',
            useGameTimer: true,
            useMoveTimer: true,
            player1Name: 'Host',
            player2Name: joinSelection.playerName,
            lanSession: lanSession,
          );
        } catch (error) {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            _showSetupError(
              context,
              'Could not connect to that phone.\n\nMake sure both phones are on the same Wi-Fi or hotspot, then try again.',
            );
          }
        }
        return;
    }
  }

  if (mode != 'PvC') {
    if (mode == 'PvD') {
      final selection = await _showGameStartModal(context, mode, null);
      if (selection == null || !context.mounted) {
        return;
      }
      await _settleUiTransition();
      if (!context.mounted) {
        return;
      }

      final startingPlayer = await _showFirstMoveModal(
        context,
        mode: mode,
        player1Name: selection.player1Name,
        opponentName: DexterEngine.defaultName,
      );

      if (startingPlayer == null || !context.mounted) {
        return;
      }
      await _settleUiTransition();
      if (!context.mounted) {
        return;
      }

      _startGame(
        context,
        mode: mode,
        useGameTimer: selection.useGameTimer,
        useMoveTimer: selection.useMoveTimer,
        startingPlayer: startingPlayer,
        player1Name: selection.player1Name,
        player2Name: DexterEngine.defaultName,
      );
      return;
    }

    final selection = await _showGameStartModal(context, mode, null);
    if (selection == null || !context.mounted) {
      return;
    }
    await _settleUiTransition();
    if (!context.mounted) {
      return;
    }

    _startGame(
      context,
      mode: mode,
      useGameTimer: selection.useGameTimer,
      useMoveTimer: selection.useMoveTimer,
      player1Name: selection.player1Name,
      player2Name: selection.player2Name,
    );
    return;
  }

  SoundService().playClick();

  final difficulty = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.82,
            maxWidth: 460,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D5BFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    size: 36,
                    color: Color(0xFF1D5BFF),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Select Difficulty',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D2045),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your opponent\'s skill level',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B778C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                _DifficultyButton(
                  icon: Icons.sentiment_satisfied_outlined,
                  title: 'Easy',
                  subtitle: 'Grade 6 style - makes simple mistakes',
                  color: const Color(0xFF17A85E),
                  onTap: () {
                    SoundService().playClick();
                    Navigator.of(dialogContext).pop('easy');
                  },
                ),
                const SizedBox(height: 12),
                _DifficultyButton(
                  icon: Icons.sentiment_neutral_outlined,
                  title: 'Medium',
                  subtitle: 'Grade 12 / college style',
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    SoundService().playClick();
                    Navigator.of(dialogContext).pop('medium');
                  },
                ),
                const SizedBox(height: 12),
                _DifficultyButton(
                  icon: Icons.sentiment_very_dissatisfied_outlined,
                  title: 'Hard',
                  subtitle: 'Grandmaster challenge',
                  color: const Color(0xFFE94B4B),
                  onTap: () {
                    SoundService().playClick();
                    Navigator.of(dialogContext).pop('hard');
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    SoundService().playClick();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B778C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (difficulty == null || !context.mounted) {
    return;
  }
  await _settleUiTransition();
  if (!context.mounted) {
    return;
  }

  final selection = await _showGameStartModal(context, mode, difficulty);
  if (selection == null || !context.mounted) {
    return;
  }
  await _settleUiTransition();
  if (!context.mounted) {
    return;
  }

  final startingPlayer = await _showFirstMoveModal(
    context,
    difficulty: difficulty,
    mode: mode,
    player1Name: selection.player1Name,
    opponentName: 'Computer',
  );

  if (startingPlayer == null || !context.mounted) {
    return;
  }
  await _settleUiTransition();
  if (!context.mounted) {
    return;
  }

  _startGame(
    context,
    mode: mode,
    useGameTimer: selection.useGameTimer,
    useMoveTimer: selection.useMoveTimer,
    difficulty: difficulty,
    startingPlayer: startingPlayer,
    player1Name: selection.player1Name,
    player2Name: selection.player2Name,
  );
}

Future<_PvpSetupMode?> _showPvpSetupModeModal(BuildContext context) {
  SoundService().playClick();

  return showDialog<_PvpSetupMode>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.82,
            maxWidth: 460,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D5BFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_rounded,
                    size: 36,
                    color: Color(0xFF1D5BFF),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Player vs Player',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D2045),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose if you want one shared phone or two phones on the same Wi-Fi/hotspot.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B778C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                _DifficultyButton(
                  icon: Icons.smartphone_rounded,
                  title: 'Same Phone',
                  subtitle: 'Classic pass-and-play on one device',
                  color: const Color(0xFF17A85E),
                  onTap: () {
                    SoundService().playClick();
                    Navigator.of(dialogContext).pop(_PvpSetupMode.samePhone);
                  },
                ),
                const SizedBox(height: 12),
                _DifficultyButton(
                  icon: Icons.wifi_tethering_rounded,
                  title: 'Host Two Phones',
                  subtitle: 'Create a match from this device',
                  color: const Color(0xFF1D5BFF),
                  onTap: () {
                    SoundService().playClick();
                    Navigator.of(dialogContext).pop(_PvpSetupMode.hostLan);
                  },
                ),
                const SizedBox(height: 12),
                _DifficultyButton(
                  icon: Icons.link_rounded,
                  title: 'Join Two Phones',
                  subtitle: 'Connect to the host phone',
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    SoundService().playClick();
                    Navigator.of(dialogContext).pop(_PvpSetupMode.joinLan);
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    SoundService().playClick();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B778C),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<_LanHostSelection?> _showLanHostSetupModal(BuildContext context) async {
  SoundService().playClick();
  final nameController = TextEditingController();
  var useGameTimer = true;
  var useMoveTimer = true;

  try {
    return await showDialog<_LanHostSelection>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        _LanHostSelection buildSelection() {
          return _LanHostSelection(
            useGameTimer: useGameTimer,
            useMoveTimer: useMoveTimer,
            playerName: _sanitizePlayerName(nameController.text, 'Player 1'),
          );
        }

        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.82,
                maxWidth: 480,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D5BFF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_tethering_rounded,
                        size: 36,
                        color: Color(0xFF1D5BFF),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Host Two-Phone Match',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D2045),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your phone will become the host. Share the shown IP address with the other phone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B778C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(12),
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Enter a name',
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF1D5BFF),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4E6FF),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFD4E6FF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9E7FF)),
                      ),
                      child: const Text(
                        'Default port: 4040\nBoth phones should be on the same Wi-Fi or hotspot.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4D607C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _TimerChoiceSection(
                      title: 'Match Timer',
                      subtitle:
                          'Choose 20 minutes for the whole game or play untimed.',
                      timedLabel: '20 Minutes',
                      untimedLabel: 'Untimed',
                      useTimed: useGameTimer,
                      onChanged: (value) => setState(() {
                        useGameTimer = value;
                      }),
                    ),
                    const SizedBox(height: 14),
                    _TimerChoiceSection(
                      title: 'Move Timer',
                      subtitle:
                          'Choose 2 minutes per move or disable the move timer.',
                      timedLabel: '2 Minutes',
                      untimedLabel: 'Untimed',
                      useTimed: useMoveTimer,
                      onChanged: (value) => setState(() {
                        useMoveTimer = value;
                      }),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          SoundService().playClick();
                          FocusScope.of(dialogContext).unfocus();
                          await SystemChannels.textInput.invokeMethod<void>(
                            'TextInput.hide',
                          );
                          if (!dialogContext.mounted) {
                            return;
                          }
                          Navigator.of(dialogContext).pop(buildSelection());
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: const Color(0xFF0D2045),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continue as Host',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        SoundService().playClick();
                        FocusScope.of(dialogContext).unfocus();
                        await SystemChannels.textInput.invokeMethod<void>(
                          'TextInput.hide',
                        );
                        if (!dialogContext.mounted) {
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B778C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  } finally {
    nameController.dispose();
  }
}

Future<_LanJoinSelection?> _showLanJoinSetupModal(BuildContext context) async {
  SoundService().playClick();
  final nameController = TextEditingController();
  final hostController = TextEditingController();

  try {
    return await showDialog<_LanJoinSelection>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.82,
              maxWidth: 480,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.link_rounded,
                      size: 36,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Join Two-Phone Match',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0D2045),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the host phone\'s IP address. Example: 192.168.43.1',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B778C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(12),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      hintText: 'Enter a name',
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFFFF9800),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD4E6FF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD4E6FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hostController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Host IP Address',
                      hintText: '192.168.43.1',
                      prefixIcon: const Icon(
                        Icons.wifi_rounded,
                        color: Color(0xFFFF9800),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD4E6FF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFD4E6FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE2B6)),
                    ),
                    child: const Text(
                      'Default port: 4040\nThe host phone must already be waiting for a guest.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7A5A23),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        SoundService().playClick();
                        Navigator.of(dialogContext).pop(
                          _LanJoinSelection(
                            playerName: _sanitizePlayerName(
                              nameController.text,
                              'Player 2',
                            ),
                            hostAddress: hostController.text.trim(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: const Color(0xFFFF9800),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Join Match',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      SoundService().playClick();
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B778C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  } finally {
    nameController.dispose();
    hostController.dispose();
  }
}

void _showBusyDialog(BuildContext context, String label) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2045),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showSetupError(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Connection Problem'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

/// Difficulty button widget
class _DifficultyButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 14 : 16),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.3), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isCompact ? 42 : 48,
                  height: isCompact ? 42 : 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: isCompact ? 24 : 28),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: isCompact ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 13 : 14,
                          color: const Color(0xFF6B778C),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: color),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundLayer(),

          // Main card
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: _MainCard(screenHeight: size.height),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _startGame(
  BuildContext context, {
  required String mode,
  required bool useGameTimer,
  required bool useMoveTimer,
  String? difficulty,
  int startingPlayer = 1,
  String player1Name = 'Player 1',
  String player2Name = 'Player 2',
  LanMultiplayerSession? lanSession,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: mode,
          useGameTimer: useGameTimer,
          useMoveTimer: useMoveTimer,
          difficulty: difficulty,
          startingPlayer: startingPlayer,
          player1Name: player1Name,
          player2Name: player2Name,
          lanSession: lanSession,
        ),
      ),
    );
  });
}

String _sanitizePlayerName(String value, String fallback) {
  final cleaned = value
      .replaceAll(RegExp(r'[^A-Za-z ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (cleaned.isEmpty) {
    return fallback;
  }

  return cleaned.length > 12 ? cleaned.substring(0, 12).trimRight() : cleaned;
}

String _modeSubtitle(String mode, String? difficulty) {
  switch (mode) {
    case 'PvC':
      return '${_getDifficultyLabel(difficulty)} - Player vs Computer';
    case 'PvD':
      return 'Player vs ${DexterEngine.defaultName}';
    default:
      return 'Player vs Player';
  }
}

Future<int?> _showFirstMoveModal(
  BuildContext context, {
  String? difficulty,
  String mode = 'PvC',
  String player1Name = 'Player 1',
  String opponentName = 'Computer',
}) async {
  SoundService().playClick();

  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      if (mode == 'PvP' || mode == 'LAN') {
        return _CoinTossDialog(
          difficulty: difficulty,
          mode: mode,
          player1Name: player1Name,
          opponentName: opponentName,
        );
      }

      return _FirstMoveChoiceDialog(
        difficulty: difficulty,
        mode: mode,
        player1Name: player1Name,
        opponentName: opponentName,
      );
    },
  );
}

class _FirstMoveChoiceDialog extends StatelessWidget {
  final String? difficulty;
  final String mode;
  final String player1Name;
  final String opponentName;

  const _FirstMoveChoiceDialog({
    required this.difficulty,
    required this.mode,
    required this.player1Name,
    required this.opponentName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
          maxWidth: 460,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D5BFF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  size: 36,
                  color: Color(0xFF1D5BFF),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Who Moves First?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D2045),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _modeSubtitle(mode, difficulty),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B778C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              _DifficultyButton(
                icon: Icons.person_rounded,
                title: '$player1Name First',
                subtitle: '$player1Name will make the opening move',
                color: const Color(0xFF1D5BFF),
                onTap: () {
                  SoundService().playClick();
                  Navigator.of(context).pop(1);
                },
              ),
              const SizedBox(height: 12),
              _DifficultyButton(
                icon: mode == 'PvD'
                    ? Icons.memory_rounded
                    : Icons.smart_toy_rounded,
                title: '$opponentName First',
                subtitle: '$opponentName will make the opening move',
                color: const Color(0xFFE94B4B),
                onTap: () {
                  SoundService().playClick();
                  Navigator.of(context).pop(2);
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  SoundService().playClick();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B778C),
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

class _CoinTossDialog extends StatefulWidget {
  final String? difficulty;
  final String mode;
  final String player1Name;
  final String opponentName;

  const _CoinTossDialog({
    required this.difficulty,
    required this.mode,
    required this.player1Name,
    required this.opponentName,
  });

  @override
  State<_CoinTossDialog> createState() => _CoinTossDialogState();
}

class _CoinTossDialogState extends State<_CoinTossDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final int _startingPlayer;
  late final bool _showRizalFace;
  bool _isTossing = false;
  bool _hasTossed = false;

  @override
  void initState() {
    super.initState();
    _startingPlayer = Random().nextBool() ? 1 : 2;
    _showRizalFace = _startingPlayer == 1;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _starterName =>
      _startingPlayer == 1 ? widget.player1Name : widget.opponentName;

  String get _resultFaceLabel =>
      _showRizalFace ? 'Jose Rizal side' : '1 Piso side';

  Future<void> _tossCoin() async {
    if (_isTossing || _hasTossed) {
      return;
    }

    SoundService().playClick();
    setState(() {
      _isTossing = true;
    });

    await _controller.forward(from: 0);
    if (!mounted) {
      return;
    }

    setState(() {
      _isTossing = false;
      _hasTossed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
          maxWidth: 500,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F9FF), Color(0xFFE5EEFF), Color(0xFFF7F4EC)],
          ),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F2E5AAC),
              blurRadius: 28,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact =
                  constraints.maxWidth < 360 || constraints.maxHeight < 650;
              final coinSize = constraints.maxWidth >= 700
                  ? 196.0
                  : isCompact
                  ? 148.0
                  : 172.0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isCompact ? 56 : 64,
                    height: isCompact ? 56 : 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1D5BFF).withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.casino_rounded,
                      size: isCompact ? 30 : 34,
                      color: const Color(0xFF1D5BFF),
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 14),
                  Text(
                    'Coin Toss',
                    style: TextStyle(
                      fontSize: isCompact ? 22 : 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0D2045),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _modeSubtitle(widget.mode, widget.difficulty),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 15,
                      color: const Color(0xFF6B778C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 14),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isCompact ? 10 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.86),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD9E7FF)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Coin Assignments',
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D2045),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _CoinAssignmentRow(
                          icon: Icons.person_rounded,
                          label: 'Jose Rizal side',
                          playerName: widget.player1Name,
                          color: const Color(0xFF1D5BFF),
                        ),
                        const SizedBox(height: 8),
                        _CoinAssignmentRow(
                          icon: Icons.account_balance_wallet_rounded,
                          label: '1 Piso side',
                          playerName: widget.opponentName,
                          color: const Color(0xFFE0A11B),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isCompact ? 12 : 16),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return _OnePesoCoin(
                        progress: _controller.value,
                        showRizalFace: _showRizalFace,
                        isTossing: _isTossing,
                        size: coinSize,
                      );
                    },
                  ),
                  SizedBox(height: isCompact ? 12 : 14),
                  AnimatedOpacity(
                    opacity: _hasTossed ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: _hasTossed
                        ? Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isCompact ? 12 : 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDF6FF),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFD4E6FF),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$_resultFaceLabel wins',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isCompact ? 16 : 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0D2045),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$_starterName moves first',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isCompact ? 14 : 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF35537A),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(height: isCompact ? 12 : 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTossing
                          ? null
                          : _hasTossed
                          ? () {
                              SoundService().playClick();
                              Navigator.of(context).pop(_startingPlayer);
                            }
                          : _tossCoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D5BFF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF92B4F7),
                        padding: EdgeInsets.symmetric(
                          vertical: isCompact ? 14 : 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasTossed
                                ? Icons.play_arrow_rounded
                                : Icons.casino_rounded,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _hasTossed
                                  ? 'Start Game'
                                  : _isTossing
                                  ? 'Tossing...'
                                  : 'Toss the Coin',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isCompact ? 16 : 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isTossing
                        ? null
                        : () {
                            SoundService().playClick();
                            Navigator.of(context).pop();
                          },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B778C),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CoinAssignmentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String playerName;
  final Color color;

  const _CoinAssignmentRow({
    required this.icon,
    required this.label,
    required this.playerName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 280;

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D2045),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Text(
                  playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D2045),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                playerName,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OnePesoCoin extends StatelessWidget {
  final double progress;
  final bool showRizalFace;
  final bool isTossing;
  final double size;

  const _OnePesoCoin({
    required this.progress,
    required this.showRizalFace,
    required this.isTossing,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final tossArc = isTossing ? sin(progress * pi) : 0.0;
    final lift =
        -tossArc * (size * 0.39) - sin(progress * pi * 2.6) * (size * 0.05);
    final drift = isTossing ? sin(progress * pi * 2) * (size * 0.04) : 0.0;
    final spin = isTossing ? progress * pi * 6 : 0.0;
    final tilt = isTossing ? 1 - tossArc * 0.14 : 1.0;
    final shadowWidth = size * (isTossing ? 0.46 - tossArc * 0.19 : 0.46);
    final showAirborneFace = isTossing && progress < 0.86;
    final coinHeight = size * 0.94;

    return SizedBox(
      width: size,
      height: coinHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: size * 0.08,
            child: Container(
              width: shadowWidth,
              height: size * 0.09,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(drift, lift),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(spin)
                ..scale(1.0, tilt),
              child: _OnePesoCoinFace(
                showRizalFace: showRizalFace,
                showAirborneFace: showAirborneFace,
                size: size,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnePesoCoinFace extends StatelessWidget {
  final bool showRizalFace;
  final bool showAirborneFace;
  final double size;

  const _OnePesoCoinFace({
    required this.showRizalFace,
    this.showAirborneFace = false,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.85,
      height: size * 0.85,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDFDFD), Color(0xFFC9CDD2), Color(0xFF8E959F)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.04),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE9EBEF), width: 2.5),
            gradient: const RadialGradient(
              center: Alignment(-0.18, -0.20),
              radius: 0.92,
              colors: [Color(0xFFF8F9FB), Color(0xFFD6D9DE), Color(0xFFB0B6BE)],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.08),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF9FA6AF).withOpacity(0.7),
                  width: 1.4,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(size * 0.08),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: showAirborneFace
                      ? const _AirborneCoinArt()
                      : showRizalFace
                      ? const _RizalCoinArt()
                      : const _PesoValueCoinArt(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RizalCoinArt extends StatelessWidget {
  const _RizalCoinArt();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'REPUBLIKA NG',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Color(0xFF4D5663),
          ),
        ),
        const Text(
          'PILIPINAS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Color(0xFF4D5663),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFAAB1BA).withOpacity(0.35),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFF5D6570),
            size: 34,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'JOSE RIZAL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
            color: Color(0xFF4A5260),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'RIZAL SIDE',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF697281),
          ),
        ),
      ],
    );
  }
}

class _PesoValueCoinArt extends StatelessWidget {
  const _PesoValueCoinArt();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'BANGKO SENTRAL',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: Color(0xFF505864),
          ),
        ),
        const Text(
          'NG PILIPINAS',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: Color(0xFF505864),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '1',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 0.9,
            color: Color(0xFF56606D),
          ),
        ),
        const Text(
          'PISO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            color: Color(0xFF4A5260),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'VALUE SIDE',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF697281),
          ),
        ),
      ],
    );
  }
}

class _AirborneCoinArt extends StatelessWidget {
  const _AirborneCoinArt();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFF767E89),
          size: 18,
        ),
        const SizedBox(height: 6),
        const Text(
          '1',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            height: 0.9,
            color: Color(0xFF56606D),
          ),
        ),
        const Text(
          'PISO',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: Color(0xFF4A5260),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'TOSSING',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFF697281),
          ),
        ),
      ],
    );
  }
}

/// Shows the game start modal with timer options
Future<_GameStartSelection?> _showGameStartModal(
  BuildContext context,
  String mode,
  String? difficulty,
) async {
  SoundService().playClick();
  final player1Controller = TextEditingController();
  final player2Controller = TextEditingController();
  var useGameTimer = true;
  var useMoveTimer = true;

  try {
    return await showDialog<_GameStartSelection>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        _GameStartSelection buildSelection() {
          if (mode != 'PvP') {
            return _GameStartSelection(
              useGameTimer: useGameTimer,
              useMoveTimer: useMoveTimer,
              player2Name: mode == 'PvD'
                  ? DexterEngine.defaultName
                  : 'Player 2',
            );
          }

          return _GameStartSelection(
            useGameTimer: useGameTimer,
            useMoveTimer: useMoveTimer,
            player1Name: _sanitizePlayerName(
              player1Controller.text,
              'Player 1',
            ),
            player2Name: _sanitizePlayerName(
              player2Controller.text,
              'Player 2',
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.82,
                maxWidth: 500,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header icon
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D5BFF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        size: 36,
                        color: Color(0xFF1D5BFF),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Start Game',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D2045),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      _modeSubtitle(mode, difficulty),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B778C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (mode == 'PvP') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD9E7FF)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Player Names',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0D2045),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Use letters only, up to 12 characters each.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B778C),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: player1Controller,
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(12),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z ]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Player 1',
                                hintText: 'Enter a name',
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFF1D5BFF),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD4E6FF),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD4E6FF),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: player2Controller,
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(12),
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z ]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Player 2',
                                hintText: 'Enter a name',
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFFE94B4B),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD4E6FF),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD4E6FF),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _TimerChoiceSection(
                      title: 'Match Timer',
                      subtitle:
                          'Choose 20 minutes for the whole game or play untimed.',
                      timedLabel: '20 Minutes',
                      untimedLabel: 'Untimed',
                      useTimed: useGameTimer,
                      onChanged: (value) => setState(() {
                        useGameTimer = value;
                      }),
                    ),
                    const SizedBox(height: 14),
                    _TimerChoiceSection(
                      title: 'Move Timer',
                      subtitle:
                          'Choose 2 minutes per move or disable the move timer.',
                      timedLabel: '2 Minutes',
                      untimedLabel: 'Untimed',
                      useTimed: useMoveTimer,
                      onChanged: (value) => setState(() {
                        useMoveTimer = value;
                      }),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          SoundService().playClick();
                          FocusScope.of(dialogContext).unfocus();
                          await SystemChannels.textInput.invokeMethod<void>(
                            'TextInput.hide',
                          );
                          if (!dialogContext.mounted) {
                            return;
                          }
                          Navigator.of(dialogContext).pop(buildSelection());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D5BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    TextButton(
                      onPressed: () async {
                        SoundService().playClick();
                        FocusScope.of(dialogContext).unfocus();
                        await SystemChannels.textInput.invokeMethod<void>(
                          'TextInput.hide',
                        );
                        if (!dialogContext.mounted) {
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B778C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  } finally {
    player1Controller.dispose();
    player2Controller.dispose();
  }
}

/// Get difficulty label for display
String _getDifficultyLabel(String? difficulty) {
  switch (difficulty) {
    case 'easy':
      return 'Easy';
    case 'medium':
      return 'Medium';
    case 'hard':
      return 'Hard';
    default:
      return 'PvC';
  }
}

class _TimerChoiceSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timedLabel;
  final String untimedLabel;
  final bool useTimed;
  final ValueChanged<bool> onChanged;

  const _TimerChoiceSection({
    required this.title,
    required this.subtitle,
    required this.timedLabel,
    required this.untimedLabel,
    required this.useTimed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D2045),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B778C),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimerChoiceButton(
                  label: timedLabel,
                  icon: Icons.timer_rounded,
                  selected: useTimed,
                  onTap: () => onChanged(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimerChoiceButton(
                  label: untimedLabel,
                  icon: Icons.timer_off_outlined,
                  selected: !useTimed,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TimerChoiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1D5BFF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF1D5BFF) : const Color(0xFFD4E6FF),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFF1D5BFF),
              size: 20,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : const Color(0xFF0D2045),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainCard extends StatelessWidget {
  final double screenHeight;
  const _MainCard({required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.93),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2E5AAC),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
          BoxShadow(
            color: Color(0x0F2E5AAC),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top illustration strip
            const _TopIllustration(),

            const SizedBox(height: 10),

            // Title
            const _TitleBlock(),

            const SizedBox(height: 18),

            // Buttons
            _MenuButton(
              height: 76,
              style: MenuButtonStyle.primaryBlue,
              leading: const _IconChip(
                bg: Color(0x1AFFFFFF),
                icon: Icons.sports_esports_rounded,
                iconColor: Colors.white,
              ),
              title: 'Player vs Computer',
              onTap: () => _showDifficultyModal(context, 'PvC'),
            ),
            const SizedBox(height: 14),
            _MenuButton(
              height: 76,
              style: MenuButtonStyle.whiteBlue,
              leading: const _IconChip(
                bg: Color(0xFFEAF4FF),
                icon: Icons.memory_rounded,
                iconColor: Color(0xFF1D5BFF),
              ),
              title: 'Player vs Dexter',
              onTap: () => _showDifficultyModal(context, 'PvD'),
            ),
            const SizedBox(height: 14),
            _MenuButton(
              height: 76,
              style: MenuButtonStyle.whiteGreen,
              leading: const _IconChip(
                bg: Color(0xFFE8FFF1),
                icon: Icons.group_rounded,
                iconColor: Color(0xFF17A85E),
              ),
              title: 'Player vs Player',
              onTap: () => _showDifficultyModal(context, 'PvP'),
            ),
            const SizedBox(height: 14),
            _MenuButton(
              height: 76,
              style: MenuButtonStyle.whiteBlue,
              leading: const _IconChip(
                bg: Color(0xFFE9F2FF),
                icon: Icons.help_rounded,
                iconColor: Color(0xFF1D5BFF),
              ),
              title: 'How to Play',
              onTap: () {
                SoundService().playClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
                );
              },
            ),
            const SizedBox(height: 14),
            _MenuButton(
              height: 76,
              style: MenuButtonStyle.whiteGold,
              leading: const _IconChip(
                bg: Color(0xFFFFF5DD),
                icon: Icons.workspace_premium_rounded,
                iconColor: Color(0xFFFFA726),
              ),
              title: 'Credits',
              onTap: () {
                SoundService().playClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreditScreen()),
                );
              },
            ),
            if (_showQuitButton) ...[
              const SizedBox(height: 18),

              // iOS apps should not present a manual quit action.
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  SoundService().playClick();
                  await _closeApp();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout_rounded, color: Color(0xFFE94B4B)),
                      SizedBox(width: 10),
                      Text(
                        'Quit',
                        style: TextStyle(
                          color: Color(0xFFE94B4B),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

/// Background layer using the home-screen-bg.png image.
class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/home-screen-bg.png'),
          fit: BoxFit.cover,
        ),
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
          imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
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

class _DotGrid extends StatelessWidget {
  final double opacity;
  const _DotGrid({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(size: const Size(90, 60), painter: _DotGridPainter()),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF7AA7FF);
    const dot = 2.2;
    const gapX = 12.0;
    const gapY = 12.0;

    for (double y = 0; y <= size.height; y += gapY) {
      for (double x = 0; x <= size.width; x += gapX) {
        canvas.drawCircle(Offset(x, y), dot, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopIllustration extends StatelessWidget {
  const _TopIllustration();

  @override
  Widget build(BuildContext context) {
    // Using the logo.png asset for the app icon.
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6FBFF), Color(0xFFEFF6FF), Color(0xFFFDFDFF)],
        ),
      ),
      child: Stack(
        children: [
          // faint curve decor
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: CustomPaint(painter: _WavePainter()),
            ),
          ),

          // Center app icon using logo.png
          const Align(
            alignment: Alignment.center,
            child: Image(
              image: AssetImage('assets/images/logo.png'),
              width: 150,
              height: 150,
            ),
          ),

          // small doodles (left/right)
          Positioned(
            left: 18,
            top: 16,
            child: Opacity(
              opacity: 0.85,
              child: _DoodleCard(
                text: 'f(x)',
                lineColor: const Color(0xFF1D5BFF),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 16,
            child: Opacity(
              opacity: 0.85,
              child: _DoodleCard(
                text: '2x',
                lineColor: const Color(0xFFE45B5B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFB9D3FF).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(-10, size.height * 0.65);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.30,
      size.width * 0.45,
      size.height * 0.95,
      size.width * 1.05,
      size.height * 0.58,
    );

    canvas.drawPath(path, p);

    final p2 = Paint()
      ..color = const Color(0xFFB9D3FF).withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path2 = Path();
    path2.moveTo(-10, size.height * 0.35);
    path2.cubicTo(
      size.width * 0.35,
      size.height * 0.12,
      size.width * 0.65,
      size.height * 0.70,
      size.width * 1.05,
      size.height * 0.28,
    );
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DoodleCard extends StatelessWidget {
  final String text;
  final Color lineColor;

  const _DoodleCard({required this.text, required this.lineColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 54,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4C6DB5),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: 28,
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: lineColor.withOpacity(.25),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.05,
              letterSpacing: -0.6,
            ),
            children: [
              TextSpan(
                text: 'Derivative ',
                style: TextStyle(color: Color(0xFF0D2045)),
              ),
              TextSpan(
                text: 'Damath',
                style: TextStyle(color: Color(0xFF1D5BFF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Learn derivatives while you play!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF6B778C),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        // little underline accent (like the screenshot)
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 92,
            height: 5,
            margin: const EdgeInsets.only(right: 64),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC24A),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ],
    );
  }
}

enum MenuButtonStyle { primaryBlue, whiteBlue, whiteGreen, whiteGold }

class _MenuButton extends StatelessWidget {
  final double height;
  final MenuButtonStyle style;
  final Widget leading;
  final String title;
  final VoidCallback onTap;

  const _MenuButton({
    required this.height,
    required this.style,
    required this.leading,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = style == MenuButtonStyle.primaryBlue;

    final bg = switch (style) {
      MenuButtonStyle.primaryBlue => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E7BFF), Color(0xFF0D49E9)],
      ),
      MenuButtonStyle.whiteBlue => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF3F8FF)],
      ),
      MenuButtonStyle.whiteGreen => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF1FFF7)],
      ),
      MenuButtonStyle.whiteGold => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFFFFBF1)],
      ),
    };

    final borderColor = switch (style) {
      MenuButtonStyle.primaryBlue => Colors.transparent,
      MenuButtonStyle.whiteBlue => const Color(0xFFD4E6FF),
      MenuButtonStyle.whiteGreen => const Color(0xFFC6F0D7),
      MenuButtonStyle.whiteGold => const Color(0xFFFFE4A8),
    };

    final textColor = isPrimary ? Colors.white : const Color(0xFF0D2045);

    final arrowBg = switch (style) {
      MenuButtonStyle.primaryBlue => const Color(0x1AFFFFFF),
      MenuButtonStyle.whiteBlue => const Color(0xFFEEF5FF),
      MenuButtonStyle.whiteGreen => const Color(0xFFE9FFF2),
      MenuButtonStyle.whiteGold => const Color(0xFFFFF5DD),
    };

    final arrowColor = switch (style) {
      MenuButtonStyle.primaryBlue => Colors.white,
      MenuButtonStyle.whiteBlue => const Color(0xFF1D5BFF),
      MenuButtonStyle.whiteGreen => const Color(0xFF17A85E),
      MenuButtonStyle.whiteGold => const Color(0xFFFFA726),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: bg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color:
                  (style == MenuButtonStyle.primaryBlue
                          ? const Color(0x332E7BFF)
                          : const Color(0x242E5AAC))
                      .withOpacity(0.20),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
            const BoxShadow(
              color: Color(0x0F2E5AAC),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: arrowBg, shape: BoxShape.circle),
              child: Icon(
                Icons.chevron_right_rounded,
                color: arrowColor,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final Color bg;
  final IconData icon;
  final Color iconColor;

  const _IconChip({
    required this.bg,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: iconColor, size: 26),
    );
  }
}

class _FeatureTabItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final bool active;

  const _FeatureTabItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.75),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x122E5AAC),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D2045).withOpacity(active ? 1.0 : 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
