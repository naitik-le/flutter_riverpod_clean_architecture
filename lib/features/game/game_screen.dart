import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'task_breaker_game.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// GameScreen wraps our [TaskBreakerGame] Flame Canvas in a standard Flutter screen.
/// Offers full game overlays for game state notifications (score, lives, win/lose, restart).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late TaskBreakerGame _game;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _game = TaskBreakerGame(onScoreChanged: () => setState(() {}), onGameOver: () => setState(() {}), onGameWon: () => setState(() {}));
  }

  void _restartGame() {
    setState(() {
      _game.resetGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.videogame_asset_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text('Breakroom Playroom', style: AppTextStyles.h2(textThemeColor)),
          ],
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              // 1. Top HUD stats bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.stars_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text('Score: ${_game.score}', style: AppTextStyles.bodySemiBold(textThemeColor)),
                      ],
                    ),
                    Row(
                      children: List.generate(3, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Icon(index < _game.lives ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: AppColors.error, size: 18),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Flame Game canvas with absolute overlays
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF070B19) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      // The main Flame Game Widget!
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: GameWidget(game: _game),
                      ),

                      // Game Over Overlay
                      if (_game.isGameOver)
                        Container(
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), shape: BoxShape.circle),
                                    child: Icon(Icons.sentiment_very_dissatisfied_rounded, color: AppColors.error, size: 56),
                                  ),
                                  const SizedBox(height: 24),
                                  Text('Tasks Overwhelmed!', style: AppTextStyles.display(Colors.white), textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  Text('You ran out of collaboration energy. Let\'s try again!', style: AppTextStyles.bodyMedium(secondaryTextColor), textAlign: TextAlign.center),
                                  const SizedBox(height: 28),
                                  ElevatedButton.icon(onPressed: _restartGame, icon: const Icon(Icons.replay_rounded), label: const Text('Restart Sprint')),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Victory Overlay
                      if (_game.isWon)
                        Container(
                          color: Colors.black.withOpacity(0.85),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), shape: BoxShape.circle),
                                    child: const Icon(Icons.workspace_premium_rounded, color: AppColors.accent, size: 56),
                                  ),
                                  const SizedBox(height: 24),
                                  Text('Sprint Success!', style: AppTextStyles.display(Colors.white), textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  Text('Awesome! All workspace blockades have been cleared.', style: AppTextStyles.bodyMedium(secondaryTextColor), textAlign: TextAlign.center),
                                  const SizedBox(height: 28),
                                  ElevatedButton.icon(
                                    onPressed: _restartGame,
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: const Text('Play Again'),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
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
              const SizedBox(height: 12),
              Text('Drag or Pan horizontally to control the paddle', style: AppTextStyles.caption(secondaryTextColor)),
            ],
          ),
        ),
      ),
    );
  }
}
