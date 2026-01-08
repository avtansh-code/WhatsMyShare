import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/expense_chat_datasource.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// BLoC for managing expense chat
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ExpenseChatDataSource _chatDataSource;
  final AuthRepository _authRepository;

  StreamSubscription<List<ChatMessageEntity>>? _messagesSubscription;

  ChatBloc({
    required ExpenseChatDataSource chatDataSource,
    required AuthRepository authRepository,
  }) : _chatDataSource = chatDataSource,
       _authRepository = authRepository,
       super(const ChatState()) {
    on<LoadChatMessages>(_onLoadChatMessages);
    on<SubscribeToChatStream>(_onSubscribeToChatStream);
    on<UnsubscribeFromChatStream>(_onUnsubscribeFromChatStream);
    on<ChatMessagesUpdated>(_onChatMessagesUpdated);
    on<SendTextMessage>(_onSendTextMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<SendVoiceNoteMessage>(_onSendVoiceNoteMessage);
    on<MarkMessagesAsRead>(_onMarkMessagesAsRead);
    on<DeleteMessage>(_onDeleteMessage);
    on<EditTextMessage>(_onEditTextMessage);
    on<StartVoiceRecording>(_onStartVoiceRecording);
    on<StopVoiceRecording>(_onStopVoiceRecording);
    on<CancelVoiceRecording>(_onCancelVoiceRecording);
    on<VoiceRecordingProgressUpdated>(_onVoiceRecordingProgressUpdated);
    on<ClearChatError>(_onClearChatError);
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(status: ChatStatus.loading, expenseId: event.expenseId),
    );

    try {
      final messages = await _chatDataSource.getMessages(
        expenseId: event.expenseId,
      );

      emit(state.copyWith(status: ChatStatus.loaded, messages: messages));
    } catch (e) {
      emit(state.copyWith(status: ChatStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSubscribeToChatStream(
    SubscribeToChatStream event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      state.copyWith(status: ChatStatus.loading, expenseId: event.expenseId),
    );

    await _messagesSubscription?.cancel();

    _messagesSubscription = _chatDataSource
        .getMessagesStream(event.expenseId)
        .listen((messages) {
          add(ChatMessagesUpdated(messages));
        });
  }

  void _onUnsubscribeFromChatStream(
    UnsubscribeFromChatStream event,
    Emitter<ChatState> emit,
  ) {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
  }

  void _onChatMessagesUpdated(
    ChatMessagesUpdated event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(status: ChatStatus.loaded, messages: event.messages));
  }

  Future<void> _onSendTextMessage(
    SendTextMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isSending: true));

    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final sender = ChatSender(
        id: currentUser.id,
        displayName: currentUser.displayName ?? 'Unknown',
        photoUrl: currentUser.photoUrl,
      );

      await _chatDataSource.sendTextMessage(
        expenseId: event.expenseId,
        sender: sender,
        text: event.text,
      );

      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSending: false,
          status: ChatStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSendImageMessage(
    SendImageMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isSending: true));

    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final sender = ChatSender(
        id: currentUser.id,
        displayName: currentUser.displayName ?? 'Unknown',
        photoUrl: currentUser.photoUrl,
      );

      await _chatDataSource.sendImageMessage(
        expenseId: event.expenseId,
        sender: sender,
        imageFile: event.imageFile,
      );

      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(
        state.copyWith(
          isSending: false,
          status: ChatStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSendVoiceNoteMessage(
    SendVoiceNoteMessage event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isSending: true));

    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final sender = ChatSender(
        id: currentUser.id,
        displayName: currentUser.displayName ?? 'Unknown',
        photoUrl: currentUser.photoUrl,
      );

      await _chatDataSource.sendVoiceNoteMessage(
        expenseId: event.expenseId,
        sender: sender,
        audioFile: event.audioFile,
        durationMs: event.durationMs,
      );

      emit(
        state.copyWith(
          isSending: false,
          voiceRecordingStatus: VoiceRecordingStatus.idle,
          voiceRecordingDurationMs: 0,
          voiceRecordingPath: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSending: false,
          status: ChatStatus.error,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) return;

      await _chatDataSource.markAllAsRead(
        expenseId: event.expenseId,
        userId: currentUser.id,
      );
    } catch (e) {
      // Silent fail for marking as read
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatDataSource.deleteMessage(
        expenseId: event.expenseId,
        messageId: event.messageId,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          error: 'Failed to delete message: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onEditTextMessage(
    EditTextMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatDataSource.editMessage(
        expenseId: event.expenseId,
        messageId: event.messageId,
        newText: event.newText,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          error: 'Failed to edit message: ${e.toString()}',
        ),
      );
    }
  }

  void _onStartVoiceRecording(
    StartVoiceRecording event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        voiceRecordingStatus: VoiceRecordingStatus.recording,
        voiceRecordingDurationMs: 0,
      ),
    );
  }

  void _onStopVoiceRecording(
    StopVoiceRecording event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(voiceRecordingStatus: VoiceRecordingStatus.stopped));
  }

  void _onCancelVoiceRecording(
    CancelVoiceRecording event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        voiceRecordingStatus: VoiceRecordingStatus.idle,
        voiceRecordingDurationMs: 0,
        voiceRecordingPath: null,
      ),
    );
  }

  void _onVoiceRecordingProgressUpdated(
    VoiceRecordingProgressUpdated event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(voiceRecordingDurationMs: event.durationMs));
  }

  void _onClearChatError(ClearChatError event, Emitter<ChatState> emit) {
    emit(state.copyWith(status: ChatStatus.loaded, error: null));
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
