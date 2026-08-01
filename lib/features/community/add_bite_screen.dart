import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/photo_picker_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/bite_guide.dart';
import '../../data/seed/seed_data.dart';
import '../../state/app_controller.dart';

class AddBiteScreen extends ConsumerStatefulWidget {
  const AddBiteScreen({super.key});

  @override
  ConsumerState<AddBiteScreen> createState() => _AddBiteScreenState();
}

class _AddBiteScreenState extends ConsumerState<AddBiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final Set<String> _tags = <String>{'Itchy'};
  String _guideId = 'mosquito';
  bool _acknowledged = false;
  bool _loadingPhoto = false;
  Uint8List? _photoBytes;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  BiteGuide get _selectedGuide =>
      guides.firstWhere((guide) => guide.id == _guideId);

  Future<void> _pickPhoto() async {
    setState(() => _loadingPhoto = true);
    try {
      final image = await const PhotoPickerService().pickFromLibrary();
      if (!mounted || image == null) return;
      setState(() => _photoBytes = image);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo library is unavailable right now. You can still share without a photo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingPhoto = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_acknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge the safety note before sharing.'),
        ),
      );
      return;
    }
    ref
        .read(appControllerProvider.notifier)
        .addCommunityPost(
          possibleMatch: 'Possible ${_selectedGuide.title.toLowerCase()}',
          body: _detailsController.text.trim(),
          visual: _selectedGuide.visual,
          tags: _tags.toList(growable: false),
          imageBytes: _photoBytes,
        );
    context.go('/community');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => context.pop(),
      ),
      title: const Text('Share an experience'),
    ),
    body: SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
          children: <Widget>[
            Text(
              'Help others compare safely.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Share what you noticed and what helped. Avoid claiming a definite diagnosis.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SectionHeader(title: 'Photo (optional)'),
            _PhotoAttachment(
              bytes: _photoBytes,
              visual: _selectedGuide.visual,
              isLoading: _loadingPhoto,
              onPick: _pickPhoto,
              onRemove: () => setState(() => _photoBytes = null),
            ),
            SectionHeader(title: 'What might it resemble?'),
            DropdownButtonFormField<String>(
              initialValue: _guideId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.visibility_outlined),
              ),
              items: guides
                  .map(
                    (guide) => DropdownMenuItem<String>(
                      value: guide.id,
                      child: Text('${guide.title} — possible match'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _guideId = value);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'A few details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 7),
            TextFormField(
              controller: _detailsController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                hintText:
                    'For example: where it appeared, what you noticed, and any gentle step that helped.',
              ),
              validator: (value) => (value ?? '').trim().length < 12
                  ? 'Add a little more detail (at least 12 characters).'
                  : null,
            ),
            SectionHeader(title: 'Tags'),
            _TagSelector(
              selected: _tags,
              onChanged: (tag, selected) => setState(() {
                if (selected) {
                  _tags.add(tag);
                } else {
                  _tags.remove(tag);
                }
              }),
            ),
            const SizedBox(height: 16),
            const SafetyNotice(compact: true),
            CheckboxListTile(
              value: _acknowledged,
              onChanged: (value) =>
                  setState(() => _acknowledged = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I understand this is a personal experience, not a confirmed identification or medical advice.',
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Share carefully'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PhotoAttachment extends StatelessWidget {
  const _PhotoAttachment({
    required this.bytes,
    required this.visual,
    required this.isLoading,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final BiteVisual visual;
  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
    height: 190,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.apricot,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
    child: bytes == null
        ? InkWell(
            onTap: isLoading ? null : onPick,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AssetCrop(
                  asset: AppAssets.bugBitePairs,
                  alignment: visualAlignment(visual),
                  borderRadius: BorderRadius.zero,
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(color: Color(0x990F0A09)),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (isLoading)
                          const CircularProgressIndicator(color: Colors.white)
                        else
                          const Icon(
                            Icons.add_a_photo_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          isLoading
                              ? 'Opening your photo library…'
                              : 'Add a photo from your library',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Optional · shared only with this post',
                          style: TextStyle(
                            color: Color(0xFFEEDDD8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.memory(
                bytes!,
                fit: BoxFit.cover,
                semanticLabel: 'Selected bite photo',
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton.filled(
                  tooltip: 'Remove photo',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
  );
}

class _TagSelector extends StatelessWidget {
  const _TagSelector({required this.selected, required this.onChanged});

  final Set<String> selected;
  final void Function(String tag, bool selected) onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children:
        const <String>[
              'Itchy',
              'Red',
              'Cluster',
              'Outdoors',
              'Improving',
              'Checked with clinician',
            ]
            .map(
              (tag) => FilterChip(
                label: Text(tag),
                selected: selected.contains(tag),
                onSelected: (value) => onChanged(tag, value),
              ),
            )
            .toList(),
  );
}
