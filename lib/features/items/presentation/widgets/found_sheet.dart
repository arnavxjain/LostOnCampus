import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/item.dart';
import '../../../../shared/utils/error_message.dart';
import '../../../../shared/utils/snackbar.dart';
import '../../../../shared/widgets/loading_button.dart';
import '../../providers/items_providers.dart';

/// Bottom sheet for a finder: confirm they've handed the item to security and
/// say which desk. Returns true once the item has been reported found.
Future<bool> showFoundSheet(BuildContext context, Item item) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FoundSheet(item: item),
  );
  return result ?? false;
}

class _FoundSheet extends ConsumerStatefulWidget {
  const _FoundSheet({required this.item});

  final Item item;

  @override
  ConsumerState<_FoundSheet> createState() => _FoundSheetState();
}

class _FoundSheetState extends ConsumerState<_FoundSheet> {
  static const _maxNote = 300;

  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(itemsRepositoryProvider).reportFound(itemId: widget.item.id, note: _note.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      // Keep the field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Text('Found "${widget.item.title}"?', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Hand the item to a security guard first, then tell us where you left it. '
                'The owner will be notified and given a pickup code.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _note,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                maxLength: _maxNote,
                decoration: const InputDecoration(
                  labelText: 'Which security desk has it?',
                  hintText: 'e.g. Left with the Floor 2 security guard near the lifts',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Add a note so the owner knows where to go';
                  if (t.length < 3) return 'Add a bit more detail';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              LoadingButton(label: 'I handed it to security', loading: _saving, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the confirmation after a successful report.
void showFoundThanks(BuildContext context) =>
    showInfoSnackBar(context, 'Thank you! The owner has been notified and given a pickup code.');
