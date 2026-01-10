import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_bloc.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_event.dart';
import 'package:whats_my_share/features/groups/presentation/bloc/group_state.dart';
import 'package:whats_my_share/features/groups/presentation/pages/create_group_page.dart';

// Mock classes
class MockGroupBloc extends Mock implements GroupBloc {}

class FakeGroupEvent extends Fake implements GroupEvent {}

class FakeGroupState extends Fake implements GroupState {}

void main() {
  late MockGroupBloc mockGroupBloc;

  setUpAll(() {
    registerFallbackValue(FakeGroupEvent());
    registerFallbackValue(FakeGroupState());
  });

  setUp(() {
    mockGroupBloc = MockGroupBloc();
    when(
      () => mockGroupBloc.stream,
    ).thenAnswer((_) => Stream<GroupState>.empty());
  });

  Widget createTestWidget({GroupState? groupState}) {
    when(
      () => mockGroupBloc.state,
    ).thenReturn(groupState ?? const GroupState());

    return MaterialApp(
      home: BlocProvider<GroupBloc>.value(
        value: mockGroupBloc,
        child: const CreateGroupPage(),
      ),
    );
  }

  group('CreateGroupPage Widget Tests', () {
    group('AppBar', () {
      testWidgets('should display Create Group title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Create Group'), findsWidgets);
      });
    });

    group('Form Fields', () {
      testWidgets('should display Group Name field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Group Name *'), findsOneWidget);
      });

      testWidgets('should display Description field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Description (optional)'), findsOneWidget);
      });

      testWidgets('should display Group Type section', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Group Type'), findsOneWidget);
      });

      testWidgets('should display Currency section', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Currency'), findsOneWidget);
      });

      testWidgets('should display Simplify Debts toggle', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Simplify Debts'), findsOneWidget);
      });
    });

    group('Group Type Selection', () {
      testWidgets('should display Trip type chip', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Trip'), findsOneWidget);
        expect(find.text('✈️'), findsOneWidget);
      });

      testWidgets('should display Home type chip', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('🏠'), findsOneWidget);
      });

      testWidgets('should display Couple type chip', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Couple'), findsOneWidget);
        expect(find.text('💑'), findsOneWidget);
      });

      testWidgets('should display Other type chip', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Other'), findsOneWidget);
        expect(find.text('👥'), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('should show error for empty group name', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Scroll down to make button visible then tap
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Tap the FilledButton directly
        final createButton = find.byType(FilledButton);
        expect(createButton, findsOneWidget);
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        expect(find.text('Please enter a group name'), findsOneWidget);
      });

      testWidgets('should show error for short group name', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Enter a short name
        await tester.enterText(find.byType(TextFormField).first, 'A');

        // Scroll down to make button visible
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Tap the FilledButton
        final createButton = find.byType(FilledButton);
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        expect(find.text('Name must be at least 2 characters'), findsOneWidget);
      });

      testWidgets('should accept valid group name', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Enter a valid name
        await tester.enterText(find.byType(TextFormField).first, 'Test Group');

        // Scroll down to make button visible
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Tap the FilledButton
        final createButton = find.byType(FilledButton);
        await tester.tap(createButton);
        await tester.pumpAndSettle();

        expect(find.text('Please enter a group name'), findsNothing);
        expect(find.text('Name must be at least 2 characters'), findsNothing);
      });
    });

    group('Create Button', () {
      testWidgets('should display Create Group button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Create Group'), findsWidgets);
      });

      testWidgets('should show loading indicator when creating', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestWidget(groupState: const GroupState(isCreating: true)),
        );
        await tester.pump();

        // Scroll down to make button visible - use pump instead of pumpAndSettle
        // because CircularProgressIndicator animates forever
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Simplify Debts Toggle', () {
      testWidgets('should display toggle with subtitle', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(
          find.text('Automatically minimize the number of payments needed'),
          findsOneWidget,
        );
      });

      testWidgets('should have switch widget', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(SwitchListTile), findsOneWidget);
      });
    });

    group('Info Text', () {
      testWidgets('should display info about adding members', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Scroll down to make the info text visible
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(
          find.text('You can add members after creating the group'),
          findsOneWidget,
        );
      });
    });

    group('Icons', () {
      testWidgets('should display group icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.group), findsOneWidget);
      });

      testWidgets('should display description icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      });

      testWidgets('should display currency icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.currency_rupee), findsOneWidget);
      });
    });

    group('Hint Text', () {
      testWidgets('should display name hint text', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('e.g., Trip to Goa'), findsOneWidget);
      });

      testWidgets('should display description hint text', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('What is this group for?'), findsOneWidget);
      });
    });
  });
}
