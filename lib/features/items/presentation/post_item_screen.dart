import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/item.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/snackbar.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/loading_button.dart';
import '../providers/items_providers.dart';
import '../../../core/theme/shapes.dart';

class PostItemScreen extends ConsumerStatefulWidget {
  const PostItemScreen({super.key});

  @override
  ConsumerState<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends ConsumerState<PostItemScreen> {
  static const _maxTitle = 100;
  static const _maxDescription = 1000;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  ItemCategory? _category;
  Uint8List? _imageBytes;
  String? _imageExtension;
  bool _saving = false;

  /// Set once the post is saved so leaving the screen doesn't ask to discard.
  bool _submitted = false;

  bool get _hasInput =>
      _title.text.trim().isNotEmpty || _description.text.trim().isNotEmpty || _imageBytes != null || _category != null;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.camera),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.photo_on_rectangle),
              title: const Text('Choose from library'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final dot = file.name.lastIndexOf('.');
      setState(() {
        _imageBytes = bytes;
        _imageExtension = dot < 0 ? 'jpg' : file.name.substring(dot + 1);
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(
        context,
        e.code.contains('camera')
            ? 'Camera not available on this device.'
            : e.code.contains('access_denied')
            ? 'Allow photo access in Settings to add an image.'
            : "Couldn't open the image picker.",
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final description = _description.text.trim();
      await ref
          .read(itemsRepositoryProvider)
          .createItem(
            title: _title.text.trim(),
            description: description.isEmpty ? null : description,
            category: _category!,
            imageBytes: _imageBytes,
            imageExtension: _imageExtension,
          );
      if (!mounted) return;
      invalidateItemLists(ref);
      showInfoSnackBar(context, 'Posted. We\'ll let you know if someone finds it.');
      _submitted = true;
      context.pop();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onPopBlocked(bool didPop, Object? _) async {
    if (didPop || _saving) return;
    if (!_hasInput || await _confirmDiscard()) {
      _submitted = true;
      if (mounted) context.pop();
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this post?'),
        content: const Text("What you've entered will be lost."),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(CupertinoIcons.pencil, size: 18),
            label: const Text('Keep editing'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(CupertinoIcons.trash, size: 18),
            label: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _submitted,
      onPopInvokedWithResult: _onPopBlocked,
      child: Scaffold(
        appBar: const AppHeader(title: 'Post lost item', showAvatar: false),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Material(
                    color: scheme.surfaceContainerHighest,
                    shape: AppShapes.border(24),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _saving ? null : _pickImage,
                      child: _imageBytes == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.camera_on_rectangle, size: 40, color: scheme.outline),
                                const SizedBox(height: 8),
                                const Text('Add a photo (optional)'),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(_imageBytes!, fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton.filledTonal(
                                    tooltip: 'Remove photo',
                                    icon: const Icon(CupertinoIcons.xmark),
                                    onPressed: _saving
                                        ? null
                                        : () => setState(() {
                                            _imageBytes = null;
                                            _imageExtension = null;
                                          }),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: _maxTitle,
                  decoration: const InputDecoration(
                    labelText: 'What did you lose?',
                    hintText: 'e.g. Black HP laptop charger',
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ItemCategory>(
                  borderRadius: AppShapes.radius(18),
                  icon: const Icon(CupertinoIcons.chevron_down, size: 18),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final c in ItemCategory.values)
                      DropdownMenuItem(
                        value: c,
                        child: Row(children: [Icon(c.icon, size: 20), const SizedBox(width: 12), Text(c.label)]),
                      ),
                  ],
                  onChanged: _saving ? null : (c) => setState(() => _category = c),
                  validator: (c) => c == null ? 'Choose a category' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: _maxDescription,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Where and when you lost it, colour, stickers, anything distinctive',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                LoadingButton(
                  label: 'Post',
                  icon: CupertinoIcons.paperplane_fill,
                  loading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
