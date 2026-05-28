import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// TaskBreakerGame is a premium collaborative breakroom game built using Flame.
/// Users clear workspace tasks ("Bugs", "Meetings", "Deployments") by bouncing
/// a "Collaboration Ball" off a horizontal paddle.
class TaskBreakerGame extends FlameGame with PanDetector {
  late Paddle paddle;
  late Ball ball;
  final List<TaskBrick> bricks = [];

  int score = 0;
  int lives = 3;
  bool isGameOver = false;
  bool isWon = false;

  // Callbacks to notify the Flutter UI of state updates
  final VoidCallback onScoreChanged;
  final VoidCallback onGameOver;
  final VoidCallback onGameWon;

  TaskBreakerGame({required this.onScoreChanged, required this.onGameOver, required this.onGameWon});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    resetGame();
  }

  void resetGame() {
    score = 0;
    lives = 3;
    isGameOver = false;
    isWon = false;

    // Clear existing components
    removeAll(children);
    bricks.clear();

    // 1. Create and add Paddle
    paddle = Paddle(position: Vector2(size.x / 2 - 60, size.y - 60), size: Vector2(120, 16));
    add(paddle);

    // 2. Create and add Ball
    ball = Ball(
      position: Vector2(size.x / 2, size.y - 100),
      radius: 8,
      velocity: Vector2(180, -250), // Standard pixels per second velocity
    );
    add(ball);

    // 3. Create grid of Workspace Bricks (Tasks)
    const double spacing = 10.0;
    final double brickWidth = (size.x - (spacing * 6)) / 5;
    const double brickHeight = 24.0;

    final taskTitles = [
      ['Fix Bugs', 'Meetings', 'Fix Bugs', 'Meetings', 'Fix Bugs'],
      ['Deploy Code', 'Sprint Plan', 'Deploy Code', 'Sprint Plan', 'Deploy Code'],
      ['Code Review', 'Standup', 'Code Review', 'Standup', 'Code Review'],
    ];

    final colors = [
      AppColors.error, // Red for Bugs/Deploy
      AppColors.primary, // Indigo for Sprint/Code
      AppColors.accent, // Green for Success/Meetings
    ];

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 5; col++) {
        final brick = TaskBrick(
          position: Vector2(spacing + (col * (brickWidth + spacing)), 60 + (row * (brickHeight + spacing))),
          size: Vector2(brickWidth, brickHeight),
          title: taskTitles[row][col],
          color: colors[row % colors.length],
        );
        bricks.add(brick);
        add(brick);
      }
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (isGameOver || isWon) return;

    // Smoothly drag paddle horizontally
    paddle.position.x = info.eventPosition.global.x - paddle.size.x / 2;

    // Keep paddle inside viewport borders
    if (paddle.position.x < 0) {
      paddle.position.x = 0;
    }
    if (paddle.position.x > size.x - paddle.size.x) {
      paddle.position.x = size.x - paddle.size.x;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver || isWon) return;

    // Check custom bounding collisions (extremely robust across all Flame versions)
    _checkCollisions(dt);
  }

  void _checkCollisions(double dt) {
    // 1. Ball updates and bounces on walls
    ball.position.x += ball.velocity.x * dt;
    ball.position.y += ball.velocity.y * dt;

    // Side walls
    if (ball.position.x - ball.radius < 0) {
      ball.position.x = ball.radius;
      ball.velocity.x = -ball.velocity.x;
    }
    if (ball.position.x + ball.radius > size.x) {
      ball.position.x = size.x - ball.radius;
      ball.velocity.x = -ball.velocity.x;
    }

    // Top wall
    if (ball.position.y - ball.radius < 0) {
      ball.position.y = ball.radius;
      ball.velocity.y = -ball.velocity.y;
    }

    // Bottom wall (Lose a life)
    if (ball.position.y + ball.radius > size.y) {
      lives--;
      if (lives <= 0) {
        isGameOver = true;
        onGameOver();
      } else {
        // Reset ball position
        ball.position = Vector2(size.x / 2, size.y - 100);
        ball.velocity = Vector2((Random().nextBool() ? 180 : -180), -250);
      }
      return;
    }

    // 2. Paddle collision check
    final ballRect = Rect.fromCircle(center: Offset(ball.position.x, ball.position.y), radius: ball.radius);
    final paddleRect = Rect.fromLTWH(paddle.position.x, paddle.position.y, paddle.size.x, paddle.size.y);

    if (ballRect.overlaps(paddleRect)) {
      // Reverse vertical direction
      ball.position.y = paddle.position.y - ball.radius;
      ball.velocity.y = -ball.velocity.y;

      // Add angle deviation based on where the ball hits the paddle
      final paddleCenter = paddle.position.x + (paddle.size.x / 2);
      final offsetFactor = (ball.position.x - paddleCenter) / (paddle.size.x / 2);
      ball.velocity.x = offsetFactor * 250; // Dynamic horizontal bounce
    }

    // 3. Bricks collision check
    for (int i = bricks.length - 1; i >= 0; i--) {
      final brick = bricks[i];
      final brickRect = Rect.fromLTWH(brick.position.x, brick.position.y, brick.size.x, brick.size.y);

      if (ballRect.overlaps(brickRect)) {
        // Remove brick
        remove(brick);
        bricks.removeAt(i);

        // Simple bounce back
        ball.velocity.y = -ball.velocity.y;

        // Increase score
        score += 10;
        onScoreChanged();

        // Check victory
        if (bricks.isEmpty) {
          isWon = true;
          onGameWon();
        }
        break;
      }
    }
  }
}

// --- Flame Drawing Components ---

class Paddle extends PositionComponent {
  Paddle({required super.position, required super.size});

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    // Draw beautiful rounded pill shape
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(8)), paint);

    // Subtle gloss highlight
    final glossPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, 2, size.x - 8, 3), const Radius.circular(2)), glossPaint);
  }
}

class Ball extends PositionComponent {
  final double radius;
  Vector2 velocity;

  Ball({required super.position, required this.radius, required this.velocity}) : super(size: Vector2(radius * 2, radius * 2));

  @override
  void render(Canvas canvas) {
    // Draw outer glowing ring
    final glowPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(radius, radius), radius + 2, glowPaint);

    // Draw main solid sphere
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Draw core highlight
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius - 2, radius - 2), 2, innerPaint);
  }
}

class TaskBrick extends PositionComponent {
  final String title;
  final Color color;

  TaskBrick({required super.position, required super.size, required this.title, required this.color});

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // Draw card background
    canvas.drawRRect(rrect, paint);
    canvas.drawRRect(rrect, borderPaint);

    // Draw truncated title text inside the brick
    final textPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(color: color, fontSize: size.x < 70 ? 8 : 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.x - 4);

    // Center text vertically and horizontally
    final offset = Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2);
    textPainter.paint(canvas, offset);
  }
}
