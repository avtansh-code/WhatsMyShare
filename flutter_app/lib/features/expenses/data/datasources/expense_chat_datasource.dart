import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../models/chat_message_model.dart';

/// Data source for expense chat operations
class ExpenseChatDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid = const Uuid();
  final LoggingService _log = LoggingService();

  ExpenseChatDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance {
    _log.debug('ExpenseChatDataSource initialized', tag: LogTags.chat);
  }

  /// Get chat collection reference for an expense
  CollectionReference<Map<String, dynamic>> _chatCollection(String expenseId) {
    return _firestore.collection('expenses').doc(expenseId).collection('chat');
  }

  /// Send a text message
  Future<ChatMessageEntity> sendTextMessage({
    required String expenseId,
    required ChatSender sender,
    required String text,
  }) async {
    _log.info(
      'Sending text message',
      tag: LogTags.chat,
      data: {'expenseId': expenseId, 'senderId': sender.id},
    );
    try {
      final messageData = ChatMessageModel.toNewMessageMap(
        expenseId: expenseId,
        sender: sender,
        type: ChatMessageType.text,
        text: text,
      );

      final docRef = await _chatCollection(expenseId).add(messageData);

      // Update expense chat message count
      await _updateChatMessageCount(expenseId, 1);

      final doc = await docRef.get();
      _log.info(
        'Text message sent successfully',
        tag: LogTags.chat,
        data: {'messageId': docRef.id},
      );
      return ChatMessageModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to send text message',
        tag: LogTags.chat,
        data: {'expenseId': expenseId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to send message');
    }
  }

  /// Send an image message
  Future<ChatMessageEntity> sendImageMessage({
    required String expenseId,
    required ChatSender sender,
    required File imageFile,
  }) async {
    _log.info(
      'Sending image message',
      tag: LogTags.chat,
      data: {'expenseId': expenseId, 'senderId': sender.id},
    );
    try {
      // Upload image to Firebase Storage
      final imageUrl = await _uploadChatImage(expenseId, imageFile);
      _log.debug('Image uploaded successfully', tag: LogTags.chat);

      final messageData = ChatMessageModel.toNewMessageMap(
        expenseId: expenseId,
        sender: sender,
        type: ChatMessageType.image,
        imageUrl: imageUrl,
      );

      final docRef = await _chatCollection(expenseId).add(messageData);

      // Update expense chat message count
      await _updateChatMessageCount(expenseId, 1);

      final doc = await docRef.get();
      _log.info(
        'Image message sent successfully',
        tag: LogTags.chat,
        data: {'messageId': docRef.id},
      );
      return ChatMessageModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to send image message',
        tag: LogTags.chat,
        data: {'expenseId': expenseId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to send image');
    }
  }

  /// Send a voice note message
  Future<ChatMessageEntity> sendVoiceNoteMessage({
    required String expenseId,
    required ChatSender sender,
    required File audioFile,
    required int durationMs,
  }) async {
    _log.info(
      'Sending voice note',
      tag: LogTags.chat,
      data: {
        'expenseId': expenseId,
        'senderId': sender.id,
        'durationMs': durationMs,
      },
    );
    try {
      // Upload voice note to Firebase Storage
      final voiceNoteUrl = await _uploadVoiceNote(expenseId, audioFile);
      _log.debug('Voice note uploaded successfully', tag: LogTags.chat);

      final messageData = ChatMessageModel.toNewMessageMap(
        expenseId: expenseId,
        sender: sender,
        type: ChatMessageType.voiceNote,
        voiceNoteUrl: voiceNoteUrl,
        voiceNoteDurationMs: durationMs,
      );

      final docRef = await _chatCollection(expenseId).add(messageData);

      // Update expense chat message count
      await _updateChatMessageCount(expenseId, 1);

      final doc = await docRef.get();
      _log.info(
        'Voice note sent successfully',
        tag: LogTags.chat,
        data: {'messageId': docRef.id},
      );
      return ChatMessageModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to send voice note',
        tag: LogTags.chat,
        data: {'expenseId': expenseId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to send voice note');
    }
  }

  /// Get messages stream for real-time updates
  Stream<List<ChatMessageEntity>> getMessagesStream(String expenseId) {
    _log.debug(
      'Setting up messages stream',
      tag: LogTags.chat,
      data: {'expenseId': expenseId},
    );
    return _chatCollection(expenseId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          _log.debug(
            'Messages stream updated',
            tag: LogTags.chat,
            data: {'count': snapshot.docs.length},
          );
          return snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get paginated messages
  Future<List<ChatMessageEntity>> getMessages({
    required String expenseId,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    _log.debug(
      'Fetching messages',
      tag: LogTags.chat,
      data: {'expenseId': expenseId, 'limit': limit},
    );
    try {
      Query<Map<String, dynamic>> query = _chatCollection(expenseId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final messages = snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList()
          .reversed
          .toList();
      _log.info(
        'Messages fetched successfully',
        tag: LogTags.chat,
        data: {'count': messages.length},
      );
      return messages;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get messages',
        tag: LogTags.chat,
        data: {'expenseId': expenseId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to get messages');
    }
  }

  /// Mark message as read by user
  Future<void> markAsRead({
    required String expenseId,
    required String messageId,
    required String userId,
  }) async {
    _log.debug(
      'Marking message as read',
      tag: LogTags.chat,
      data: {'messageId': messageId, 'userId': userId},
    );
    try {
      await _chatCollection(expenseId).doc(messageId).update({
        'readBy': FieldValue.arrayUnion([userId]),
        'isRead': true,
      });
      _log.debug('Message marked as read', tag: LogTags.chat);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to mark message as read',
        tag: LogTags.chat,
        data: {'messageId': messageId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to mark as read');
    }
  }

  /// Mark all messages as read by user
  Future<void> markAllAsRead({
    required String expenseId,
    required String userId,
  }) async {
    _log.info(
      'Marking all messages as read',
      tag: LogTags.chat,
      data: {'expenseId': expenseId, 'userId': userId},
    );
    try {
      final batch = _firestore.batch();

      final unreadMessages = await _chatCollection(
        expenseId,
      ).where('isDeleted', isEqualTo: false).get();

      int updateCount = 0;
      for (final doc in unreadMessages.docs) {
        final readBy = (doc.data()['readBy'] as List<dynamic>?) ?? [];
        if (!readBy.contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
            'isRead': true,
          });
          updateCount++;
        }
      }

      await batch.commit();
      _log.info(
        'All messages marked as read',
        tag: LogTags.chat,
        data: {'updatedCount': updateCount},
      );
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to mark all as read',
        tag: LogTags.chat,
        data: {'expenseId': expenseId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to mark all as read');
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage({
    required String expenseId,
    required String messageId,
  }) async {
    _log.info(
      'Deleting message',
      tag: LogTags.chat,
      data: {'expenseId': expenseId, 'messageId': messageId},
    );
    try {
      await _chatCollection(
        expenseId,
      ).doc(messageId).update({'isDeleted': true});

      // Update expense chat message count
      await _updateChatMessageCount(expenseId, -1);
      _log.info('Message deleted successfully', tag: LogTags.chat);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to delete message',
        tag: LogTags.chat,
        data: {'messageId': messageId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to delete message');
    }
  }

  /// Edit a text message
  Future<ChatMessageEntity> editMessage({
    required String expenseId,
    required String messageId,
    required String newText,
  }) async {
    _log.info(
      'Editing message',
      tag: LogTags.chat,
      data: {'expenseId': expenseId, 'messageId': messageId},
    );
    try {
      await _chatCollection(expenseId).doc(messageId).update({
        'text': newText,
        'editedAt': FieldValue.serverTimestamp(),
      });

      final doc = await _chatCollection(expenseId).doc(messageId).get();
      _log.info('Message edited successfully', tag: LogTags.chat);
      return ChatMessageModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to edit message',
        tag: LogTags.chat,
        data: {'messageId': messageId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to edit message');
    }
  }

  /// Get unread message count for a user
  Future<int> getUnreadCount({
    required String expenseId,
    required String userId,
  }) async {
    _log.debug(
      'Getting unread count',
      tag: LogTags.chat,
      data: {'expenseId': expenseId, 'userId': userId},
    );
    try {
      final snapshot = await _chatCollection(
        expenseId,
      ).where('isDeleted', isEqualTo: false).get();

      int unreadCount = 0;
      for (final doc in snapshot.docs) {
        final readBy = (doc.data()['readBy'] as List<dynamic>?) ?? [];
        final senderId = (doc.data()['sender'] as Map<String, dynamic>)['id'];
        if (!readBy.contains(userId) && senderId != userId) {
          unreadCount++;
        }
      }
      _log.debug(
        'Unread count fetched',
        tag: LogTags.chat,
        data: {'count': unreadCount},
      );
      return unreadCount;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to get unread count',
        tag: LogTags.chat,
        data: {'expenseId': expenseId, 'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to get unread count');
    }
  }

  /// Upload chat image to Firebase Storage
  Future<String> _uploadChatImage(String expenseId, File imageFile) async {
    _log.debug(
      'Uploading chat image',
      tag: LogTags.chat,
      data: {'expenseId': expenseId},
    );
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('chat_images/$expenseId/$fileName');

      await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));

      final url = await ref.getDownloadURL();
      _log.debug('Chat image uploaded', tag: LogTags.chat);
      return url;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to upload chat image',
        tag: LogTags.chat,
        data: {'error': e.message},
      );
      throw ServerException(message: e.message ?? 'Failed to upload image');
    }
  }

  /// Upload voice note to Firebase Storage
  Future<String> _uploadVoiceNote(String expenseId, File audioFile) async {
    _log.debug(
      'Uploading voice note',
      tag: LogTags.chat,
      data: {'expenseId': expenseId},
    );
    try {
      final fileName = '${_uuid.v4()}.m4a';
      final ref = _storage.ref().child('voice_notes/$expenseId/$fileName');

      await ref.putFile(audioFile, SettableMetadata(contentType: 'audio/m4a'));

      final url = await ref.getDownloadURL();
      _log.debug('Voice note uploaded', tag: LogTags.chat);
      return url;
    } on FirebaseException catch (e) {
      _log.error(
        'Failed to upload voice note',
        tag: LogTags.chat,
        data: {'error': e.message},
      );
      throw ServerException(
        message: e.message ?? 'Failed to upload voice note',
      );
    }
  }

  /// Update expense chat message count
  Future<void> _updateChatMessageCount(String expenseId, int delta) async {
    _log.debug(
      'Updating chat message count',
      tag: LogTags.chat,
      data: {'expenseId': expenseId, 'delta': delta},
    );
    try {
      await _firestore.collection('expenses').doc(expenseId).update({
        'chatMessageCount': FieldValue.increment(delta),
      });
    } on FirebaseException catch (e) {
      _log.warning(
        'Failed to update chat message count',
        tag: LogTags.chat,
        data: {'error': e.message},
      );
      // Don't throw - this is a secondary operation
    }
  }
}
