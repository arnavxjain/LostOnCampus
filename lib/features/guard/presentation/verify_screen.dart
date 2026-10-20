import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/item.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/async_view.dart';
import '../../items/presentation/widgets/handover_info.dart';
import '../../items/presentation/widgets/item_grid.dart';
import '../../items/providers/items_providers.dart';
import 'admin_pills.dart';
import 'otp_match.dart';
import 'trace_complete_sheet.dart';

/// Type the code the owner gives; the matching item appears. A full code with
/// no match means nothing is handed over.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _trace(Item item) async {
    final done = await showTraceCompleteSheet(context, item, initialCode: _code.text);
    if (!done || !mounted) return;
    setState(_code.clear);
    invalidateItemLists(ref);
    showTraceCompleteDone(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(adminItemsProvider);
    final textTheme = Theme.of(context).textTheme;

    final codeField = Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Owner's pickup code", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Ask the owner for the 6-digit code shown in their app.', style: textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            onChanged: (_) => setState(() {}),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 10,
              color: AppColors.teal,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              hintText: '••••••',
              hintStyle: textTheme.displaySmall?.copyWith(letterSpacing: 10, color: AppColors.teal36),
              suffixIcon: _code.text.isEmpty
                  ? null
                  : IconButton(tooltip: 'Clear', icon: const Icon(CupertinoIcons.xmark), onPressed: () => setState(_code.clear)),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: const AppHeader(title: 'Verify', showAvatar: false),
      body: AsyncView(
        value: items,
        onRetry: () => ref.invalidate(adminItemsProvider),
        data: (all) {
          final typed = _code.text;
          final result = matchOtp(
            typed: typed,
            atSecurity: all.where((i) => i.status == ItemStatus.atSecurity).toList(),
            returned: all.where((i) => i.status == ItemStatus.returned).toList(),
          );

          if (typed.isEmpty) {
            return ListView(
              children: [
                codeField,
                const MessageView(icon: CupertinoIcons.number_square, title: 'Enter a code to find the matching item'),
              ],
            );
          }
          if (result.noMatch) {
            return ListView(
              children: [
                codeField,
                MessageView(
                  icon: CupertinoIcons.nosign,
                  title: result.alreadyUsed ? 'This code was already used' : 'No item matches ${spacedCode(typed)}',
                  subtitle: result.alreadyUsed
                      ? 'That item has already been collected.'
                      : "Don't hand anything over. Ask the owner to check the code in their app.",
                ),
              ],
            );
          }
          return ItemGrid(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                codeField,
                if (result.matches.isEmpty)
                  MessageView(icon: CupertinoIcons.search, title: 'No codes start with $typed')
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      result.isFullCode ? 'Match found: tap it to complete the trace' : 'Keep typing…',
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            items: result.matches,
            pillsFor: adminPills,
            onTap: _trace,
          );
        },
      ),
    );
  }
}
