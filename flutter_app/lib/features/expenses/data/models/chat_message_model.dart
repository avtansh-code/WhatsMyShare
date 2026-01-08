import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message_entity.dart';

/// Firestore model for chat sender
class ChatSenderModel extends ChatSender {
  const ChatSenderModel({
    required super.id,
    required super.displayName,
    super.photoUrl,
  });

  factory ChatSenderModel.fromMap(Map<String, dynamic> map) {
    return ChatSenderModel(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'displayName': displayName, 'photoUrl': photoUrl};
  }

  factory ChatSenderModel.fromEntity(ChatSender entity) {
    return ChatSenderModel(
      id: entity.id,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
    );
  }
}

/// Firestore model for chat messages
class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.expenseId,
    required super.sender,
    required super.type,
    super.text,
    super.imageUrl,
    super.voiceNoteUrl,
    super.voiceNoteDurationMs,
    super.isRead,
    super.readBy,
    required super.createdAt,
    super.editedAt,
    super.isDeleted,
  });

  /// Create from Firestore document
  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      expenseId: data['expenseId'] as String,
      sender: ChatSenderModel.fromMap(data['sender'] as Map<String, dynamic>),
      type: _typeFromString(data['type'] as String),
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      voiceNoteUrl: data['voiceNoteUrl'] as String?,
      voiceNoteDurationMs: data['voiceNoteDurationMs'] as int?,
      isRead: data['isRead'] as bool? ?? false,
      readBy: (data['readBy'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  /// Create from map (for snapshots)
  factory ChatMessageModel.fromMap(Map<String, dynamic> data, String id) {
    return ChatMessageModel(
      id: id,
      expenseId: data['expenseId'] as String,
      sender: ChatSenderModel.fromMap(data['sender'] as Map<String, dynamic>),
      type: _typeFromString(data['type'] as String),
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      voiceNoteUrl: data['voiceNoteUrl'] as String?,
      voiceNoteDurationMs: data['voiceNoteDurationMs'] as int?,
      isRead: data['isRead'] as bool? ?? false,
      readBy: (data['readBy'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'expenseId': expenseId,
      'sender': (sender as ChatSenderModel).toMap(),
      'type': type.name,
      'text': text,
      'imageUrl': imageUrl,
      'voiceNoteUrl': voiceNoteUrl,
      'voiceNoteDurationMs': voiceNoteDurationMs,
      'isRead': isRead,
      'readBy': readBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'isDeleted': isDeleted,
    };
  }

  /// Create new message map (for creating new messages)
  static Map<String, dynamic> toNewMessageMap({
    required String expenseId,
    required ChatSender sender,
    required ChatMessageType type,
    String? text,
    String? imageUrl,
    String? voiceNoteUrl,
    int? voiceNoteDurationMs,
  }) {
    return {
      'expenseId': expenseId,
      'sender': ChatSenderModel.fromEntity(sender).toMap(),
      'type': type.name,
      'text': text,
      'imageUrl': imageUrl,
      'voiceNoteUrl': voiceNoteUrl,
      'voiceNoteDurationMs': voiceNoteDurationMs,
      'isRead': false,
      'readBy': [],
      'createdAt': FieldValue.serverTimestamp(),
      'editedAt': null,
      'isDeleted': false,
    };
  }

  /// Create from entity
  factory ChatMessageModel.fromEntity(ChatMessageEntity entity) {
    return ChatMessageModel(
      id: entity.id,
      expenseId: entity.expenseId,
      sender: ChatSenderModel.fromEntity(entity.sender),
      type: entity.type,
      text: entity.text,
      imageUrl: entity.imageUrl,
      voiceNoteUrl: entity.voiceNoteUrl,
      voiceNoteDurationMs: entity.voiceNoteDurationMs,
      isRead: entity.isRead,
      readBy: entity.readBy,
      createdAt: entity.createdAt,
      editedAt: entity.editedAt,
      isDeleted: entity.isDeleted,
    );
  }

  static ChatMessageType _typeFromString(String type) {
    switch (type) {
      case 'text':
        return ChatMessageType.text;
      case 'image':
        return ChatMessageType.image;
      case 'voiceNote':
        return ChatMessageType.voiceNote;
      default:
        return ChatMessageType.text;
    }
  }
}
