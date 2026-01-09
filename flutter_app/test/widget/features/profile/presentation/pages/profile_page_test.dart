import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/profile/domain/entities/user_profile_entity.dart';
import 'package:whats_my_share/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:whats_my_share/features/profile/presentation/pages/profile_page.dart';

// Mock classes
class MockProfileBloc extends Mock implements ProfileBloc {}

class FakeProfileEvent extends Fake implements ProfileEvent {}

class FakeProfileState extends Fake implements ProfileState {}

void main() {
  late MockProfileBloc mockProfileBloc;

  setUpAll(() {
    registerFallbackValue(FakeProfileEvent());
    registerFallbackValue(FakeProfileState());
  });

  setUp(() {
    mockProfileBloc = MockProfileBloc();
    when(
      () => mockProfileBloc.stream,
    ).thenAnswer((_) => Stream<ProfileState>.empty());
  });

  Widget createTestWidget({ProfileState? profileState}) {
    when(
      () => mockProfileBloc.state,
    ).thenReturn(profileState ?? const ProfileState());

    return MaterialApp(
      home: BlocProvider<ProfileBloc>.value(
        value: mockProfileBloc,
        child: const ProfilePage(),
      ),
    );
  }

  UserProfileEntity createTestProfile({
    String id = 'user-1',
    String email = 'test@example.com',
    String? displayName = 'Test User',
    String? phone,
    int totalOwed = 10000,
    int totalOwing = 5000,
    String defaultCurrency = 'INR',
    bool notificationsEnabled = true,
    bool contactSyncEnabled = false,
    bool biometricAuthEnabled = false,
  }) {
    return UserProfileEntity(
      id: id,
      email: email,
      displayName: displayName,
      phone: phone,
      totalOwed: totalOwed,
      totalOwing: totalOwing,
      defaultCurrency: defaultCurrency,
      notificationsEnabled: notificationsEnabled,
      contactSyncEnabled: contactSyncEnabled,
      biometricAuthEnabled: biometricAuthEnabled,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );
  }

  group('ProfilePage Widget Tests', () {
    group('AppBar', () {
      testWidgets('should display title', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Profile'), findsOneWidget);
      });

      testWidgets('should display edit button', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.edit), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('should show loading indicator when loading', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            profileState: const ProfileState(status: ProfileStatus.loading),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Error State', () {
      testWidgets('should show error message when profile is null', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            profileState: const ProfileState(
              status: ProfileStatus.loaded,
              profile: null,
            ),
          ),
        );

        expect(find.text('Failed to load profile'), findsOneWidget);
      });

      testWidgets('should show retry button when profile is null', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(
            profileState: const ProfileState(
              status: ProfileStatus.loaded,
              profile: null,
            ),
          ),
        );

        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should trigger reload when retry is tapped', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            profileState: const ProfileState(
              status: ProfileStatus.loaded,
              profile: null,
            ),
          ),
        );

        await tester.tap(find.text('Retry'));
        await tester.pump();

        verify(
          () => mockProfileBloc.add(const ProfileLoadRequested()),
        ).called(1);
      });
    });

    group('Profile Header', () {
      testWidgets('should display user name', (tester) async {
        final profile = createTestProfile(displayName: 'John Doe');
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('John Doe'), findsOneWidget);
      });

      testWidgets('should display user email', (tester) async {
        final profile = createTestProfile(email: 'john@example.com');
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('john@example.com'), findsOneWidget);
      });

      testWidgets('should display phone when available', (tester) async {
        final profile = createTestProfile(phone: '+1234567890');
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('+1234567890'), findsOneWidget);
      });

      testWidgets('should display avatar', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.byType(CircleAvatar), findsWidgets);
      });
    });

    group('Balance Summary', () {
      testWidgets('should display balance summary title', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Balance Summary'), findsOneWidget);
      });

      testWidgets('should display "You are owed" section', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('You are owed'), findsOneWidget);
      });

      testWidgets('should display "You owe" section', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('You owe'), findsOneWidget);
      });

      testWidgets('should display "Net Balance" section', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Net Balance'), findsOneWidget);
      });
    });

    group('Settings Section', () {
      testWidgets('should display settings title', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('should display push notifications toggle', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Push Notifications'), findsOneWidget);
      });

      testWidgets('should display contact sync toggle', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Contact Sync'), findsOneWidget);
      });

      testWidgets('should display biometric auth toggle', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Biometric Authentication'), findsOneWidget);
      });

      testWidgets('should display default currency option', (tester) async {
        final profile = createTestProfile(defaultCurrency: 'INR');
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Default Currency'), findsOneWidget);
        expect(find.text('INR'), findsOneWidget);
      });
    });

    group('Account Section', () {
      testWidgets('should display account title', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Account'), findsOneWidget);
      });

      testWidgets('should display help & support option', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Help & Support'), findsOneWidget);
      });

      testWidgets('should display privacy policy option', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Privacy Policy'), findsOneWidget);
      });

      testWidgets('should display terms of service option', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Terms of Service'), findsOneWidget);
      });

      testWidgets('should display sign out option', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.text('Sign Out'), findsOneWidget);
      });
    });

    group('Toggle Switches', () {
      testWidgets('should toggle notifications when tapped', (tester) async {
        final profile = createTestProfile(notificationsEnabled: true);
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        await tester.tap(find.byType(SwitchListTile).first);
        await tester.pump();

        verify(
          () => mockProfileBloc.add(
            const ProfileSettingsChanged(notificationsEnabled: false),
          ),
        ).called(1);
      });
    });

    group('Currency Picker', () {
      testWidgets('should display current currency', (tester) async {
        final profile = createTestProfile(defaultCurrency: 'INR');
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        // Currency option should be displayed with current value
        expect(find.text('Default Currency'), findsOneWidget);
        expect(find.text('INR'), findsOneWidget);
      });
    });

    group('Sign Out', () {
      testWidgets('should display sign out option', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        // Sign out button should be visible
        expect(find.text('Sign Out'), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsOneWidget);
      });
    });

    group('RefreshIndicator', () {
      testWidgets('should have RefreshIndicator', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Icons', () {
      testWidgets('should display help icon', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.byIcon(Icons.help_outline), findsOneWidget);
      });

      testWidgets('should display privacy icon', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      });

      testWidgets('should display terms icon', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      });

      testWidgets('should display logout icon', (tester) async {
        final profile = createTestProfile();
        await tester.pumpWidget(
          createTestWidget(
            profileState: ProfileState(
              status: ProfileStatus.loaded,
              profile: profile,
            ),
          ),
        );

        expect(find.byIcon(Icons.logout), findsOneWidget);
      });
    });
  });
}
