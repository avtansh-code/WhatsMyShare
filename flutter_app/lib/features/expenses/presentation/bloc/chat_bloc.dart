import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/error_messages.dart';
import '../../../../core/services/logging_service.dart';
import '../../data/datasources/expense_chat_datasource.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// BLoC for managing expense chat
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ExpenseChatDataSource _chatDataSource;
  final AuthRepository _authRepository;
  final LoggingService _log = LoggingService();

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

    _log.info('ChatBloc initialized', tag: LogTags.chat);
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessages event,
    Emitter<ChatState> emit,
  ) async {
    _log.debug(
      'Loading chat messages',
      tag: LogTags.chat,
      data: {'expenseId': event.expenseId},
    );
    emit(
      state.copyWith(status: ChatStatus.loading, expenseId: event.expenseId),
    );

    try {
      final messages = await _chatDataSource.getMessages(
        expenseId: event.expenseId,
      );

      _log.info(
        'Chat messages loaded',
        tag: LogTags.chat,
        data: {'expenseId': event.expenseId, 'count': messages.length},
      );
      emit(state.copyWith(status: ChatStatus.loaded, messages: messages));
    } catch (e, stackTrace) {
      _log.error(
        'Failed to load chat messages',
        tag: LogTags.chat,
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: ChatStatus.error,
          error: ErrorMessages.chatLoadFailed,
        ),
      );
    }
  }

  Future<void> _onSubscribeToChatStream(
    SubscribeToChatStream event,
    Emitter<ChatState> emit,
  ) async {
    _log.debug(
      'Subscribing to chat stream',
      tag: LogTags.chat,
      data: {'expenseId': event.expenseId},
    );
    emit(
      state.copyWith(status: ChatStatus.loading, expenseId: event.expenseId),
    );

    await _messagesSubscription?.cancel();

    _messagesSubscription = _chatDataSource
        .getMessagesStream(event.expenseId)
        .listen(
          (messages) {
            _log.debug(
              'Chat stream updated',
              tag: LogTags.chat,
              data: {'count': messages.length},
            );
            add(ChatMessagesUpdated(messages));
          },
          onError: (error, stackTrace) {
            _log.error(
              'Chat stream error',
              tag: LogTags.chat,
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }

  void _onUnsubscribeFromChatStream(
    UnsubscribeFromChatStream event,
    Emitter<ChatState> emit,
  ) {
    _log.debug('Unsubscribing from chat stream', tag: LogTags.chat);
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
    _log.info(
      'Sending text message',
      tag: LogTags.chat,
      data: {'expenseId': event.expenseId},
    );
    emit(state.copyWith(isSending: true));

    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        _log.warning(
          'User not authenticated when sending message',
          tag: LogTags.chat,
        );
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

      _log.debug('Text message sent successfully', tag: LogTags.chat);
      emit(state.copyWith(isSending: false));
    } catch (e, stackTrace) {
      _log.error(
        'Failed to send text message',
        tag: LogTags.chat,
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          isSending: false,
          status: ChatStatus.error,
          error: ErrorMessages.chatSendFailed,
        ),
      );
    }
  }

  Future<void> _onSendImageMessage(
    SendImageMessage event,
    Emitter<ChatState> emit,
  ) async {
    _log.info(
      'Sending image message',
      tag: LogTags.chat,
      data: {'expenseId': event.expenseId},
    );
    emit(state.copyWith(isSending: true));

    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        _log.warning(
          'User not authenticated when sending image',
          tag: LogTags.chat,
        );
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

      _log.debug('Image message sent successfully', tag: LogTags.chat);
      emit(state.copyWith(isSending: false));
    } catch (e, stackTrace) {
      _log.error(
        'Failed to send image message',
        tag: LogTags.chat,
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          isSending: false,
          status: ChatStatus.error,
          error: ErrorMessages.chatImageUploadFailed,
        ),
      );
    }
  }

  Future<void> _onSendVoiceNoteMessage(
    SendVoiceNoteMessage event,
    Emitter<ChatState> emit,
  ) async {
    _log.info(
      'Sending voice note message',
      tag: LogTags.chat,
      data: {'expenseId': event.expenseId, 'durationMs': event.durationMs},
    );
    emit(state.copyWith(isSending: true));

    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        _log.warning(
          'User not authenticated when sending voice note',
          tag: LogTags.chat,
        );
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

      _log.debug('Voice note message sent successfully', tag: LogTags.chat);
      emit(
        state.copyWith(
          isSending: false,
          voiceRecordingStatus: VoiceRecordingStatus.idle,
          voiceRecordingDurationMs: 0,
          voiceRecordingPath: null,
        ),
      );
    } catch (e, stackTrace) {
      _log.error(
        'Failed to send voice note message',
        tag: LogTags.chat,
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          isSending: false,
          status: ChatStatus.error,
          error: ErrorMessages.chatVoiceNoteUploadFailed,
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

      _log.debug(
        'Marking messages as read',
        tag: LogTags.chat,
        data: {'expenseId': event.expenseId},
      );
      await _chatDataSource.markAllAsRead(
        expenseId: event.expenseId,
        userId: currentUser.id,
      );
    } catch (e) {
      // Silent fail for marking as read
      _log.warning('Failed to mark messages as read', tag: LogTags.chat);
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    _log.info(
      'Deleting message',
      tag: LogTags.chat,
      data: {'messageId': event.messageId},
    );
    try {
      await _chatDataSource.deleteMessage(
        expenseId: event.expenseId,
        messageId: event.messageId,
      );
      _log.debug('Message deleted successfully', tag: LogTags.chat);
    } catch (e, stackTrace) {
      _log.error(
        'Failed to delete message',
        tag: LogTags.chat,
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: ChatStatus.error,
          error: ErrorMessages.chatDeleteFailed,
        ),
      );
    }
  }

  Future<void> _onEditTextMessage(
    EditTextMessage event,
    Emitter<ChatState> emit,
  ) async {
    _log.info(
      'Editing message',
      tag: LogTags.chat,
      data: {'messageId': event.messageId},
    );
    try {
      await _chatDataSource.editMessage(
        expenseId: event.expenseId,
        messageId: event.messageId,
        newText: event.newText,
      );
      _log.debug('Message edited successfully', tag: LogTags.chat);
    } catch (e, stackTrace) {
      _log.error(
        'Failed to edit message',
        tag: LogTags.chat,
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: ChatStatus.error,
          error: ErrorMessages.chatSendFailed,
        ),
      );
    }
  }

  void _onStartVoiceRecording(
    StartVoiceRecording event,
    Emitter<ChatState> emit,
  ) {
    _log.debug('Starting voice recording', tag: LogTags.chat);
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
    _log.debug('Stopping voice recording', tag: LogTags.chat);
    emit(state.copyWith(voiceRecordingStatus: VoiceRecordingStatus.stopped));
  }

  void _onCancelVoiceRecording(
    CancelVoiceRecording event,
    Emitter<ChatState> emit,
  ) {
    _log.debug('Cancelling voice recording', tag: LogTags.chat);
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
    _log.debug('Clearing chat error', tag: LogTags.chat);
    emit(state.copyWith(status: ChatStatus.loaded, error: null));
  }

  @override
  Future<void> close() {
    _log.debug('ChatBloc closing', tag: LogTags.chat);
    _messagesSubscription?.cancel();
    return super.close();
  }
}
