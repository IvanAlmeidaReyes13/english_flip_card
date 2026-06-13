import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/cards_viewmodel.dart';
import '../models/flashcard.dart';
import '../components/inputs/app_text_field.dart';
import '../components/buttons/app_button.dart';
import '../components/theme/app_colors.dart';

class CardFormView extends StatefulWidget {
  final Flashcard? card;

  const CardFormView({super.key, this.card});

  @override
  State<CardFormView> createState() => _CardFormViewState();
}

class _CardFormViewState extends State<CardFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _englishController;
  late TextEditingController _spanishController;
  late TextEditingController _notesController;
  bool _isSaving = false;

  bool get isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    _englishController = TextEditingController(
      text: widget.card?.english ?? '',
    );
    _spanishController = TextEditingController(
      text: widget.card?.spanish ?? '',
    );
    _notesController = TextEditingController(text: widget.card?.notes ?? '');
  }

  @override
  void dispose() {
    _englishController.dispose();
    _spanishController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Tarjeta' : 'Nueva Tarjeta'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Inglés',
                hint: 'Ej: Hello',
                controller: _englishController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, introduce la palabra en inglés';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Español',
                hint: 'Ej: Hola',
                controller: _spanishController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, introduce la traducción en español';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Notas (opcional)',
                hint: 'Ej: Saludo informal',
                controller: _notesController,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 32),
              Consumer<CardsViewModel>(
                builder: (context, viewModel, child) {
                  return AppButton(
                    text: isEditing ? 'Guardar Cambios' : 'Añadir Tarjeta',
                    onPressed: _isSaving ? null : () => _saveCard(viewModel),
                    isLoading: _isSaving,
                    icon: isEditing ? Icons.save : Icons.add,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCard(CardsViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final english = _capitalizeWords(_englishController.text);
    final spanish = _capitalizeWords(_spanishController.text);
    final notes =
        _notesController.text.trim().isEmpty
            ? null
            : _capitalizeSentence(_notesController.text);

    bool success;
    if (isEditing) {
      final updatedCard = widget.card!.copyWith(
        english: english,
        spanish: spanish,
        notes: notes,
      );
      success = await viewModel.updateCard(updatedCard);
    } else {
      success = await viewModel.addCard(english, spanish, notes: notes);
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Error al guardar'),
            backgroundColor: AppColors.error,
          ),
        );
        viewModel.clearError();
      }
    }
  }

  String _capitalizeWords(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _capitalizeSentence(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }
}
