import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/community_config.dart';
import '../../core/navigation/navigation_helpers.dart';
import '../../core/services/photo_picker_service.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/bite_guide.dart';
import '../../data/models/bite_filters.dart';
import '../../data/models/community_post.dart';
import '../../data/seed/seed_data.dart';
import '../../state/app_controller.dart';
import '../../state/auth_controller.dart';
import '../../state/community_providers.dart';
import 'widgets/add_bite_widgets.dart';

class AddBiteScreen extends ConsumerStatefulWidget {
  const AddBiteScreen({super.key, this.initialPost});

  final CommunityPost? initialPost;

  @override
  ConsumerState<AddBiteScreen> createState() => _AddBiteScreenState();
}

class _AddBiteScreenState extends ConsumerState<AddBiteScreen> {
  static const _otherBug = 'other';

  final _formKey = GlobalKey<FormState>();
  final _detailsController = TextEditingController();
  final _customBugController = TextEditingController();
  final Set<String> _tags = <String>{'itchy'};
  String _guideId = 'mosquito';
  bool _acknowledged = false;
  bool _loadingPhoto = false;
  bool _submitting = false;
  Uint8List? _photoBytes;
  late final String _draftId;

  @override
  void initState() {
    super.initState();
    final post = widget.initialPost;
    _draftId = post == null
        ? 'draft-${DateTime.now().microsecondsSinceEpoch}'
        : 'legacy-${post.authorId}-${post.id}';
    if (post == null) return;
    _detailsController.text = post.body;
    _guideId = guides.any((guide) => guide.id == post.guideId)
        ? post.guideId!
        : _otherBug;
    _customBugController.text = post.possibleMatch.replaceFirst(
      RegExp(r'^Possible\s+', caseSensitive: false),
      '',
    );
    _photoBytes = post.imageBytes;
    _tags
      ..clear()
      ..addAll(BiteFilters.normalizeAll(post.tags));
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _customBugController.dispose();
    super.dispose();
  }

  BiteGuide? get _selectedGuide => _guideId == _otherBug
      ? null
      : guides.firstWhere((guide) => guide.id == _guideId);

  Future<void> _pickPhoto() async {
    if (!communityPhotoUploadsEnabled) return;
    setState(() => _loadingPhoto = true);
    try {
      final image = await const PhotoPickerService().pickFromLibrary();
      if (!mounted || image == null) return;
      setState(() => _photoBytes = image);
    } on PhotoSelectionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (!communityPhotoUploadsEnabled && _photoBytes != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo uploads are coming soon. Remove the photo to publish a text experience; the original private note keeps its photo.',
          ),
        ),
      );
      return;
    }
    if (!_acknowledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge the safety note before sharing.'),
        ),
      );
      return;
    }
    final initialPost = widget.initialPost;
    if (initialPost != null &&
        initialPost.authorId != ref.read(currentUserProvider)?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to the account that owns this private note.'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final selectedGuide = _selectedGuide;
    final matchName =
        selectedGuide?.title.toLowerCase() ?? _customBugController.text.trim();
    final remoteId = await ref
        .read(communityActionsProvider.notifier)
        .publishPost(
          draftId: _draftId,
          possibleMatch: 'Possible $matchName',
          body: _detailsController.text.trim(),
          guideId: selectedGuide?.id,
          tags: _tags.toList(growable: false),
          imageBytes: _photoBytes,
        );
    if (!mounted) return;
    if (remoteId != null && initialPost != null) {
      final marked = await ref
          .read(appControllerProvider.notifier)
          .markLegacyPublished(
            localPostId: initialPost.id,
            remotePostId: remoteId,
          );
      if (!mounted) return;
      if (!marked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Published online. This device could not update the private-note label; reviewing it again will not create a duplicate.',
            ),
          ),
        );
      }
    }
    setState(() => _submitting = false);
    if (remoteId != null) {
      context.go('/community');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(communityActionsProvider).errorMessage ??
              'Your experience could not be published. Check your connection and try again. Your draft is still here.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => popOrGo(context, '/community'),
      ),
      title: Text(
        widget.initialPost == null ? 'Share an experience' : 'Review & publish',
      ),
    ),
    body: SafeArea(
      top: false,
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
          children: <Widget>[
            // Keep every field registered with Form even when the longer tag
            // list scrolls a required field out of the viewport.
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Help others compare safely.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  communityPhotoUploadsEnabled
                      ? 'Share what you noticed and what helped. Published posts and photos are visible to other signed-in members. Do not include names, contact details, or identifying photos.'
                      : 'Share what you noticed and what helped. Published posts are visible to other signed-in members. Do not include names, contact details, or identifying information.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SectionHeader(
                  title: communityPhotoUploadsEnabled
                      ? 'Photo (optional)'
                      : 'Photo',
                ),
                if (!communityPhotoUploadsEnabled)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: PhotoComingSoon(key: ValueKey('photo-coming-soon')),
                  ),
                if (widget.initialPost != null)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      communityPhotoUploadsEnabled
                          ? 'This note is currently private on this device. Only the text, selected tags, and photo you approve below will be published. Previous local likes and comments are not copied.'
                          : 'This note is currently private on this device. Only the text and selected tags you approve below will be published. Original photos stay private, and previous local likes and comments are not copied.',
                    ),
                  ),
                if (communityPhotoUploadsEnabled || _photoBytes != null)
                  PhotoAttachment(
                    bytes: _photoBytes,
                    previewAsset: _selectedGuide?.thumbnail.asset,
                    isLoading: _loadingPhoto,
                    onPick: _pickPhoto,
                    onRemove: () => setState(() => _photoBytes = null),
                  ),
                SectionHeader(title: 'What might it resemble?'),
                DropdownButtonFormField<String>(
                  key: const Key('possible-match'),
                  initialValue: _guideId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.visibility_outlined),
                  ),
                  items: <DropdownMenuItem<String>>[
                    for (final guide in guides)
                      DropdownMenuItem<String>(
                        value: guide.id,
                        child: Text('${guide.title} — possible match'),
                      ),
                    const DropdownMenuItem<String>(
                      value: _otherBug,
                      child: Text('Other bug'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _guideId = value);
                  },
                ),
                if (_guideId == _otherBug) ...<Widget>[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('custom-bug-name'),
                    controller: _customBugController,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: 'Possible bug name',
                      hintText: 'For example: sand flea',
                      helperText:
                          'Your suggestion, not a confirmed identification.',
                      helperMaxLines: 2,
                    ),
                    validator: (value) {
                      final length = (value ?? '').trim().length;
                      return length < 2 || length > 60
                          ? 'Enter a bug name between 2 and 60 characters.'
                          : null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'A few details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 7),
                TextFormField(
                  key: const Key('experience-details'),
                  controller: _detailsController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                    alignLabelWithHint: true,
                    hintText:
                        'For example: where it appeared, what you noticed, and any gentle step that helped.',
                  ),
                  validator: (value) {
                    final length = (value ?? '').trim().length;
                    return length < 12 || length > 4000
                        ? 'Enter between 12 and 4,000 characters.'
                        : null;
                  },
                ),
                SectionHeader(title: 'Tags'),
                BiteTagSelector(
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
                  title: Text(
                    'I agree to publish this for other signed-in members. It is a personal experience, not a confirmed identification or medical advice.${communityPhotoUploadsEnabled && _photoBytes != null ? ' I have permission to share this photo.' : ''}',
                    style: const TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_submitting ? 'Publishing…' : 'Share carefully'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
