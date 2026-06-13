import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/game_viewmodel.dart';
import '../widgets/flashcard_widget.dart';
import '../components/feedback/app_loading.dart';
import '../components/feedback/app_error.dart';
import '../components/theme/app_colors.dart';
import '../components/theme/app_text_styles.dart';

class GameView extends StatefulWidget {
  const GameView({super.key});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameViewModel>().startGame();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<GameViewModel>().refreshCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Práctica'),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            tooltip: 'Cómo jugar',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => context.read<GameViewModel>().toggleTutorial(),
          ),
        ],
      ),
      body: Consumer<GameViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const AppLoading(message: 'Cargando juego...');
          }

          if (viewModel.errorMessage != null) {
            return AppError(
              message: viewModel.errorMessage!,
              onRetry: () => viewModel.startGame(),
            );
          }

          if (viewModel.sessionTotalCards == 0) {
            return _buildEmptyState();
          }

          if (viewModel.sessionComplete) {
            return _buildSessionComplete(viewModel);
          }

          final card = viewModel.currentCard!;
          final cardColor = _getCardColor(card.colorIndex);

          return Stack(
            children: [
              Column(
                children: [
                  _buildPracticeHeader(viewModel, cardColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                      child: FlashcardWidget(
                        key: ValueKey(card.id),
                        frontText: card.english,
                        backText: card.spanish,
                        noteText: card.notes,
                        cardColor: cardColor,
                        mastery: card.knowledgeLevel,
                        onSwipeLeft: () => viewModel.swipeLeft(),
                        onSwipeRight: () => viewModel.swipeRight(),
                        onTap: () => viewModel.flipCard(),
                      ),
                    ),
                  ),
                  _buildActionDock(viewModel),
                  const SizedBox(height: 12),
                ],
              ),
              if (viewModel.showTutorial)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 92,
                  child: _buildTutorial(viewModel),
                ),
              if (viewModel.animateStreak) _buildStreakAnimation(viewModel),
            ],
          );
        },
      ),
    );
  }

  Color _getCardColor(int index) {
    return AppColors.cardPalette[index % AppColors.cardPalette.length];
  }

  Widget _buildPracticeHeader(GameViewModel viewModel, Color accentColor) {
    final total = viewModel.sessionTotalCards;
    final position = viewModel.currentPosition;
    final progress = total == 0 ? 0.0 : position / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '$position / $total',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (viewModel.streak > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${viewModel.streak}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: progress,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDock(GameViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => viewModel.swipeLeft(),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Repasar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => viewModel.swipeRight(),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Lo sé'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.style_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text('No hay tarjetas disponibles', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'Añade tarjetas para comenzar a jugar',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakAnimation(GameViewModel viewModel) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) {
          return Opacity(
            opacity: 1.0 - value,
            child: Transform.scale(
              scale: 1.0 + (value * 0.5),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${viewModel.streak}x',
                      style: AppTextStyles.heading1.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTutorial(GameViewModel viewModel) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildInstructionItem(
                icon: Icons.swipe_left_rounded,
                label: 'Repasar',
                color: AppColors.error,
              ),
            ),
            Expanded(
              child: _buildInstructionItem(
                icon: Icons.touch_app_rounded,
                label: 'Voltear',
                color: AppColors.info,
              ),
            ),
            Expanded(
              child: _buildInstructionItem(
                icon: Icons.swipe_right_rounded,
                label: 'Lo sé',
                color: AppColors.success,
              ),
            ),
            IconButton(
              tooltip: 'Cerrar tutorial',
              icon: const Icon(
                Icons.close_rounded,
                size: 19,
                color: AppColors.textTertiary,
              ),
              onPressed: () => viewModel.dismissTutorial(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionComplete(GameViewModel viewModel) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text('¡Sesión completada!', style: AppTextStyles.heading1),
            const SizedBox(height: 16),
            if (viewModel.bestStreak >= 5) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: AppColors.warning,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mejor racha: ${viewModel.bestStreak}',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Has repasado todas las tarjetas',
              style: AppTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vuelve cuando quieras hacer otra sesión',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => viewModel.startGame(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Nueva sesión', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
