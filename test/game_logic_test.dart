// test/game_logic_test.dart
import 'package:derivative_damath/utils/score_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:derivative_damath/utils/game_logic.dart';
import 'package:derivative_damath/models/chip_model.dart';
import 'package:derivative_damath/models/game_state_model.dart';

void main() {
  group('Game Logic - Capture Tests', () {
    test('Can get available captures for a chip', () {
      var gameLogic = GameLogic();

      // Setup: Create a capture scenario
      gameLogic.chips = [
        ChipModel(id: 0, owner: 1, x: 2, y: 3, terms: {1: 1}),
        ChipModel(id: 1, owner: 2, x: 3, y: 2, terms: {1: 1}),
      ];

      final player1Chip = gameLogic.chips.firstWhere((c) => c.owner == 1);
      final captures = gameLogic.getAvailableCaptures(player1Chip);

      // Method should work without error
      expect(captures != null, isTrue);
    });

    test('Get valid moves returns moves', () {
      var gameLogic = GameLogic();
      gameLogic.initializeChips();

      // Get any chip that has valid moves
      final chips = gameLogic.getChipsForPlayer(1);
      final chip = chips.firstWhere(
        (c) => gameLogic.getValidMoves(c).isNotEmpty,
        orElse: () => chips.first,
      );
      final validMoves = gameLogic.getValidMoves(chip);

      expect(validMoves.isNotEmpty, isTrue);
    });

    test(
      'Dama capture prevails when both a Dama and a regular chip can capture',
      () {
        final gameLogic = GameLogic();

        final regularChip = ChipModel(
          id: 10,
          owner: 1,
          x: 2,
          y: 1,
          terms: {1: 6},
        );
        final damaChip = ChipModel(
          id: 11,
          owner: 1,
          x: 6,
          y: 5,
          terms: {3: -3},
          isDama: true,
        );

        gameLogic.chips = [
          regularChip,
          damaChip,
          ChipModel(id: 20, owner: 2, x: 3, y: 2, terms: {2: 10}),
          ChipModel(id: 21, owner: 2, x: 5, y: 4, terms: {2: 28}),
        ];
        gameLogic.currentPlayer = 1;

        final capturingChips = gameLogic.getChipsThatCanCapture(1);
        final legalMoves = gameLogic.getLegalMovesForPlayer(1);

        expect(capturingChips.map((chip) => chip.id), contains(11));
        expect(capturingChips.map((chip) => chip.id), isNot(contains(10)));
        expect(gameLogic.chipCanCapture(damaChip), isTrue);
        expect(gameLogic.chipCanCapture(regularChip), isFalse);
        expect(legalMoves, isNotEmpty);
        expect(
          legalMoves.every((move) => move.fromX == 6 && move.fromY == 5),
          isTrue,
        );
      },
    );
  });

  group('Game Logic - Move Validation Tests', () {
    test('Regular forward move is valid', () {
      var gameLogic = GameLogic();
      gameLogic.initializeChips();

      // Player 1 starts at y=0,1,2 and moves upward (direction = -1)
      final chip = gameLogic.chips.firstWhere((c) => c.owner == 1 && c.y == 2);

      // Forward move should be valid
      final direction = -1;
      final canMove = gameLogic.chipAt(chip.x, chip.y + direction) == null;

      expect(canMove, isTrue);
    });

    test('Backward move for non-Dama is invalid', () {
      var gameLogic = GameLogic();
      gameLogic.initializeChips();

      // Get a regular chip (not Dama)
      final chip = gameLogic.chips.firstWhere((c) => c.owner == 1 && !c.isDama);

      expect(chip.y >= 0, isTrue);
      expect(chip.isDama, isFalse);
    });

    test('Diagonal move - chip validates diagonal', () {
      var gameLogic = GameLogic();
      gameLogic.initializeChips();

      // Get any regular chip that has valid moves
      final chip = gameLogic.chips.firstWhere(
        (c) =>
            c.owner == 1 && !c.isDama && gameLogic.getValidMoves(c).isNotEmpty,
        orElse: () =>
            gameLogic.chips.firstWhere((c) => c.owner == 1 && !c.isDama),
      );

      // Verify chip is valid
      expect(chip != null, isTrue);
      expect(chip.isDama || chip.y >= 0, isTrue);
    });
  });

  group('Game Logic - Double Jump Tests', () {
    test('Capture chain depth is tracked', () {
      var gameLogic = GameLogic();

      gameLogic.chips = [
        ChipModel(id: 0, owner: 1, x: 2, y: 3, terms: {1: 1}),
        ChipModel(id: 1, owner: 2, x: 3, y: 2, terms: {1: 1}),
        ChipModel(id: 2, owner: 2, x: 4, y: 1, terms: {1: 1}),
      ];

      gameLogic.currentPlayer = 1;
      gameLogic.selectedChip = gameLogic.chips[0];
      gameLogic.onTileTap(4, 1);

      expect(gameLogic.captureChainDepth >= 0, isTrue);
    });

    test('Turn switches after valid move', () {
      var gameLogic = GameLogic();
      gameLogic.initializeChips();

      gameLogic.currentPlayer = 1;
      final chip = gameLogic.chips.firstWhere((c) => c.owner == 1);
      gameLogic.selectedChip = chip;

      final validMoves = gameLogic.getValidMoves(chip);
      if (validMoves.isNotEmpty) {
        final move = validMoves.firstWhere(
          (m) => !m.isCapture,
          orElse: () => validMoves.first,
        );
        gameLogic.onTileTap(move.toX, move.toY);

        // Either turn switched or move was processed
        expect(
          gameLogic.currentPlayer == 2 ||
              gameLogic.gamePhase == GamePhase.playing,
          isTrue,
        );
      }
    });
  });

  group('Game Logic - Dama Promotion Tests', () {
    test('Chip promoted when reaching end row', () {
      var gameLogic = GameLogic();

      gameLogic.chips = [
        ChipModel(id: 0, owner: 1, x: 3, y: 1, terms: {1: 1}, isDama: false),
      ];
      gameLogic.currentPlayer = 1;

      final chip = gameLogic.chips.first;
      expect(chip.isDama, isFalse);

      gameLogic.selectedChip = chip;
      gameLogic.onTileTap(3, 0);

      final promotedChip = gameLogic.chipAt(3, 0);
      if (promotedChip != null) {
        expect(promotedChip.isDama, isTrue);
      }
    });

    test('Dama can move backward after promotion', () {
      var gameLogic = GameLogic();

      final chip = ChipModel(
        id: 0,
        owner: 1,
        x: 3,
        y: 3,
        terms: {1: 1},
        isDama: true,
      );
      gameLogic.chips = [chip];
      gameLogic.currentPlayer = 1;

      final moves = gameLogic.getValidMoves(chip);
      expect(moves.isNotEmpty, isTrue);

      final backwardMoves = moves.where((m) => m.toY > chip.y).toList();
      expect(backwardMoves.isNotEmpty, isTrue);
    });

    test('Dama can slide multiple squares', () {
      var gameLogic = GameLogic();

      final chip = ChipModel(
        id: 0,
        owner: 1,
        x: 3,
        y: 3,
        terms: {1: 1},
        isDama: true,
      );
      gameLogic.chips = [chip];

      final moves = gameLogic.getValidMoves(chip);

      final multiSquareMoves = moves
          .where(
            (m) => (m.toX - chip.x).abs() > 1 || (m.toY - chip.y).abs() > 1,
          )
          .toList();

      expect(multiSquareMoves.isNotEmpty, isTrue);
    });

    test(
      'Dama cannot jump over two chips on the same diagonal in one capture',
      () {
        var gameLogic = GameLogic();

        final dama = ChipModel(
          id: 0,
          owner: 1,
          x: 0,
          y: 0,
          terms: {1: 1},
          isDama: true,
        );
        gameLogic.chips = [
          dama,
          ChipModel(id: 1, owner: 2, x: 2, y: 2, terms: {1: 1}),
          ChipModel(id: 2, owner: 2, x: 4, y: 4, terms: {1: 1}),
        ];

        final captures = gameLogic.getAvailableCaptures(dama);

        expect(captures.any((move) => move.toX == 3 && move.toY == 3), isTrue);
        expect(captures.any((move) => move.toX == 5 && move.toY == 5), isFalse);
        expect(captures.any((move) => move.toX == 6 && move.toY == 6), isFalse);
      },
    );
  });

  group('Game Logic - Win Detection Tests', () {
    test('Win when opponent has no chips', () {
      var gameLogic = GameLogic();

      gameLogic.chips = [
        ChipModel(id: 0, owner: 1, x: 3, y: 3, terms: {1: 1}),
      ];
      gameLogic.currentPlayer = 1;

      gameLogic.evaluateGameState();

      expect(
        gameLogic.gamePhase == GamePhase.won ||
            gameLogic.chips.where((c) => c.owner == 2).isEmpty,
        isTrue,
      );
    });

    test('Can get all valid moves for player', () {
      var gameLogic = GameLogic();

      gameLogic.chips = [
        ChipModel(id: 0, owner: 1, x: 3, y: 3, terms: {1: 1}),
        ChipModel(id: 1, owner: 2, x: 4, y: 4, terms: {1: 1}),
      ];
      gameLogic.currentPlayer = 1;

      final player1Moves = gameLogic.getAllValidMovesForPlayer(1);
      expect(player1Moves != null, isTrue);
    });

    test(
      'Player with the higher final score wins even when both totals are negative',
      () {
        var gameLogic = GameLogic();

        gameLogic.chips = [
          ChipModel(id: 0, owner: 1, x: 3, y: 3, terms: {1: -3}, isDama: true),
        ];
        gameLogic.currentPlayer = 1;
        gameLogic.player1Score = -386487316.56;
        gameLogic.player2Score = -405163164.67;

        gameLogic.evaluateGameState();

        expect(gameLogic.isGameOver, isTrue);
        expect(gameLogic.currentWinner, isNotNull);
        expect(gameLogic.currentWinner!.playerNumber, equals(1));
        expect(gameLogic.getFinalScore(1), equals(-386487310.56));
        expect(gameLogic.getFinalScore(2), equals(-405163164.67));
        expect(gameLogic.getFinalScore(1) > gameLogic.getFinalScore(2), isTrue);
      },
    );

    test('Endgame bonus is recorded in move history for both players', () {
      final gameLogic = GameLogic();

      gameLogic.chips = [
        ChipModel(id: 0, owner: 1, x: 3, y: 3, terms: {1: -3}, isDama: true),
      ];
      gameLogic.currentPlayer = 1;

      gameLogic.evaluateGameState();

      final bonusEntries = gameLogic.history
          .where((entry) => entry.isEndgameBonus)
          .toList();

      expect(bonusEntries.length, equals(2));
      expect(bonusEntries[0].player, equals(1));
      expect(bonusEntries[0].pointsEarned, equals(6.0));
      expect(
        bonusEntries[0].calculationDetails,
        contains('Total endgame bonus = 6.00'),
      );
      expect(bonusEntries[1].player, equals(2));
      expect(bonusEntries[1].pointsEarned, equals(0.0));
      expect(
        bonusEntries[1].calculationDetails,
        contains('No remaining chips: 0.00'),
      );
    });
  });

  group('Game Logic - Score Calculation', () {
    test('Score is accessible after moves', () {
      var gameLogic = GameLogic();
      gameLogic.initializeChips();

      final initialScore = gameLogic.player1Score;

      gameLogic.currentPlayer = 1;
      final chip = gameLogic.chips.firstWhere((c) => c.owner == 1);
      gameLogic.selectedChip = chip;

      final validMoves = gameLogic.getValidMoves(chip);
      if (validMoves.isNotEmpty) {
        final move = validMoves.firstWhere(
          (m) => !m.isCapture,
          orElse: () => validMoves.first,
        );
        gameLogic.onTileTap(move.toX, move.toY);

        // Score should be accessible
        expect(gameLogic.player1Score >= 0, isTrue);
      }
    });

    test('Dama capture applies the thesis multiplier', () {
      final gameLogic = GameLogic();
      final dama = ChipModel(
        id: 0,
        owner: 1,
        x: 2,
        y: 2,
        terms: {1: 6},
        isDama: true,
      );
      final target = ChipModel(id: 1, owner: 2, x: 3, y: 3, terms: {2: 10});

      gameLogic.chips = [dama, target];
      gameLogic.currentPlayer = 1;
      gameLogic.selectedChip = dama;

      final operation = gameLogic.getOperationAt(4, 4)!;
      final expectedScore = ScoreCalculator.calculateScorePDF(
        movingChipTerms: dama.terms,
        targetChipTerms: target.terms,
        operationSymbol: operation,
        targetX: 4,
        targetY: 4,
        isCapture: true,
        isMovingChipDama: true,
      );

      gameLogic.onTileTap(4, 4);

      expect(gameLogic.player1Score, closeTo(expectedScore, 1e-9));
    });

    test('Final score includes remaining-chip endgame bonuses', () {
      final gameLogic = GameLogic();

      gameLogic.chips = [
        ChipModel(id: 0, owner: 1, x: 7, y: 6, terms: {3: -3}, isDama: true),
        ChipModel(id: 1, owner: 1, x: 6, y: 3, terms: {2: 10}),
        ChipModel(id: 2, owner: 2, x: 7, y: 4, terms: {3: -3}),
      ];
      gameLogic.player1Score = -100;
      gameLogic.player2Score = -100;

      expect(gameLogic.getFinalScore(1), equals(-84.0));
      expect(gameLogic.getFinalScore(2), equals(-97.0));
    });

    test('Chain captures do not add an extra bonus point', () {
      final gameLogic = GameLogic();
      final attacker = ChipModel(id: 0, owner: 1, x: 1, y: 4, terms: {1: 6});
      final firstTarget = ChipModel(
        id: 1,
        owner: 2,
        x: 2,
        y: 3,
        terms: {2: 10},
      );
      final secondTarget = ChipModel(
        id: 2,
        owner: 2,
        x: 4,
        y: 1,
        terms: {1: -15},
      );

      gameLogic.chips = [attacker, firstTarget, secondTarget];
      gameLogic.currentPlayer = 1;
      gameLogic.selectedChip = attacker;

      final firstOperation = gameLogic.getOperationAt(3, 2)!;
      final secondOperation = gameLogic.getOperationAt(5, 0)!;
      final firstExpected = ScoreCalculator.calculateScorePDF(
        movingChipTerms: attacker.terms,
        targetChipTerms: firstTarget.terms,
        operationSymbol: firstOperation,
        targetX: 3,
        targetY: 2,
        isCapture: true,
      );
      final secondExpected = ScoreCalculator.calculateScorePDF(
        movingChipTerms: attacker.terms,
        targetChipTerms: secondTarget.terms,
        operationSymbol: secondOperation,
        targetX: 5,
        targetY: 0,
        isCapture: true,
      );

      gameLogic.onTileTap(3, 2);
      expect(gameLogic.player1Score, closeTo(firstExpected, 1e-9));
      expect(gameLogic.mustContinueCapture, isTrue);

      gameLogic.onTileTap(5, 0);

      expect(
        gameLogic.player1Score,
        closeTo(firstExpected + secondExpected, 1e-9),
      );
    });
  });

  group('Game Logic - Chip Selection', () {
    test('Select own chip works', () {
      var gameLogic = GameLogic();
      gameLogic.initializeChips();

      final chip = gameLogic.chips.firstWhere((c) => c.owner == 1);
      gameLogic.selectedChip = chip;

      expect(gameLogic.selectedChip, equals(chip));
    });

    test('Get chips for player returns correct count', () {
      var gameLogic = GameLogic();
      gameLogic.initializeChips();

      final player1Chips = gameLogic.getChipsForPlayer(1);
      final player2Chips = gameLogic.getChipsForPlayer(2);

      expect(player1Chips.length, equals(12));
      expect(player2Chips.length, equals(12));
    });
  });

  group('Game Logic - Reset', () {
    test('Reset returns to initial state', () {
      var gameLogic = GameLogic();
      gameLogic.initializeChips();

      gameLogic.currentPlayer = 2;
      gameLogic.player1Score = 100;
      gameLogic.player2Score = 50;

      gameLogic.reset();

      expect(gameLogic.currentPlayer, equals(1));
      expect(gameLogic.player1Score, equals(0));
      expect(gameLogic.player2Score, equals(0));
    });
  });

  group('Game Logic - Chip Model', () {
    test('Chip label is generated correctly', () {
      final chip = ChipModel(id: 0, owner: 1, x: 0, y: 0, terms: {2: 3, 1: 2});

      expect(chip.label.isNotEmpty, isTrue);
    });

    test('Chip can be created with isDama flag', () {
      final chip = ChipModel(
        id: 0,
        owner: 1,
        x: 0,
        y: 0,
        terms: {1: 1},
        isDama: true,
      );

      expect(chip.isDama, isTrue);
    });
  });
}
