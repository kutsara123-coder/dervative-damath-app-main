import 'package:derivative_damath/utils/dexter_engine.dart';
import 'package:derivative_damath/utils/game_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DexterEngine', () {
    test('mirrors the player opening move during strategy stealing', () {
      final game = GameLogic();

      game.executeMove(Move(fromX: 1, fromY: 2, toX: 0, toY: 3));

      final dexter = DexterEngine(gameLogic: game);
      final move = dexter.getBestMove();

      expect(move, isNotNull);
      expect(move!.fromX, 6);
      expect(move.fromY, 5);
      expect(move.toX, 7);
      expect(move.toY, 4);
    });

    test('continues mirrored opening play on the next non-capture turn', () {
      final game = GameLogic();

      game.executeMove(Move(fromX: 1, fromY: 2, toX: 0, toY: 3));
      final firstDexterMove = DexterEngine(gameLogic: game).getBestMove();
      expect(firstDexterMove, isNotNull);
      game.executeMove(firstDexterMove!);

      game.executeMove(Move(fromX: 3, fromY: 2, toX: 4, toY: 3));

      final secondDexterMove = DexterEngine(gameLogic: game).getBestMove();

      expect(secondDexterMove, isNotNull);
      expect(secondDexterMove!.fromX, 4);
      expect(secondDexterMove.fromY, 5);
      expect(secondDexterMove.toX, 3);
      expect(secondDexterMove.toY, 4);
    });

    test('returns a legal move even with a very small time budget', () {
      final game = GameLogic();
      final dexter = DexterEngine(gameLogic: game);

      final legalMoves = game.getLegalMovesForPlayer(2);
      final move = dexter.getBestMove(
        maxThinkingTime: const Duration(milliseconds: 1),
      );

      expect(move, isNotNull);
      expect(
        legalMoves.any(
          (candidate) =>
              candidate.fromX == move!.fromX &&
              candidate.fromY == move.fromY &&
              candidate.toX == move.toX &&
              candidate.toY == move.toY,
        ),
        isTrue,
      );
    });

    test('uses prepared give-and-take opening response', () {
      final game = GameLogic();

      game.executeMove(Move(fromX: 5, fromY: 2, toX: 4, toY: 3));

      final move = DexterEngine(gameLogic: game).getBestMove();

      expect(move, isNotNull);
      expect(move!.fromX, 2);
      expect(move.fromY, 5);
      expect(move.toX, 3);
      expect(move.toY, 4);
    });

    test('uses prepared greedy counter opening response', () {
      final game = GameLogic();

      game.executeMove(Move(fromX: 5, fromY: 2, toX: 6, toY: 3));

      final move = DexterEngine(gameLogic: game).getBestMove();

      expect(move, isNotNull);
      expect(move!.fromX, 4);
      expect(move.fromY, 5);
      expect(move.toX, 5);
      expect(move.toY, 4);
    });

    test('continues deeper strategy-stealing book line', () {
      final game = GameLogic();

      game.executeMove(Move(fromX: 1, fromY: 2, toX: 0, toY: 3));
      game.executeMove(Move(fromX: 6, fromY: 5, toX: 7, toY: 4));
      game.executeMove(Move(fromX: 3, fromY: 2, toX: 4, toY: 3));
      game.executeMove(Move(fromX: 4, fromY: 5, toX: 3, toY: 4));
      game.executeMove(Move(fromX: 7, fromY: 2, toX: 6, toY: 3));
      game.executeMove(Move(fromX: 0, fromY: 5, toX: 1, toY: 4));
      game.executeMove(Move(fromX: 6, fromY: 1, toX: 7, toY: 2));

      final move = DexterEngine(gameLogic: game).getBestMove();

      expect(move, isNotNull);
      expect(move!.fromX, 1);
      expect(move.fromY, 6);
      expect(move.toX, 0);
      expect(move.toY, 5);
    });

    test('continues even deeper strategy-stealing book line', () {
      final game = GameLogic();

      game.executeMove(Move(fromX: 1, fromY: 2, toX: 0, toY: 3));
      game.executeMove(Move(fromX: 6, fromY: 5, toX: 7, toY: 4));
      game.executeMove(Move(fromX: 3, fromY: 2, toX: 4, toY: 3));
      game.executeMove(Move(fromX: 4, fromY: 5, toX: 3, toY: 4));
      game.executeMove(Move(fromX: 7, fromY: 2, toX: 6, toY: 3));
      game.executeMove(Move(fromX: 0, fromY: 5, toX: 1, toY: 4));
      game.executeMove(Move(fromX: 6, fromY: 1, toX: 7, toY: 2));
      game.executeMove(Move(fromX: 1, fromY: 6, toX: 0, toY: 5));
      game.executeMove(Move(fromX: 5, fromY: 0, toX: 6, toY: 1));

      final move = DexterEngine(gameLogic: game).getBestMove();

      expect(move, isNotNull);
      expect(move!.fromX, 2);
      expect(move.fromY, 7);
      expect(move.toX, 1);
      expect(move.toY, 6);
    });

    test('prefers the stronger capture when multiple captures are legal', () {
      final game = GameLogic();

      game.setupCustomBoard([
        {
          'x': 3,
          'y': 6,
          'owner': 2,
          'isDama': false,
          'terms': {2: 28},
        },
        {
          'x': 5,
          'y': 6,
          'owner': 2,
          'isDama': false,
          'terms': {1: -15},
        },
        {
          'x': 4,
          'y': 5,
          'owner': 1,
          'isDama': false,
          'terms': {1: 6},
        },
      ]);
      game.currentPlayer = 2;

      final legalMoves = game.getLegalMovesForPlayer(2);
      expect(legalMoves, hasLength(2));

      final move = DexterEngine(
        gameLogic: game,
      ).getBestMove(maxThinkingTime: const Duration(milliseconds: 120));

      expect(move, isNotNull);
      expect(move!.fromX, 3);
      expect(move.fromY, 6);
      expect(move.toX, 5);
      expect(move.toY, 4);
    });
  });

  group('GameLogic legal move generation', () {
    test('returns only capture moves when a capture is available', () {
      final game = GameLogic();

      game.setupCustomBoard([
        {
          'x': 3,
          'y': 4,
          'owner': 2,
          'isDama': false,
          'terms': {1: 6},
        },
        {
          'x': 6,
          'y': 5,
          'owner': 2,
          'isDama': false,
          'terms': {2: 10},
        },
        {
          'x': 2,
          'y': 3,
          'owner': 1,
          'isDama': false,
          'terms': {4: -1},
        },
      ]);

      game.currentPlayer = 2;

      final legalMoves = game.getLegalMovesForPlayer(2);

      expect(legalMoves, hasLength(1));
      expect(legalMoves.first.isCapture, isTrue);
      expect(legalMoves.first.fromX, 3);
      expect(legalMoves.first.fromY, 4);
      expect(legalMoves.first.toX, 1);
      expect(legalMoves.first.toY, 2);
    });
  });
}
