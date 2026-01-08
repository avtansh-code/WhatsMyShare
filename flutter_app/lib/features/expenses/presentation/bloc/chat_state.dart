import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message_entity.dart';

/// Chat status enum
enum ChatStatus { initial, loading, loaded, sending, error }

/// Voice recording status
enum VoiceRecordingStatus { idle, recording, stopped }

/// Chat state
class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessageEntity> messages;
  final String? error;
  final bool isSending;
  final VoiceRecordingStatus voiceRecordingStatus;
  final int voiceRecordingDurationMs;
  final String? voiceRecordingPath;
  final String? expenseId;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.error,
    this.isSending = false,
    this.voiceRecordingStatus = VoiceRecordingStatus.idle,
    this.voiceRecordingDurationMs = 0,
    this.voiceRecordingPath,
    this.expenseId,
  });

  /// Check if chat is loading
  bool get isLoading => status == ChatStatus.loading;

  /// Check if chat has loaded
  bool get isLoaded => status == ChatStatus.loaded;

  /// Check if there's an error
  bool get hasError => status == ChatStatus.error;

  /// Check if currently recording voice
  bool get isRecording =>
      voiceRecordingStatus == VoiceRecordingStatus.recording;

  /// Check if voice recording is stopped (ready to send)
  bool get hasRecording => voiceRecordingStatus == VoiceRecordingStatus.stopped;

  /// Get message count
  int get messageCount => messages.length;

  /// Check if there are messages
  bool get hasMessages => messages.isNotEmpty;

  /// Get formatted voice recording duration
  String get formattedRecordingDuration {
    final seconds = voiceRecordingDurationMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessageEntity>? messages,
    String? error,
    bool? isSending,
    VoiceRecordingStatus? voiceRecordingStatus,
    int? voiceRecordingDurationMs,
    String? voiceRecordingPath,
    String? expenseId,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      error: error,
      isSending: isSending ?? this.isSending,
      voiceRecordingStatus: voiceRecordingStatus ?? this.voiceRecordingStatus,
      voiceRecordingDurationMs:
          voiceRecordingDurationMs ?? this.voiceRecordingDurationMs,
      voiceRecordingPath: voiceRecordingPath ?? this.voiceRecordingPath,
      expenseId: expenseId ?? this.expenseId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    error,
    isSending,
    voiceRecordingStatus,
    voiceRecordingDurationMs,
    voiceRecordingPath,
    expenseId,
  ];
}
