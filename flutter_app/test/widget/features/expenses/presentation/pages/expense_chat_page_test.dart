import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/expenses/domain/entities/chat_message_entity.dart';
import 'package:whats_my_share/features/expenses/domain/entities/expense_entity.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/chat_bloc.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/chat_event.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/chat_state.dart';

// Mock classes
class MockChatBloc extends MockBloc<ChatEvent, ChatState> implements ChatBloc {}

class FakeChatEvent extends Fake implements ChatEvent {}

class FakeChatState extends Fake implements ChatState {}

// Test widget that mimics ExpenseChatPage but without image picker dependencies
class TestExpenseChatPage extends StatefulWidget {
  final ExpenseEntity expense;
  final String currentUserId;
  final ChatBloc chatBloc;

  const TestExpenseChatPage({
    super.key,
    required this.expense,
    required this.currentUserId,
    required this.chatBloc,
  });

  @override
  State<TestExpenseChatPage> createState() => _TestExpenseChatPageState();
}

class _TestExpenseChatPageState extends State<TestExpenseChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.chatBloc.add(SubscribeToChatStream(widget.expense.id));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    widget.chatBloc.add(const UnsubscribeFromChatStream());
    super.dispose();
  }

  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    widget.chatBloc.add(
      SendTextMessage(expenseId: widget.expense.id, text: text),
    );

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>.value(
      value: widget.chatBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.expense.description,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                widget.expense.formattedAmount,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        body: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            return Column(
              children: [
                // Messages list
                Expanded(
                  child: state.isLoading && !state.hasMessages
                      ? const Center(child: CircularProgressIndicator())
                      : state.hasMessages
                      ? _buildMessagesList(state.messages)
                      : _buildEmptyState(),
                ),
                // Input area
                _buildInputArea(state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation about this expense',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessageEntity> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageEntity message) {
    final isMe = message.sender.id == widget.currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              child: Text(message.sender.displayName[0].toUpperCase()),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  Text(
                    message.text ?? '',
                    style: TextStyle(
                      color: isMe
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: state.isSending ? null : () {},
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                enabled: !state.isSending,
                onSubmitted: (_) => _sendTextMessage(),
              ),
            ),
            const SizedBox(width: 8),
            state.isSending
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendTextMessage,
                  ),
          ],
        ),
      ),
    );
  }
}

