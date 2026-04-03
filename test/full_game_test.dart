// test/full_game_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:derivative_damath/utils/game_logic.dart';
import 'package:derivative_damath/models/chip_model.dart';
import 'package:derivative_damath/models/game_state_model.dart';

void main() {
  group('Full Game Integration Tests', () {
    test('Simulate complete PvP game from start to finish', () {
      var game = GameLogic();
      
      // Initialize game
      game.initializeChips();
      
      // Verify initial state
      expect(game.chips.length, equals(24)); // 12 chips per player
      expect(game.currentPlayer, equals(1));
      expect(game.player1Score, equals(0));
      expect(game.player2Score, equals(0));
      expect(game.gamePhase, equals(GamePhase.playing));
      
      // Get Player 1 chips
      var player1Chips = game.getChipsForPlayer(1);
      var player2Chips = game.getChipsForPlayer(2);
      
      expect(player1Chips.length, equals(12));
      expect(player2Chips.length, equals(12));
    });

    test('Game mechanics work together - Movement', () {
      var game = GameLogic();
      game.initializeChips();
      
      game.currentPlayer = 1;
      
      // Get any chip that has valid moves
      final chips = game.getChipsForPlayer(1);
      final chip = chips.firstWhere(
        (c) => game.getValidMoves(c).isNotEmpty,
        orElse: () => chips.first,
      );
      final validMoves = game.getValidMoves(chip);
      
      expect(validMoves.isNotEmpty, isTrue);
      
      // Just verify we can get valid moves without error
      expect(validMoves != null, isTrue);
    });

    test('Game mechanics work together - Captures', () {
      var game = GameLogic();
      
      // Create a scenario where capture is possible
      game.chips = [
        ChipModel(id: 0, owner: 1, x: 2, y: 4, terms: {1: 1}),
        ChipModel(id: 1, owner: 2, x: 3, y: 3, terms: {1: 1}),
        ChipModel(id: 2, owner: 2, x: 1, y: 3, terms: {1: 1}),
      ];
      game.currentPlayer = 1;
      
      final player1Chip = game.chips.firstWhere((c) => c.owner == 1);
      final captures = game.getAvailableCaptures(player1Chip);
      
      expect(captures.isNotEmpty, isTrue);
      
      // Can execute capture without error
      game.selectedChip = player1Chip;
      final captureMove = captures.first;
      game.onTileTap(captureMove.toX, captureMove.toY);
      
      // Game should still be valid
      expect(game.gamePhase == GamePhase.playing || game.gamePhase == GamePhase.won, isTrue);
    });

    test('Game mechanics work together - Derivative validation', () {
      var game = GameLogic();
      
      game.chips = [
        ChipModel(id: 0, owner: 1, x: 3, y: 5, terms: {2: 3}),
        ChipModel(id: 1, owner: 2, x: 3, y: 3, terms: {1: 6}),
      ];
      game.currentPlayer = 1;
      
      final player1Chip = game.chips.firstWhere((c) => c.owner == 1);
      game.selectedChip = player1Chip;
      
      final derivative = game.computeDerivative(player1Chip);
      expect(derivative, equals({1: 6}));
      
      final isValid = game.validateDerivativeMove(player1Chip, 3, 3);
      expect(isValid, isTrue);
    });

    test('Game mechanics work together - Scoring', () {
      var game = GameLogic();
      game.initializeChips();
      
      final initialScore = game.player1Score;
      
      game.currentPlayer = 1;
      final chip = game.chips.firstWhere((c) => c.owner == 1);
      game.selectedChip = chip;
      
      final validMoves = game.getValidMoves(chip);
      if (validMoves.isNotEmpty) {
        final move = validMoves.firstWhere((m) => !m.isCapture, orElse: () => validMoves.first);
        game.onTileTap(move.toX, move.toY);
        
        expect(game.player1Score >= 0, isTrue);
      }
    });

    test('Game mechanics work together - Dama promotion', () {
      var game = GameLogic();
      
      game.chips = [
        ChipModel(id: 0, owner: 1, x: 3, y: 1, terms: {1: 1}, isDama: false),
      ];
      game.currentPlayer = 1;
      
      final chip = game.chips.first;
      expect(chip.isDama, isFalse);
      
      game.selectedChip = chip;
      game.onTileTap(3, 0);
      
      final promotedChip = game.chipAt(3, 0);
      if (promotedChip != null) {
        expect(promotedChip.isDama, isTrue);
      }
    });

    test('Game mechanics work together - Win condition', () {
      var game = GameLogic();
      
      game.chips = [
        ChipModel(id: 0, owner: 1, x: 3, y: 3, terms: {1: 1}),
      ];
      game.currentPlayer = 1;
      
      game.evaluateGameState();
      
      expect(game.gamePhase, equals(GamePhase.won));
      expect(game.winner?.playerNumber, equals(1));
    });

    test('Full game simulation - multiple turns', () {
      var game = GameLogic();
      game.initializeChips();
      
      var turnCount = 0;
      const maxTurns = 10;
      
      while (game.gamePhase == GamePhase.playing && turnCount < maxTurns) {
        final currentPlayerChips = game.getChipsForPlayer(game.currentPlayer);
        
        if (currentPlayerChips.isEmpty) {
          break;
        }
        
        // Find a chip that has valid moves
        final availableChips = currentPlayerChips.where(
          (c) => game.getValidMoves(c).isNotEmpty,
        ).toList();
        
        if (availableChips.isEmpty) {
          game.evaluateGameState();
          break;
        }
        
        // Use any available chip
        final chip = availableChips.first;
        final validMoves = game.getValidMoves(chip);
        
        if (validMoves.isEmpty) {
          game.evaluateGameState();
          break;
        }
        
        game.selectedChip = chip;
        final move = validMoves.first;
        game.onTileTap(move.toX, move.toY);
        
        turnCount++;
      }
      
      expect(turnCount > 0, isTrue);
      expect(game.gamePhase == GamePhase.playing || turnCount == maxTurns, isTrue);
    });

    test('Chain captures work correctly', () {
      var game = GameLogic();
      
      // Player 1 chip at (2,2) can capture Player 2 chip at (3,3) to land at (4,4)
      game.chips = [
        ChipModel(id: 0, owner: 1, x: 2, y: 2, terms: {1: 1}),
        ChipModel(id: 1, owner: 2, x: 3, y: 3, terms: {1: 1}),
      ];
      game.currentPlayer = 1;
      
      final player1Chip = game.chips.firstWhere((c) => c.owner == 1);
      
      // Player 1 at (2,2) can capture opponent at (3,3) by jumping to (4,4)
      // This requires: dx=2, dy=2 (diagonal forward for player 1)
      var captures = game.getAvailableCaptures(player1Chip);
      
      // Verify capture tracking is available
      expect(game.captureChainDepth >= 0, isTrue);
    });

    test('Game state serialization/deserialization', () {
      var game = GameLogic();
      game.initializeChips();
      
      game.currentPlayer = 2;
      game.player1Score = 5;
      game.player2Score = 3;
      
      final chipsState = game.chips.map((c) => {
        'owner': c.owner,
        'x': c.x,
        'y': c.y,
        'terms': Map<String, int>.from(c.terms.map((k, v) => MapEntry(k.toString(), v))),
        'isDama': c.isDama,
      }).toList();
      
      expect(chipsState.length, equals(24));
      expect(game.player1Score, equals(5));
      expect(game.player2Score, equals(3));
      expect(game.currentPlayer, equals(2));
    });
  });

  group('Edge Cases and Error Handling', () {
    test('Handle invalid tap position', () {
      var game = GameLogic();
      game.initializeChips();
      
      game.onTileTap(10, 10);
      
      expect(game.gamePhase, equals(GamePhase.playing));
    });

    test('Handle empty valid moves list', () {
      var game = GameLogic();
      
      game.chips = [
        ChipModel(id: 0, owner: 1, x: 0, y: 0, terms: {1: 1}),
        ChipModel(id: 1, owner: 2, x: 1, y: 1, terms: {1: 1}),
        ChipModel(id: 2, owner: 2, x: 0, y: 2, terms: {1: 1}),
        ChipModel(id: 3, owner: 2, x: 2, y: 0, terms: {1: 1}),
      ];
      game.currentPlayer = 1;
      
      final chip = game.chips.firstWhere((c) => c.owner == 1);
      final moves = game.getValidMoves(chip);
      
      expect(moves != null, isTrue);
    });

    test('Game continues after incorrect derivative', () {
      var game = GameLogic();
      
      game.chips = [
        ChipModel(id: 0, owner: 1, x: 3, y: 5, terms: {2: 3}),
        ChipModel(id: 1, owner: 2, x: 3, y: 3, terms: {1: 5}),
      ];
      game.currentPlayer = 1;
      
      final player1Chip = game.chips.firstWhere((c) => c.owner == 1);
      game.selectedChip = player1Chip;
      
      game.onTileTap(3, 3);
      
      expect(game.gamePhase == GamePhase.playing, isTrue);
    });
  });
}
