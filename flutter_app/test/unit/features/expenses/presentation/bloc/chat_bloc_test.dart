import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:whats_my_share/features/expenses/data/datasources/expense_chat_datasource.dart';
import 'package:whats_my_share/features/expenses/domain/entities/chat_message_entity.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/chat_bloc.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/chat_event.dart';
import 'package:whats_my_share/features/expenses/presentation/bloc/chat_state.dart';
import 'package:whats_my_share/features/auth/domain/repositories/auth_repository.dart';
import 'package:whats_my_share/features/auth/domain/entities/user_entity.dart';

// Mock classes
class MockExpenseChatDataSource extends Mock implements ExpenseChatDataSource {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockExpenseChatDataSource mockChatDataSource;
  late MockAuthRepository mockAuthRepository;
  late ChatBloc chatBloc;

  final testDate = DateTime(2024, 1, 15, 10, 30);
  final testSender = ChatSender(id: 'user-1', displayName: 'John');

  final testMessages = [
    ChatMessageEntity(
      id: 'msg-1',
      expenseId: 'expense-123',
      type: ChatMessageType.text,
      sender: testSender,
      text: 'This expense was for dinner',
      createdAt: testDate,
    ),
    ChatMessageEntity(
      id: 'msg-2',
      expenseId: 'expense-123',
      type: ChatMessageType.text,
      sender: ChatSender(id: 'user-2', displayName: 'Jane'),
      text: 'Thanks for splitting!',
      createdAt: testDate.add(const Duration(minutes: 5)),
    ),
  ];

  final testUser = UserEntity(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'John',
    createdAt: testDate,
  );

  setUpAll(() {
    registerFallbackValue(ChatSender(id: '', displayName: ''));
  });

  setUp(() {
    mockChatDataSource = MockExpenseChatDataSource();
    mockAuthRepository = MockAuthRepository();
    chatBloc = ChatBloc(
      chatDataSource: mockChatDataSource,
      authRepository: mockAuthRepository,
    );
  });

  tearDown(() {
    chatBloc.close();
  });

