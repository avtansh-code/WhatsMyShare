import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message_entity.dart';

/// Base class for all chat events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Load chat messages for an expense
class LoadChatMessages extends ChatEvent {
  final String expenseId;

  const LoadChatMessages(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

/// Subscribe to real-time chat updates
class SubscribeToChatStream extends ChatEvent {
  final String expenseId;

  const SubscribeToChatStream(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

/// Unsubscribe from chat stream
class UnsubscribeFromChatStream extends ChatEvent {
  const UnsubscribeFromChatStream();
}

/// Messages updated from stream
class ChatMessagesUpdated extends ChatEvent {
  final List<ChatMessageEntity> messages;

  const ChatMessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Send a text message
class SendTextMessage extends ChatEvent {
  final String expenseId;
  final String text;

  const SendTextMessage({required this.expenseId, required this.text});

  @override
  List<Object?> get props => [expenseId, text];
}

/// Send an image message
class SendImageMessage extends ChatEvent {
  final String expenseId;
  final File imageFile;

  const SendImageMessage({required this.expenseId, required this.imageFile});

  @override
  List<Object?> get props => [expenseId, imageFile];
}

/// Send a voice note message
class SendVoiceNoteMessage extends ChatEvent {
  final String expenseId;
  final File audioFile;
  final int durationMs;

  const SendVoiceNoteMessage({
    required this.expenseId,
    required this.audioFile,
    required this.durationMs,
  });

  @override
  List<Object?> get props => [expenseId, audioFile, durationMs];
}

/// Mark messages as read
class MarkMessagesAsRead extends ChatEvent {
  final String expenseId;

  const MarkMessagesAsRead(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

/// Delete a message
class DeleteMessage extends ChatEvent {
  final String expenseId;
  final String messageId;

  const DeleteMessage({required this.expenseId, required this.messageId});

  @override
  List<Object?> get props => [expenseId, messageId];
}

/// Edit a text message
class EditTextMessage extends ChatEvent {
  final String expenseId;
  final String messageId;
  final String newText;

  const EditTextMessage({
    required this.expenseId,
    required this.messageId,
    required this.newText,
  });

  @override
  List<Object?> get props => [expenseId, messageId, newText];
}

/// Start voice recording
class StartVoiceRecording extends ChatEvent {
  const StartVoiceRecording();
}

/// Stop voice recording
class StopVoiceRecording extends ChatEvent {
  const StopVoiceRecording();
}

/// Cancel voice recording
class CancelVoiceRecording extends ChatEvent {
  const CancelVoiceRecording();
}

/// Voice recording progress update
class VoiceRecordingProgressUpdated extends ChatEvent {
  final int durationMs;

  const VoiceRecordingProgressUpdated(this.durationMs);

  @override
  List<Object?> get props => [durationMs];
}

/// Clear chat error
class ClearChatError extends ChatEvent {
  const ClearChatError();
}
