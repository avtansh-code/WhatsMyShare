import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../models/chat_message_model.dart';

/// Data source for expense chat operations
class ExpenseChatDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final Uuid _uuid = const Uuid();

  ExpenseChatDataSource({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

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
    return ChatMessageModel.fromFirestore(doc);
  }

  /// Send an image message
  Future<ChatMessageEntity> sendImageMessage({
    required String expenseId,
    required ChatSender sender,
    required File imageFile,
  }) async {
    // Upload image to Firebase Storage
    final imageUrl = await _uploadChatImage(expenseId, imageFile);

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
    return ChatMessageModel.fromFirestore(doc);
  }

  /// Send a voice note message
  Future<ChatMessageEntity> sendVoiceNoteMessage({
    required String expenseId,
    required ChatSender sender,
    required File audioFile,
    required int durationMs,
  }) async {
    // Upload voice note to Firebase Storage
    final voiceNoteUrl = await _uploadVoiceNote(expenseId, audioFile);

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
    return ChatMessageModel.fromFirestore(doc);
  }

  /// Get messages stream for real-time updates
  Stream<List<ChatMessageEntity>> getMessagesStream(String expenseId) {
    return _chatCollection(expenseId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessageModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get paginated messages
  Future<List<ChatMessageEntity>> getMessages({
    required String expenseId,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    Query<Map<String, dynamic>> query = _chatCollection(expenseId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ChatMessageModel.fromFirestore(doc))
        .toList()
        .reversed
        .toList();
  }

  /// Mark message as read by user
  Future<void> markAsRead({
    required String expenseId,
    required String messageId,
    required String userId,
  }) async {
    await _chatCollection(expenseId).doc(messageId).update({
      'readBy': FieldValue.arrayUnion([userId]),
      'isRead': true,
    });
  }

  /// Mark all messages as read by user
  Future<void> markAllAsRead({
    required String expenseId,
    required String userId,
  }) async {
    final batch = _firestore.batch();

    final unreadMessages = await _chatCollection(
      expenseId,
    ).where('isDeleted', isEqualTo: false).get();

    for (final doc in unreadMessages.docs) {
      final readBy = (doc.data()['readBy'] as List<dynamic>?) ?? [];
      if (!readBy.contains(userId)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
          'isRead': true,
        });
      }
    }

    await batch.commit();
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage({
    required String expenseId,
    required String messageId,
  }) async {
    await _chatCollection(expenseId).doc(messageId).update({'isDeleted': true});

    // Update expense chat message count
    await _updateChatMessageCount(expenseId, -1);
  }

  /// Edit a text message
  Future<ChatMessageEntity> editMessage({
    required String expenseId,
    required String messageId,
    required String newText,
  }) async {
    await _chatCollection(expenseId).doc(messageId).update({
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
    });

    final doc = await _chatCollection(expenseId).doc(messageId).get();
    return ChatMessageModel.fromFirestore(doc);
  }

  /// Get unread message count for a user
  Future<int> getUnreadCount({
    required String expenseId,
    required String userId,
  }) async {
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
    return unreadCount;
  }

  /// Upload chat image to Firebase Storage
  Future<String> _uploadChatImage(String expenseId, File imageFile) async {
    final fileName = '${_uuid.v4()}.jpg';
    final ref = _storage.ref().child('chat_images/$expenseId/$fileName');

    await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));

    return await ref.getDownloadURL();
  }

  /// Upload voice note to Firebase Storage
  Future<String> _uploadVoiceNote(String expenseId, File audioFile) async {
    final fileName = '${_uuid.v4()}.m4a';
    final ref = _storage.ref().child('voice_notes/$expenseId/$fileName');

    await ref.putFile(audioFile, SettableMetadata(contentType: 'audio/m4a'));

    return await ref.getDownloadURL();
  }

  /// Update expense chat message count
  Future<void> _updateChatMessageCount(String expenseId, int delta) async {
    await _firestore.collection('expenses').doc(expenseId).update({
      'chatMessageCount': FieldValue.increment(delta),
    });
  }
}
