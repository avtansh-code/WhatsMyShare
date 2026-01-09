import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/groups/domain/entities/group_entity.dart'
    hide SimplifiedDebt;
import 'package:whats_my_share/features/settlements/domain/entities/settlement_entity.dart';
import 'package:whats_my_share/features/settlements/presentation/bloc/settlement_bloc.dart';
import 'package:whats_my_share/features/settlements/presentation/bloc/settlement_event.dart';
import 'package:whats_my_share/features/settlements/presentation/bloc/settlement_state.dart';
import 'package:whats_my_share/features/settlements/presentation/pages/settle_up_page.dart';

// Mock classes
class MockSettlementBloc extends MockBloc<SettlementEvent, SettlementState>
    implements SettlementBloc {}

class FakeSettlementEvent extends Fake implements SettlementEvent {}

class FakeSettlementState extends Fake implements SettlementState {}

void main() {
  late MockSettlementBloc mockSettlementBloc;

  setUpAll(() {
    registerFallbackValue(FakeSettlementEvent());
    registerFallbackValue(FakeSettlementState());
  });

  setUp(() {
    mockSettlementBloc = MockSettlementBloc();
    when(() => mockSettlementBloc.state).thenReturn(SettlementInitial());
  });

  tearDown(() {
    mockSettlementBloc.close();
  });

  // Create test group
  final testMembers = [
    GroupMember(
      userId: 'user1',
      email: 'user1@example.com',
      displayName: 'User One',
      role: MemberRole.admin,
      joinedAt: DateTime(2025, 1, 1),
    ),
    GroupMember(
      userId: 'user2',
      email: 'user2@example.com',
      displayName: 'User Two',
      role: MemberRole.member,
      joinedAt: DateTime(2025, 1, 1),
    ),
    GroupMember(
      userId: 'user3',
      email: 'user3@example.com',
      displayName: 'User Three',
      role: MemberRole.member,
      joinedAt: DateTime(2025, 1, 1),
    ),
  ];

  final testGroup = GroupEntity(
    id: 'group1',
    name: 'Test Group',
    description: 'Test description',
    type: GroupType.other,
    currency: 'INR',
    createdBy: 'user1',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    members: testMembers,
    memberIds: const ['user1', 'user2', 'user3'],
    admins: const ['user1'],
    balances: const {'user1': 50000, 'user2': -30000, 'user3': -20000},
    simplifiedDebts: const [],
    simplifyDebts: true,
    memberCount: 3,
    expenseCount: 0,
    totalExpenses: 0,
  );

  Widget createWidgetUnderTest({SimplifiedDebt? suggestedDebt}) {
    return MaterialApp(
      home: BlocProvider<SettlementBloc>.value(
        value: mockSettlementBloc,
        child: SettleUpPage(
          group: testGroup,
          currentUserId: 'user2',
          currentUserName: 'User Two',
          suggestedDebt: suggestedDebt,
        ),
      ),
    );
  }

  group('SettleUpPage Widget Tests', () {
    group('AppBar', () {
      testWidgets('should display Settle Up title', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Settle Up'), findsOneWidget);
      });
    });

    group('Participant Selection', () {
      testWidgets('should display Who is paying? label', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Who is paying?'), findsOneWidget);
      });

      testWidgets('should display Who is receiving? label', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Who is receiving?'), findsOneWidget);
      });

      testWidgets('should display Select Member buttons when no selection', (
        tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Select Member'), findsNWidgets(2));
      });

      testWidgets('should display arrow indicator between participants', (
        tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      });

      testWidgets('should pre-fill payer when suggested debt provided', (
        tester,
      ) async {
        final suggestedDebt = SimplifiedDebt(
          fromUserId: 'user2',
          fromUserName: 'User Two',
          toUserId: 'user1',
          toUserName: 'User One',
          amount: 30000,
        );

        await tester.pumpWidget(
          createWidgetUnderTest(suggestedDebt: suggestedDebt),
        );
        await tester.pumpAndSettle();

        expect(find.text('User Two'), findsWidgets);
        expect(find.text('User One'), findsWidgets);
      });
    });

    group('Amount Input', () {
      testWidgets('should display Amount field', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Amount'), findsOneWidget);
      });

      testWidgets('should display currency prefix', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('₹ '), findsOneWidget);
      });

      testWidgets('should pre-fill amount when suggested debt provided', (
        tester,
      ) async {
        final suggestedDebt = SimplifiedDebt(
          fromUserId: 'user2',
          fromUserName: 'User Two',
          toUserId: 'user1',
          toUserName: 'User One',
          amount: 30000,
        );

        await tester.pumpWidget(
          createWidgetUnderTest(suggestedDebt: suggestedDebt),
        );
        await tester.pumpAndSettle();

        // Amount should be 300.00 (30000 paisa)
        expect(find.text('300.00'), findsOneWidget);
      });
    });

    group('Payment Method Selection', () {
      testWidgets('should display Payment Method label', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Payment Method'), findsOneWidget);
      });

      testWidgets('should display payment method chips', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(ChoiceChip), findsNWidgets(4)); // 4 payment methods
      });

      testWidgets('should display UPI option', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('UPI'), findsOneWidget);
      });

      testWidgets('should display Cash option', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Cash'), findsOneWidget);
      });

      testWidgets('should display Bank Transfer option', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Bank Transfer'), findsOneWidget);
      });
    });

    group('Notes Input', () {
      testWidgets('should display Notes field', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Scroll down to find Notes field
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('Notes (optional)'), findsOneWidget);
      });
    });

    group('Submit Button', () {
      testWidgets('should display Record Payment button', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Scroll down to find Submit button
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text('Record Payment'), findsOneWidget);
      });

      testWidgets('should have ElevatedButton for submit', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Scroll down to find Submit button
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should show loading indicator when operation in progress', (
        tester,
      ) async {
        when(
          () => mockSettlementBloc.state,
        ).thenReturn(const SettlementOperationInProgress('creating'));

        await tester.pumpWidget(createWidgetUnderTest());
        // Use pump instead of pumpAndSettle for loading state
        await tester.pump();

        // Scroll down to find Submit button area
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Form Structure', () {
      testWidgets('should have Form widget', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(Form), findsOneWidget);
      });

      testWidgets('should have ListView for scrolling', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('should have Cards for participant selection', (
        tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(Card), findsNWidgets(2)); // Payer and receiver cards
      });
    });

    group('Validation', () {
      testWidgets('should validate empty amount on submit', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Scroll down to find Submit button
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        // Tap submit button without entering amount
        await tester.tap(find.text('Record Payment'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter an amount'), findsOneWidget);
      });

      testWidgets('should validate invalid amount', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Enter invalid amount
        final amountField = find.widgetWithText(TextFormField, 'Amount');
        await tester.enterText(amountField, '-100');
        await tester.pumpAndSettle();

        // Scroll down to find Submit button
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        // Tap submit button
        await tester.tap(find.text('Record Payment'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a valid amount'), findsOneWidget);
      });
    });

    group('Text Fields', () {
      testWidgets('should have TextFormField for amount', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(TextFormField), findsWidgets);
      });

      testWidgets('should accept input in amount field', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        final amountField = find.widgetWithText(TextFormField, 'Amount');
        await tester.enterText(amountField, '500.00');
        await tester.pumpAndSettle();

        expect(find.text('500.00'), findsOneWidget);
      });
    });

    group('Member Selection Bottom Sheet', () {
      testWidgets('should open bottom sheet when Select Member tapped', (
        tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Tap first Select Member button
        await tester.tap(find.text('Select Member').first);
        await tester.pumpAndSettle();

        // Bottom sheet should show members
        expect(find.byType(ListTile), findsWidgets);
      });
    });

    group('UPI Reference Field', () {
      testWidgets('should show UPI Transaction ID field when UPI selected', (
        tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // UPI is default selected
        expect(find.text('UPI Transaction ID (optional)'), findsOneWidget);
      });
    });

    // Biometric Warning tests skipped - feature is a future enhancement
    // group('Biometric Warning', () {
    //   testWidgets('should show biometric warning for large amounts', ...);
    // });
  });
}
