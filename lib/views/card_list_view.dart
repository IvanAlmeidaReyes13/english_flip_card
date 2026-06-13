import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/cards_viewmodel.dart';
import '../models/flashcard.dart';
import '../services/ai_template_service.dart';
import '../services/card_import_service.dart';
import '../services/database_service.dart';
import '../components/feedback/app_loading.dart';
import '../components/feedback/app_error.dart';
import '../components/theme/app_colors.dart';
import '../components/theme/app_text_styles.dart';
import 'card_form_view.dart';

class CardListView extends StatefulWidget {
  const CardListView({super.key});

  @override
  State<CardListView> createState() => _CardListViewState();
}

class _CardListViewState extends State<CardListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardsViewModel>().loadCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Tarjetas'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          PopupMenuButton<_CardListAction>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Más opciones',
            color: AppColors.surface,
            onSelected: (action) {
              switch (action) {
                case _CardListAction.importJsonFromClipboard:
                  _importJsonFromClipboard(context);
                case _CardListAction.copyAiTemplate:
                  _copyAiTemplate(context);
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: _CardListAction.importJsonFromClipboard,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.file_upload_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Import JSON from clipboard',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _CardListAction.copyAiTemplate,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.content_copy_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Copy AI template',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Consumer<CardsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const AppLoading(message: 'Cargando tarjetas...');
          }

          if (viewModel.errorMessage != null) {
            return AppError(
              message: viewModel.errorMessage!,
              onRetry: () => viewModel.loadCards(),
            );
          }

          if (viewModel.isEmpty) {
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
                    Text('No hay tarjetas aún', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(
                      'Añade tu primera tarjeta para comenzar',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.cards.length,
            itemBuilder: (context, index) {
              final card = viewModel.cards[index];
              return _buildCardItem(context, card, viewModel);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddCard(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Añadir Tarjeta'),
      ),
    );
  }

  Widget _buildCardItem(
    BuildContext context,
    Flashcard card,
    CardsViewModel viewModel,
  ) {
    final cardColor =
        AppColors.cardPalette[card.colorIndex % AppColors.cardPalette.length];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 80,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.english, style: AppTextStyles.heading2),
                  const SizedBox(height: 6),
                  Text(
                    card.spanish,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (card.notes != null && card.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(card.notes!, style: AppTextStyles.bodySmall),
                  ],
                  const SizedBox(height: 10),
                  _buildKnowledgeLevel(card.knowledgeLevel),
                ],
              ),
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () => _navigateToEditCard(context, card),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: () => _confirmDelete(context, card, viewModel),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildKnowledgeLevel(int level) {
    final color =
        level < 30
            ? AppColors.error
            : level < 70
            ? AppColors.warning
            : AppColors.success;

    return Row(
      children: [
        SizedBox(
          width: 100,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: level / 100,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$level%', style: AppTextStyles.caption.copyWith(color: color)),
      ],
    );
  }

  void _navigateToAddCard(BuildContext context) {
    final cardsVm = context.read<CardsViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CardFormView()),
    ).then((_) {
      cardsVm.loadCards();
    });
  }

  Future<void> _copyAiTemplate(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(text: AiTemplateService.vocabularyJsonPrompt),
    );

    if (!context.mounted) return;
    _showSnackBar(context, 'AI template copied', seconds: 2);
  }

  Future<void> _importJsonFromClipboard(BuildContext context) async {
    final dbService = context.read<DatabaseService>();
    final cardsViewModel = context.read<CardsViewModel>();
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final jsonText = clipboardData?.text?.trim();

    if (jsonText == null || jsonText.isEmpty) {
      if (!context.mounted) return;
      _showSnackBar(context, 'Clipboard is empty');
      return;
    }

    try {
      final result = await CardImportService(
        dbService,
      ).importFromJsonText(jsonText);

      if (!context.mounted) return;

      await cardsViewModel.loadCards();
      if (!context.mounted) return;

      _showSnackBar(
        context,
        'Imported: ${result.imported} · Duplicates: ${result.skippedDuplicates} · Invalid: ${result.skippedInvalid}',
      );
    } on FormatException {
      if (!context.mounted) return;
      _showSnackBar(context, 'This is not valid JSON');
    } on CardImportException {
      if (!context.mounted) return;
      _showSnackBar(context, 'This file is not a valid vocabulary import file');
    }
  }

  void _showSnackBar(BuildContext context, String message, {int seconds = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceVariant,
        duration: Duration(seconds: seconds),
      ),
    );
  }

  void _navigateToEditCard(BuildContext context, Flashcard card) {
    final cardsVm = context.read<CardsViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CardFormView(card: card)),
    ).then((_) {
      cardsVm.loadCards();
    });
  }

  void _confirmDelete(
    BuildContext context,
    Flashcard card,
    CardsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Eliminar Tarjeta', style: AppTextStyles.heading3),
            content: Text(
              '¿Estás seguro de que quieres eliminar "${card.english}"?',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await viewModel.deleteCard(card.id);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }
}

enum _CardListAction { importJsonFromClipboard, copyAiTemplate }