  group('ChatBloc', () {
    test('initial state is correct', () {
      expect(chatBloc.state.status, ChatStatus.initial);
      expect(chatBloc.state.messages, isEmpty);
      expect(chatBloc.state.isLoading, isFalse);
      expect(chatBloc.state.error, isNull);
      expect(chatBloc.state.isSending, isFalse);
    });

    group('LoadChatMessages', () {
      blocTest<ChatBloc, ChatState>(
        'emits [loading, loaded] when loading succeeds',
        build: () {
          when(
            () => mockChatDataSource.getMessages(expenseId: 'expense-123'),
          ).thenAnswer((_) async => testMessages);
          return chatBloc;
        },
        act: (bloc) => bloc.add(const LoadChatMessages('expense-123')),
        expect: () => [
          isA<ChatState>()
              .having((s) => s.status, 'status', ChatStatus.loading)
              .having((s) => s.expenseId, 'expenseId', 'expense-123'),
          isA<ChatState>()
              .having((s) => s.status, 'status', ChatStatus.loaded)
              .having((s) => s.messages.length, 'messages', 2),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits [loading, error] when loading fails',
        build: () {
          when(
            () => mockChatDataSource.getMessages(expenseId: 'expense-123'),
          ).thenThrow(Exception('Failed'));
          return chatBloc;
        },
        act: (bloc) => bloc.add(const LoadChatMessages('expense-123')),
        expect: () => [
          isA<ChatState>().having(
            (s) => s.status,
            'status',
            ChatStatus.loading,
          ),
          isA<ChatState>()
              .having((s) => s.status, 'status', ChatStatus.error)
              .having((s) => s.error, 'error', isNotNull),
        ],
      );
    });

    group('SendTextMessage', () {
      blocTest<ChatBloc, ChatState>(
        'emits [sending, sent] when sending succeeds',
        build: () {
          when(
            () => mockAuthRepository.getCurrentUser(),
          ).thenAnswer((_) async => testUser);
          when(
            () => mockChatDataSource.sendTextMessage(
              expenseId: any(named: 'expenseId'),
              sender: any(named: 'sender'),
              text: any(named: 'text'),
            ),
          ).thenAnswer(
            (_) async => ChatMessageEntity(
              id: 'msg-new',
              expenseId: 'expense-123',
              type: ChatMessageType.text,
              sender: testSender,
              text: 'Hello!',
              createdAt: testDate,
            ),
          );
          return chatBloc;
        },
        act: (bloc) => bloc.add(
          const SendTextMessage(expenseId: 'expense-123', text: 'Hello!'),
        ),
        expect: () => [
          isA<ChatState>().having((s) => s.isSending, 'isSending', true),
          isA<ChatState>().having((s) => s.isSending, 'isSending', false),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits [sending, error] when user not authenticated',
        build: () {
          when(
            () => mockAuthRepository.getCurrentUser(),
          ).thenAnswer((_) async => null);
          return chatBloc;
        },
        act: (bloc) => bloc.add(
          const SendTextMessage(expenseId: 'expense-123', text: 'Hello!'),
        ),
        expect: () => [
          isA<ChatState>().having((s) => s.isSending, 'isSending', true),
          isA<ChatState>()
              .having((s) => s.isSending, 'isSending', false)
              .having((s) => s.status, 'status', ChatStatus.error),
        ],
      );
    });

    group('ChatMessagesUpdated', () {
      blocTest<ChatBloc, ChatState>(
        'updates messages from stream',
        build: () => chatBloc,
        act: (bloc) => bloc.add(ChatMessagesUpdated(testMessages)),
        expect: () => [
          isA<ChatState>()
              .having((s) => s.status, 'status', ChatStatus.loaded)
              .having((s) => s.messages.length, 'count', 2),
        ],
      );
    });

    group('VoiceRecording', () {
      blocTest<ChatBloc, ChatState>(
        'emits recording status when starting',
        build: () => chatBloc,
        act: (bloc) => bloc.add(const StartVoiceRecording()),
        expect: () => [
          isA<ChatState>().having(
            (s) => s.voiceRecordingStatus,
            'voiceRecordingStatus',
            VoiceRecordingStatus.recording,
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits stopped status when stopping',
        seed: () => const ChatState(
          voiceRecordingStatus: VoiceRecordingStatus.recording,
        ),
        build: () => chatBloc,
        act: (bloc) => bloc.add(const StopVoiceRecording()),
        expect: () => [
          isA<ChatState>().having(
            (s) => s.voiceRecordingStatus,
            'voiceRecordingStatus',
            VoiceRecordingStatus.stopped,
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'emits idle status when canceling',
        seed: () => const ChatState(
          voiceRecordingStatus: VoiceRecordingStatus.recording,
        ),
        build: () => chatBloc,
        act: (bloc) => bloc.add(const CancelVoiceRecording()),
        expect: () => [
          isA<ChatState>().having(
            (s) => s.voiceRecordingStatus,
            'voiceRecordingStatus',
            VoiceRecordingStatus.idle,
          ),
        ],
      );

      blocTest<ChatBloc, ChatState>(
        'updates recording duration',
        seed: () => const ChatState(
          voiceRecordingStatus: VoiceRecordingStatus.recording,
        ),
        build: () => chatBloc,
        act: (bloc) => bloc.add(const VoiceRecordingProgressUpdated(5000)),
        expect: () => [
          isA<ChatState>().having(
            (s) => s.voiceRecordingDurationMs,
            'voiceRecordingDurationMs',
            5000,
          ),
        ],
      );
    });

    group('ClearChatError', () {
      blocTest<ChatBloc, ChatState>(
        'clears error message',
        seed: () => const ChatState(status: ChatStatus.error, error: 'Error'),
        build: () => chatBloc,
        act: (bloc) => bloc.add(const ClearChatError()),
        expect: () => [
          isA<ChatState>()
              .having((s) => s.status, 'status', ChatStatus.loaded)
              .having((s) => s.error, 'error', isNull),
        ],
      );
    });
  });

  group('ChatState', () {
    test('initial state has correct defaults', () {
      const state = ChatState();
      expect(state.status, ChatStatus.initial);
      expect(state.messages, isEmpty);
      expect(state.isSending, isFalse);
      expect(state.error, isNull);
      expect(state.voiceRecordingStatus, VoiceRecordingStatus.idle);
      expect(state.voiceRecordingDurationMs, 0);
    });

    test('isLoading returns true for loading status', () {
      const state = ChatState(status: ChatStatus.loading);
      expect(state.isLoading, isTrue);
    });

    test('isLoaded returns true for loaded status', () {
      const state = ChatState(status: ChatStatus.loaded);
      expect(state.isLoaded, isTrue);
    });

    test('hasError returns true for error status', () {
      const state = ChatState(status: ChatStatus.error);
      expect(state.hasError, isTrue);
    });

    test('isRecording returns true when recording', () {
      const state = ChatState(
        voiceRecordingStatus: VoiceRecordingStatus.recording,
      );
      expect(state.isRecording, isTrue);
    });

    test('hasRecording returns true when stopped', () {
      const state = ChatState(
        voiceRecordingStatus: VoiceRecordingStatus.stopped,
      );
      expect(state.hasRecording, isTrue);
    });

    test('hasMessages returns true when messages exist', () {
      final state = ChatState(messages: testMessages);
      expect(state.hasMessages, isTrue);
    });

    test('hasMessages returns false when messages are empty', () {
      const state = ChatState(messages: []);
      expect(state.hasMessages, isFalse);
    });

    test('messageCount returns correct count', () {
      final state = ChatState(messages: testMessages);
      expect(state.messageCount, 2);
    });

    test('formattedRecordingDuration formats correctly', () {
      const state = ChatState(voiceRecordingDurationMs: 65000);
      expect(state.formattedRecordingDuration, '1:05');
    });

    test('copyWith creates copy with new values', () {
      const state = ChatState();
      final newState = state.copyWith(status: ChatStatus.loading);
      expect(newState.status, ChatStatus.loading);
    });

    test('props contain all state fields', () {
      final state = ChatState(
        status: ChatStatus.loaded,
        messages: testMessages,
        error: 'Error',
        isSending: true,
      );
      expect(state.props.length, 8);
    });
  });

  group('ChatEvent', () {
    test('LoadChatMessages props contain expenseId', () {
      const event = LoadChatMessages('expense-123');
      expect(event.props, contains('expense-123'));
    });

    test('SendTextMessage props contain expenseId and text', () {
      const event = SendTextMessage(expenseId: 'expense-123', text: 'Hello!');
      expect(event.props, contains('expense-123'));
      expect(event.props, contains('Hello!'));
    });

    test('SubscribeToChatStream props contain expenseId', () {
      const event = SubscribeToChatStream('expense-123');
      expect(event.props, contains('expense-123'));
    });

    test('ChatMessagesUpdated props contain messages list', () {
      final event = ChatMessagesUpdated(testMessages);
      expect(event.props, contains(testMessages));
    });

    test('ClearChatError props are empty', () {
      const event = ClearChatError();
      expect(event.props, isEmpty);
    });

    test('MarkMessagesAsRead props contain expenseId', () {
      const event = MarkMessagesAsRead('expense-123');
      expect(event.props, contains('expense-123'));
    });

    test('DeleteMessage props contain expenseId and messageId', () {
      const event = DeleteMessage(expenseId: 'expense-123', messageId: 'msg-1');
      expect(event.props, contains('expense-123'));
      expect(event.props, contains('msg-1'));
    });

    test('EditTextMessage props contain all fields', () {
      const event = EditTextMessage(
        expenseId: 'expense-123',
        messageId: 'msg-1',
        newText: 'Updated',
      );
      expect(event.props, contains('expense-123'));
      expect(event.props, contains('msg-1'));
      expect(event.props, contains('Updated'));
    });

    test('VoiceRecordingProgressUpdated props contain durationMs', () {
      const event = VoiceRecordingProgressUpdated(5000);
      expect(event.props, contains(5000));
    });
  });

  group('ChatMessageEntity', () {
    test('creates message with required fields', () {
      final message = ChatMessageEntity(
        id: 'msg-1',
        expenseId: 'expense-123',
        type: ChatMessageType.text,
        sender: testSender,
        createdAt: testDate,
      );
      expect(message.id, 'msg-1');
      expect(message.expenseId, 'expense-123');
      expect(message.type, ChatMessageType.text);
    });

    test('creates text message', () {
      final message = ChatMessageEntity(
        id: 'msg-1',
        expenseId: 'expense-123',
        type: ChatMessageType.text,
        sender: testSender,
        text: 'Hello!',
        createdAt: testDate,
      );
      expect(message.text, 'Hello!');
    });

    test('creates image message', () {
      final message = ChatMessageEntity(
        id: 'msg-1',
        expenseId: 'expense-123',
        type: ChatMessageType.image,
        sender: testSender,
        imageUrl: 'https://example.com/image.jpg',
        createdAt: testDate,
      );
      expect(message.imageUrl, 'https://example.com/image.jpg');
    });

    test('creates voice note message', () {
      final message = ChatMessageEntity(
        id: 'msg-1',
        expenseId: 'expense-123',
        type: ChatMessageType.voiceNote,
        sender: testSender,
        voiceNoteUrl: 'https://example.com/audio.mp3',
        voiceNoteDurationMs: 5000,
        createdAt: testDate,
      );
      expect(message.voiceNoteUrl, 'https://example.com/audio.mp3');
      expect(message.voiceNoteDurationMs, 5000);
    });
  });

  group('ChatSender', () {
    test('creates sender with all fields', () {
      final sender = ChatSender(
        id: 'user-1',
        displayName: 'John',
        photoUrl: 'https://example.com/photo.jpg',
      );
      expect(sender.id, 'user-1');
      expect(sender.displayName, 'John');
      expect(sender.photoUrl, 'https://example.com/photo.jpg');
    });

    test('creates sender without photo', () {
      final sender = ChatSender(id: 'user-1', displayName: 'John');
      expect(sender.photoUrl, isNull);
    });
  });
}
