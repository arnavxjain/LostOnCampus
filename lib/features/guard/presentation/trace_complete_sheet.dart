import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/item.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/snackbar.dart';
import '../../../shared/utils/time_ago.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../items/presentation/widgets/handover_info.dart';
import '../../items/presentation/widgets/item_image.dart';
import '../../items/providers/items_providers.dart';
import '../../../core/theme/shapes.dart';

/// Admin confirms the owner's code matches this item and hands it over.
/// Returns true once the handover is marked complete.
Future<bool> showTraceCompleteSheet(BuildContext context, Item item, {String initialCode = ''}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TraceCompleteSheet(item: item, initialCode: initialCode),
  );
  return result ?? false;
}

class _TraceCompleteSheet extends ConsumerStatefulWidget {
  const _TraceCompleteSheet({required this.item, required this.initialCode});

  final Item item;
  final String initialCode;

  @override
  ConsumerState<_TraceCompleteSheet> createState() => _TraceCompleteSheetState();
}

class _TraceCompleteSheetState extends ConsumerState<_TraceCompleteSheet> {
  late final TextEditingController _code = TextEditingController(text: widget.initialCode);
  bool _saving = false;

  ItemHandover get _handover => widget.item.handover!;
  bool get _matches => _code.text == _handover.code;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    setState(() => _saving = true);
    try {
      await ref.read(itemsRepositoryProvider).completeHandover(handoverId: _handover.id, code: _code.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final typed = _code.text.length == 6;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Squircle(
              radius: 24,
              child: AspectRatio(aspectRatio: 16 / 10, child: ItemImage(item: item, iconSize: 56)),
            ),
            const SizedBox(height: 16),
            Text(item.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${item.category.label} · handed in ${timeAgo(_handover.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text('Finder\'s note', style: theme.textTheme.titleSmall),
            Text(_handover.note),
            if (item.description case final d? when d.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Owner\'s description', style: theme.textTheme.titleSmall),
              Text(d),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Code given by the owner',
                errorText: typed && !_matches ? "Doesn't match this item. Don't hand it over." : null,
                suffixIcon: _matches ? Icon(CupertinoIcons.checkmark_circle_fill, color: theme.colorScheme.primary) : null,
              ),
            ),
            const SizedBox(height: 8),
            Text('Expected: ${spacedCode(_handover.code ?? '')}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            LoadingButton(
              label: 'Trace complete: item handed over',
              icon: CupertinoIcons.checkmark_seal_fill,
              loading: _saving,
              onPressed: _matches ? _complete : null,
            ),
          ],
        ),
      ),
    );
  }
}

void showTraceCompleteDone(BuildContext context, Item item) =>
    showInfoSnackBar(context, 'Trace complete. "${item.title}" handed over.');
