import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_widgets.dart';

/// A full-page, reassuring loading state for local history and suggestions.
class ProfileDataLoadingView extends StatelessWidget {
  const ProfileDataLoadingView({required this.photoAsset, super.key});

  final String photoAsset;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.canvas,
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 64).clamp(0, double.infinity),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      height: 230,
                      decoration: BoxDecoration(
                        color: AppColors.apricot,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x147A4B4F),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: AssetCrop(
                        asset: photoAsset,
                        borderRadius: BorderRadius.circular(27),
                        semanticLabel:
                            'Photograph of a honey bee visiting a flower',
                        overlay: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.transparent,
                                Color(0x1A825257),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Semantics(
                      header: true,
                      child: Text(
                        'Gathering your bite guides',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We’re bringing your recent views, saved guides, and '
                      'helpful recommendations together.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      liveRegion: true,
                      label: 'Loading profile data',
                      value: 'In progress',
                      child: const SizedBox.square(
                        dimension: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.rose,
                          backgroundColor: AppColors.roseSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This should only take a moment',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A full-page recovery state shown when personalized data cannot be loaded.
class ProfileDataErrorView extends StatelessWidget {
  const ProfileDataErrorView({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.canvas,
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Semantics(
              container: true,
              liveRegion: true,
              child: LoadErrorPanel(
                title: 'Your profile needs another moment',
                message:
                    'We couldn’t load your recent bites and saved guides. '
                    'Your information is still safe—please try again.',
                onRetry: onRetry,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
