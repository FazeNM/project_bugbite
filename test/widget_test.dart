import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_bugbite/app/app.dart';
import 'package:project_bugbite/data/models/community_post.dart';
import 'package:project_bugbite/data/models/bite_guide.dart';
import 'package:project_bugbite/features/explore/widgets/bite_photo_card.dart';
import 'package:project_bugbite/features/explore/widgets/guide_image.dart';
import 'package:project_bugbite/data/services/auth_service.dart';
import 'package:project_bugbite/data/services/app_persistence_service.dart';
import 'package:project_bugbite/data/services/profile_data_service.dart';
import 'package:project_bugbite/state/auth_controller.dart';
import 'package:project_bugbite/state/community_providers.dart';
import 'package:project_bugbite/state/profile_data_controller.dart';
import 'package:project_bugbite/state/persistence_providers.dart';

import 'support/memory_user_data_store.dart';
import 'support/memory_community_repository.dart';

void main() {
  testWidgets('BiteWise opens on the sign-in experience', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('BiteWise'), findsOneWidget);
    expect(find.text('Welcome back'.toUpperCase()), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('empty sign-in fields show readable validation errors', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter at least 6 characters.'), findsOneWidget);
  });

  testWidgets('signing in reaches visual guides and guide detail', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await _signIn(tester);

    expect(find.text('Common bite guides'), findsOneWidget);
    await tester.tap(find.text('Mosquito').first);
    await tester.pumpAndSettle();

    expect(find.text('Gentle next steps'), findsOneWidget);
  });

  testWidgets('symptom filters open possible visual matches', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await _signIn(tester);
    await tester.tap(find.text('Find'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Itchy'));
    await tester.pumpAndSettle();

    expect(find.text('What do you notice?'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.textContaining('possible guides'), findsOneWidget);
  });

  testWidgets('expanded fly guides are available in Explore', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await _signIn(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Explore'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flies'));
    await tester.pumpAndSettle();

    expect(find.text('Biting flies'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Biting midge or no-see-um'),
      450,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Biting midge or no-see-um'), findsOneWidget);
  });

  testWidgets(
    'Explore shows skin photos and opens the selected gallery image',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpApp(tester);
      await _signIn(tester);
      await _tapNavigationDestination(tester, 'Explore');
      await tester.scrollUntilVisible(
        find.byType(BitePhotoCard).first,
        220,
        scrollable: find.byType(Scrollable).last,
      );
      final card = tester.widget<BitePhotoCard>(
        find.byType(BitePhotoCard).first,
      );
      expect(card.media.kind, GuideMediaKind.skin);
      expect(card.media.asset, startsWith('assets/images/bites/'));
      for (final rendered in tester.widgetList<BitePhotoCard>(
        find.byType(BitePhotoCard),
      )) {
        expect(rendered.media.kind, GuideMediaKind.skin);
      }
      await tester.tap(find.byType(BitePhotoCard).first);
      await tester.pumpAndSettle();
      final page = tester.widget<PageView>(find.byType(PageView));
      expect(page.controller!.page, card.guide.gallery.indexOf(card.media));
      expect(
        tester.widget<GuideImage>(find.byType(GuideImage).first).media.asset,
        card.media.asset,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile opens the dedicated settings screen', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await _signIn(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Saved visual guides'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Open settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Privacy and photos'), findsOneWidget);
    expect(find.text('Photo uploads · Coming soon'), findsOneWidget);
    expect(
      find.text(
        'Reference photos remain available. You can still share text experiences.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('user can create and view a community experience', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _signIn(tester);
    await _tapNavigationDestination(tester, 'Community');

    await tester.tap(find.text('Add your experience'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'A unique experience that should stay visible after it is saved.',
    );
    await _revealFormField(tester, find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await _revealFormField(tester, find.text('Share carefully'));
    await tester.tap(find.text('Share carefully'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A unique experience that should stay visible after it is saved.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('empty experience and missing acknowledgement are rejected', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _signIn(tester);
    await _tapNavigationDestination(tester, 'Community');
    await tester.tap(find.text('Add your experience'));
    await tester.pumpAndSettle();

    await _revealFormField(tester, find.text('Share carefully'));
    await tester.tap(find.text('Share carefully'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.text('Enter between 12 and 4,000 characters.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField),
      'Enough detail to pass form validation.',
    );
    await _revealFormField(tester, find.text('Share carefully'));
    await tester.tap(find.text('Share carefully'));
    await tester.pumpAndSettle();
    expect(
      find.text('Please acknowledge the safety note before sharing.'),
      findsOneWidget,
    );
  });

  testWidgets('comments validate, save, and appear on the post', (
    WidgetTester tester,
  ) async {
    final store = MemoryUserDataStore();
    final community = MemoryCommunityRepository(
      posts: [
        CommunityPost(
          id: 'shared-post',
          authorId: 'another-user',
          author: 'Another member',
          location: 'Your area',
          createdAt: DateTime(2026, 9, 1),
          possibleMatch: 'Possible mosquito',
          body: 'An experience shared by another member.',
          guideId: 'mosquito',
          tags: const ['itchy'],
        ),
      ],
    );
    await _pumpApp(tester, userDataStore: store, community: community);
    await _signIn(tester);
    await _tapNavigationDestination(tester, 'Community');

    await tester.scrollUntilVisible(
      find.text('Comment').first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comment').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a comment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Post comment'));
    await tester.pumpAndSettle();
    expect(
      find.text('Write a reply between 2 and 2,000 characters.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextFormField).last,
      'A kind and useful reply.',
    );
    await tester.tap(find.text('Post comment'));
    await tester.pumpAndSettle();

    expect(find.text('Add a supportive comment'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('A kind and useful reply.'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('A kind and useful reply.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Comments (1)'), findsOneWidget);

    expect(
      community.comments.values
          .expand((comments) => comments)
          .map((comment) => comment.body),
      contains('A kind and useful reply.'),
    );
    final persisted = await AppPersistenceService(store).load('test-user');
    expect(
      persisted?.posts.expand((post) => post.comments),
      isNot(
        contains(
          isA<CommunityComment>().having(
            (c) => c.body,
            'body',
            'A kind and useful reply.',
          ),
        ),
      ),
    );
  });

  testWidgets('personalized bite data shows a spinner while loading', (
    WidgetTester tester,
  ) async {
    await _pumpApp(
      tester,
      profileService: ProfileDataService(
        loadDelay: const Duration(seconds: 1),
        operationDelay: Duration.zero,
      ),
    );

    await _signIn(tester, settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Gathering your bite guides'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('Common bite guides'), findsOneWidget);
    expect(find.text('Continue looking'), findsNothing);
  });

  testWidgets('a new account profile shows no fabricated activity or saves', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    await _signIn(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Saved visual guides'), findsOneWidget);
    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('No recent guides'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No recent guides'), findsOneWidget);
    expect(
      find.text(
        'Open a visual guide and it will appear here for quick access.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continue looking'), findsNothing);
    expect(find.text('Recently viewed'), findsNothing);
    expect(find.text('Similar to what you viewed'), findsNothing);
  });

  testWidgets('personalized bite data shows a retryable error', (
    WidgetTester tester,
  ) async {
    await _pumpApp(
      tester,
      profileService: ProfileDataService(
        loadDelay: Duration.zero,
        operationDelay: Duration.zero,
        failRequests: true,
      ),
    );

    await _signIn(tester);

    expect(find.text('Your profile needs another moment'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Try again'), findsOneWidget);
  });

  testWidgets('a Firebase authentication error remains on sign in', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService(
      signInError: const AuthServiceException(
        'Please verify your email before signing in.',
        code: 'email-not-verified',
      ),
    );
    await _pumpApp(tester, authService: authService);

    await _signIn(tester);

    expect(
      find.text('Please verify your email before signing in.'),
      findsOneWidget,
    );
    expect(find.text('Welcome back'.toUpperCase()), findsOneWidget);
    expect(authService.lastEmail, 'tester@example.com');
    expect(authService.lastPassword, 'secure-password');
  });

  testWidgets('offline authentication failure is readable', (
    WidgetTester tester,
  ) async {
    await _pumpApp(
      tester,
      authService: FakeAuthService(
        signInError: const AuthServiceException(
          'Check your internet connection and try again.',
          code: 'network-request-failed',
        ),
      ),
    );

    await _signIn(tester);

    expect(
      find.text('Check your internet connection and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('unverified account can request a new verification email', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService(
      signInError: const AuthServiceException(
        'Please verify your email before signing in.',
        code: 'email-not-verified',
      ),
    );
    await _pumpApp(tester, authService: authService);

    await _signIn(tester);
    await tester.tap(find.text('Resend verification email'));
    await tester.pumpAndSettle();

    expect(authService.lastVerificationEmail, 'tester@example.com');
    expect(
      find.text(
        'A new verification email was sent. Check spam or junk folders too.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('old device notes stay private after a restored session', (
    WidgetTester tester,
  ) async {
    final store = MemoryUserDataStore();
    await AppPersistenceService(store).save(
      'restored-user',
      PersistedAppData(
        posts: <CommunityPost>[
          CommunityPost(
            id: 'restored-post',
            authorId: 'restored-user',
            author: 'Restored User',
            location: 'Your area',
            createdAt: DateTime(2026, 8, 30),
            possibleMatch: 'Possible mosquito',
            body: 'Restored after a simulated cold start.',
            guideId: 'mosquito',
            tags: const <String>['Itchy'],
          ),
        ],
        savedGuideIds: const <String>{'mosquito'},
        gentleReminders: true,
        stripPhotoMetadata: true,
      ),
    );
    const restoredUser = AuthUser(
      id: 'restored-user',
      email: 'restored@example.com',
      displayName: 'Restored User',
      photoUrl: null,
      isEmailVerified: true,
    );
    await _pumpApp(
      tester,
      authService: FakeAuthService(initialUser: restoredUser),
      userDataStore: store,
    );

    expect(find.text('Common bite guides'), findsOneWidget);
    await _tapNavigationDestination(tester, 'Community');
    expect(find.text('Restored after a simulated cold start.'), findsNothing);
    await _tapNavigationDestination(tester, 'Profile');
    await tester.scrollUntilVisible(
      find.text('Private notes on this device'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('Restored after a simulated cold start.'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Restored after a simulated cold start.'), findsOneWidget);
    expect(find.text('Review & publish'), findsOneWidget);
  });

  testWidgets('user can sign out and return to sign in', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);
    await _signIn(tester);
    await _tapNavigationDestination(tester, 'Profile');
    await tester.scrollUntilVisible(
      find.text('Sign out'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Welcome back'.toUpperCase()), findsOneWidget);
  });

  testWidgets('forgot password uses the entered email and shows confirmation', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService();
    await _pumpApp(tester, authService: authService);

    await tester.enterText(
      find.byType(TextFormField).first,
      'reset@example.com',
    );
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(authService.lastPasswordResetEmail, 'reset@example.com');
    expect(
      find.text('Password reset email sent. Check your inbox.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  ProfileDataService? profileService,
  FakeAuthService? authService,
  MemoryUserDataStore? userDataStore,
  MemoryCommunityRepository? community,
}) async {
  final fakeAuthService = authService ?? FakeAuthService();
  final memoryStore = userDataStore ?? MemoryUserDataStore();
  final sharedCommunity = community ?? MemoryCommunityRepository();
  addTearDown(sharedCommunity.dispose);
  addTearDown(fakeAuthService.dispose);
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(fakeAuthService),
        userDataStoreProvider.overrideWithValue(memoryStore),
        communityRepositoryProvider.overrideWithValue(sharedCommunity),
        if (profileService != null)
          profileDataServiceProvider.overrideWithValue(profileService),
      ],
      child: const BiteWiseApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester, {bool settle = true}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'tester@example.com');
  await tester.enterText(fields.at(1), 'secure-password');
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _revealFormField(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapNavigationDestination(
  WidgetTester tester,
  String label,
) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

class FakeAuthService implements AuthService {
  FakeAuthService({this.signInError, AuthUser? initialUser})
    : _currentUser = initialUser;

  final AuthServiceException? signInError;
  final StreamController<AuthUser?> _authState =
      StreamController<AuthUser?>.broadcast(sync: true);

  AuthUser? _currentUser;
  String? lastEmail;
  String? lastPassword;
  String? lastPasswordResetEmail;
  String? lastVerificationEmail;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _authState.stream;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    if (signInError case final error?) throw error;

    _currentUser = const AuthUser(
      id: 'test-user',
      email: 'tester@example.com',
      displayName: 'Test User',
      photoUrl: null,
      isEmailVerified: true,
    );
    _authState.add(_currentUser);
  }

  @override
  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> sendPasswordReset(String email) async {
    lastPasswordResetEmail = email;
  }

  @override
  Future<void> resendEmailVerification({
    required String email,
    required String password,
  }) async {
    lastVerificationEmail = email;
    lastPassword = password;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authState.add(null);
  }

  Future<void> dispose() => _authState.close();
}
