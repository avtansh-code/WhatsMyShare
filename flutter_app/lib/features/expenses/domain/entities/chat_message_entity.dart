import 'package:equatable/equatable.dart';

/// Chat message type enum
enum ChatMessageType {
  text,
  image,
  voiceNote;

  String get displayName {
    switch (this) {
      case ChatMessageType.text:
        return 'Text';
      case ChatMessageType.image:
        return 'Image';
      case ChatMessageType.voiceNote:
        return 'Voice Note';
    }
  }
}

/// Sender information for chat messages
class ChatSender extends Equatable {
  final String id;
  final String displayName;
  final String? photoUrl;

  const ChatSender({
    required this.id,
    required this.displayName,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, displayName, photoUrl];
}

/// Chat message entity for expense discussions
class ChatMessageEntity extends Equatable {
  final String id;
  final String expenseId;
  final ChatSender sender;
  final ChatMessageType type;
  final String? text;
  final String? imageUrl;
  final String? voiceNoteUrl;
  final int? voiceNoteDurationMs;
  final bool isRead;
  final List<String> readBy;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;

  const ChatMessageEntity({
    required this.id,
    required this.expenseId,
    required this.sender,
    required this.type,
    this.text,
    this.imageUrl,
    this.voiceNoteUrl,
    this.voiceNoteDurationMs,
    this.isRead = false,
    this.readBy = const [],
    required this.createdAt,
    this.editedAt,
    this.isDeleted = false,
  });

  /// Check if this message is a text message
  bool get isText => type == ChatMessageType.text;

  /// Check if this message is an image
  bool get isImage => type == ChatMessageType.image;

  /// Check if this message is a voice note
  bool get isVoiceNote => type == ChatMessageType.voiceNote;

  /// Get formatted voice note duration
  String get formattedVoiceDuration {
    if (voiceNoteDurationMs == null) return '0:00';
    final seconds = voiceNoteDurationMs! ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Check if message was read by a specific user
  bool wasReadBy(String userId) => readBy.contains(userId);

  /// Get the content preview for notifications
  String get contentPreview {
    switch (type) {
      case ChatMessageType.text:
        return text ?? '';
      case ChatMessageType.image:
        return '📷 Image';
      case ChatMessageType.voiceNote:
        return '🎤 Voice note ($formattedVoiceDuration)';
    }
  }

  ChatMessageEntity copyWith({
    String? id,
    String? expenseId,
    ChatSender? sender,
    ChatMessageType? type,
    String? text,
    String? imageUrl,
    String? voiceNoteUrl,
    int? voiceNoteDurationMs,
    bool? isRead,
    List<String>? readBy,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isDeleted,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      voiceNoteDurationMs: voiceNoteDurationMs ?? this.voiceNoteDurationMs,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    expenseId,
    sender,
    type,
    text,
    imageUrl,
    voiceNoteUrl,
    voiceNoteDurationMs,
    isRead,
    readBy,
    createdAt,
    editedAt,
    isDeleted,
  ];
}