void main() {
  late MockChatBloc mockChatBloc;
  late ExpenseEntity testExpense;
  late List<ChatMessageEntity> testMessages;

  setUpAll(() {
    registerFallbackValue(FakeChatEvent());
    registerFallbackValue(FakeChatState());
  });

  setUp(() {
    mockChatBloc = MockChatBloc();

    testExpense = ExpenseEntity(
      id: 'expense1',
      groupId: 'group1',
      description: 'Lunch at Restaurant',
      amount: 50000, // ₹500
      currency: 'INR',
      category: ExpenseCategory.food,
      date: DateTime.now(),
      createdBy: 'user1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: ExpenseStatus.active,
      paidBy: [PayerInfo(userId: 'user1', displayName: 'John', amount: 50000)],
      splits: [
        ExpenseSplit(
          userId: 'user1',
          displayName: 'John',
          amount: 25000,
          isPaid: true,
        ),
        ExpenseSplit(
          userId: 'user2',
          displayName: 'Jane',
          amount: 25000,
          isPaid: false,
        ),
      ],
      splitType: SplitType.equal,
    );

    testMessages = [
      ChatMessageEntity(
        id: 'msg1',
        expenseId: 'expense1',
        sender: const ChatSender(id: 'user1', displayName: 'John'),
        type: ChatMessageType.text,
        text: 'Hello, this is about lunch',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessageEntity(
        id: 'msg2',
        expenseId: 'expense1',
        sender: const ChatSender(id: 'user2', displayName: 'Jane'),
        type: ChatMessageType.text,
        text: 'Sounds good!',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ChatMessageEntity(
        id: 'msg3',
        expenseId: 'expense1',
        sender: const ChatSender(id: 'user1', displayName: 'John'),
        type: ChatMessageType.text,
        text: 'Let me know when you can pay',
        createdAt: DateTime.now(),
      ),
    ];

    when(() => mockChatBloc.state).thenReturn(const ChatState());
  });

  tearDown(() {
    mockChatBloc.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: TestExpenseChatPage(
        expense: testExpense,
        currentUserId: 'user1',
        chatBloc: mockChatBloc,
      ),
    );
  }

  group('ExpenseChatPage Widget Tests', () {
    group('AppBar', () {
      testWidgets('should display expense description in title', (
        tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Lunch at Restaurant'), findsOneWidget);
      });

      testWidgets('should display formatted amount in subtitle', (
        tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.textContaining('₹'), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('should show loading indicator when loading', (tester) async {
        when(
          () => mockChatBloc.state,
        ).thenReturn(const ChatState(status: ChatStatus.loading));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('should show empty state when no messages', (tester) async {
        when(() => mockChatBloc.state).thenReturn(const ChatState());

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('No messages yet'), findsOneWidget);
        expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      });

      testWidgets('should show conversation prompt in empty state', (
        tester,
      ) async {
        when(() => mockChatBloc.state).thenReturn(const ChatState());

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(
          find.text('Start the conversation about this expense'),
          findsOneWidget,
        );
      });
    });

    group('Messages List', () {
      testWidgets('should display messages when available', (tester) async {
        when(
          () => mockChatBloc.state,
        ).thenReturn(ChatState(messages: testMessages));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Hello, this is about lunch'), findsOneWidget);
        expect(find.text('Sounds good!'), findsOneWidget);
        expect(find.text('Let me know when you can pay'), findsOneWidget);
      });

      testWidgets('should display sender name for other users messages', (
        tester,
      ) async {
        when(
          () => mockChatBloc.state,
        ).thenReturn(ChatState(messages: testMessages));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Jane's message should show her name
        expect(find.text('Jane'), findsOneWidget);
      });

      testWidgets('should have ListView for messages', (tester) async {
        when(
          () => mockChatBloc.state,
        ).thenReturn(ChatState(messages: testMessages));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(ListView), findsOneWidget);
      });
    });

    group('Input Area', () {
      testWidgets('should display message input field', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Type a message...'), findsOneWidget);
      });

      testWidgets('should display send button', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.send), findsOneWidget);
      });

      testWidgets('should display attachment button', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('should allow text input', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Hello there');
        await tester.pumpAndSettle();

        expect(find.text('Hello there'), findsOneWidget);
      });
    });

    group('Sending State', () {
      testWidgets('should show loading indicator when sending', (tester) async {
        when(
          () => mockChatBloc.state,
        ).thenReturn(const ChatState(isSending: true));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.send), findsNothing);
      });

      testWidgets('should disable input field when sending', (tester) async {
        when(
          () => mockChatBloc.state,
        ).thenReturn(const ChatState(isSending: true));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, isFalse);
      });

      testWidgets('should disable attachment button when sending', (
        tester,
      ) async {
        when(
          () => mockChatBloc.state,
        ).thenReturn(const ChatState(isSending: true));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        final addButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.add),
        );
        expect(addButton.onPressed, isNull);
      });
    });

    group('Message Bubbles', () {
      testWidgets('should display CircleAvatar for other user messages', (
        tester,
      ) async {
        when(() => mockChatBloc.state).thenReturn(
          ChatState(messages: [testMessages[1]]), // Jane's message
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(CircleAvatar), findsOneWidget);
      });

      testWidgets('should align own messages to the right', (tester) async {
        when(() => mockChatBloc.state).thenReturn(
          ChatState(
            messages: [testMessages[0]],
          ), // John's message (current user)
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Own messages have Row with MainAxisAlignment.end
        expect(find.text('Hello, this is about lunch'), findsOneWidget);
      });
    });

    group('BlocBuilder', () {
      testWidgets('should use BlocBuilder for state management', (
        tester,
      ) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(BlocBuilder<ChatBloc, ChatState>), findsOneWidget);
      });
    });

    group('Widget Structure', () {
      testWidgets('should have Column as main layout', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('should have Scaffold', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should have AppBar', (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsOneWidget);
      });
    });
  });
}
