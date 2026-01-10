import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/features/expenses/data/models/chat_message_model.dart';
import 'package:whats_my_share/features/expenses/domain/entities/chat_message_entity.dart';

void main() {
  group('ChatSenderModel', () {
    const testSender = ChatSenderModel(
      id: 'user1',
      displayName: 'John Doe',
      photoUrl: 'https://example.com/photo.jpg',
    );

    group('fromMap', () {
      test('creates ChatSenderModel from valid map', () {
        final map = {
          'id': 'user1',
          'displayName': 'John Doe',
          'photoUrl': 'https://example.com/photo.jpg',
        };

        final result = ChatSenderModel.fromMap(map);

        expect(result.id, 'user1');
        expect(result.displayName, 'John Doe');
        expect(result.photoUrl, 'https://example.com/photo.jpg');
      });

      test('creates ChatSenderModel with null photoUrl', () {
        final map = {
          'id': 'user1',
          'displayName': 'John Doe',
          'photoUrl': null,
        };

        final result = ChatSenderModel.fromMap(map);

        expect(result.id, 'user1');
        expect(result.displayName, 'John Doe');
        expect(result.photoUrl, isNull);
      });
    });

    group('toMap', () {
      test('converts ChatSenderModel to map', () {
        final result = testSender.toMap();

        expect(result['id'], 'user1');
        expect(result['displayName'], 'John Doe');
        expect(result['photoUrl'], 'https://example.com/photo.jpg');
      });

      test('includes null photoUrl in map', () {
        const senderWithoutPhoto = ChatSenderModel(
          id: 'user1',
          displayName: 'John Doe',
          photoUrl: null,
        );

        final result = senderWithoutPhoto.toMap();

        expect(result['photoUrl'], isNull);
      });
    });

    group('fromEntity', () {
      test('creates ChatSenderModel from ChatSender entity', () {
        const entity = ChatSender(
          id: 'user1',
          displayName: 'John Doe',
          photoUrl: 'https://example.com/photo.jpg',
        );

        final result = ChatSenderModel.fromEntity(entity);

        expect(result.id, entity.id);
        expect(result.displayName, entity.displayName);
        expect(result.photoUrl, entity.photoUrl);
      });
    });

    test('ChatSenderModel is a ChatSender', () {
      expect(testSender, isA<ChatSender>());
    });
  });

  group('ChatMessageModel', () {
    final testDateTime = DateTime(2026, 1, 9, 12, 0, 0);
    final testEditedAt = DateTime(2026, 1, 9, 13, 0, 0);

    final testMessage = ChatMessageModel(
      id: 'msg1',
      expenseId: 'expense1',
      sender: const ChatSenderModel(
        id: 'user1',
        displayName: 'John Doe',
        photoUrl: 'https://example.com/photo.jpg',
      ),
      type: ChatMessageType.text,
      text: 'Hello, world!',
      imageUrl: null,
      voiceNoteUrl: null,
      voiceNoteDurationMs: null,
      isRead: false,
      readBy: const ['user2'],
      createdAt: testDateTime,
      editedAt: null,
      isDeleted: false,
    );

    group('fromMap', () {
      test('creates ChatMessageModel from valid map with text message', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {
            'id': 'user1',
            'displayName': 'John Doe',
            'photoUrl': 'https://example.com/photo.jpg',
          },
          'type': 'text',
          'text': 'Hello, world!',
          'imageUrl': null,
          'voiceNoteUrl': null,
          'voiceNoteDurationMs': null,
          'isRead': false,
          'readBy': ['user2'],
          'createdAt': Timestamp.fromDate(testDateTime),
          'editedAt': null,
          'isDeleted': false,
        };

        final result = ChatMessageModel.fromMap(map, 'msg1');

        expect(result.id, 'msg1');
        expect(result.expenseId, 'expense1');
        expect(result.sender.id, 'user1');
        expect(result.sender.displayName, 'John Doe');
        expect(result.type, ChatMessageType.text);
        expect(result.text, 'Hello, world!');
        expect(result.isRead, false);
        expect(result.readBy, ['user2']);
        expect(result.createdAt, testDateTime);
        expect(result.isDeleted, false);
      });

      test('creates ChatMessageModel with image type', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {
            'id': 'user1',
            'displayName': 'John Doe',
            'photoUrl': null,
          },
          'type': 'image',
          'text': null,
          'imageUrl': 'https://example.com/image.jpg',
          'voiceNoteUrl': null,
          'voiceNoteDurationMs': null,
          'isRead': true,
          'readBy': ['user1', 'user2'],
          'createdAt': Timestamp.fromDate(testDateTime),
          'editedAt': null,
          'isDeleted': false,
        };

        final result = ChatMessageModel.fromMap(map, 'msg2');

        expect(result.type, ChatMessageType.image);
        expect(result.imageUrl, 'https://example.com/image.jpg');
        expect(result.text, isNull);
      });

      test('creates ChatMessageModel with voiceNote type', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {
            'id': 'user1',
            'displayName': 'John Doe',
            'photoUrl': null,
          },
          'type': 'voiceNote',
          'text': null,
          'imageUrl': null,
          'voiceNoteUrl': 'https://example.com/voice.mp3',
          'voiceNoteDurationMs': 5000,
          'isRead': false,
          'readBy': [],
          'createdAt': Timestamp.fromDate(testDateTime),
          'editedAt': null,
          'isDeleted': false,
        };

        final result = ChatMessageModel.fromMap(map, 'msg3');

        expect(result.type, ChatMessageType.voiceNote);
        expect(result.voiceNoteUrl, 'https://example.com/voice.mp3');
        expect(result.voiceNoteDurationMs, 5000);
      });

      test('defaults isRead to false when not provided', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {
            'id': 'user1',
            'displayName': 'John Doe',
            'photoUrl': null,
          },
          'type': 'text',
          'text': 'Hello',
          'createdAt': Timestamp.fromDate(testDateTime),
        };

        final result = ChatMessageModel.fromMap(map, 'msg1');

        expect(result.isRead, false);
      });

      test('defaults readBy to empty list when not provided', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {
            'id': 'user1',
            'displayName': 'John Doe',
            'photoUrl': null,
          },
          'type': 'text',
          'text': 'Hello',
          'createdAt': Timestamp.fromDate(testDateTime),
        };

        final result = ChatMessageModel.fromMap(map, 'msg1');

        expect(result.readBy, isEmpty);
      });

      test('defaults isDeleted to false when not provided', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {
            'id': 'user1',
            'displayName': 'John Doe',
            'photoUrl': null,
          },
          'type': 'text',
          'text': 'Hello',
          'createdAt': Timestamp.fromDate(testDateTime),
        };

        final result = ChatMessageModel.fromMap(map, 'msg1');

        expect(result.isDeleted, false);
      });

      test('parses editedAt when provided', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {
            'id': 'user1',
            'displayName': 'John Doe',
            'photoUrl': null,
          },
          'type': 'text',
          'text': 'Hello',
          'createdAt': Timestamp.fromDate(testDateTime),
          'editedAt': Timestamp.fromDate(testEditedAt),
          'isRead': false,
          'readBy': [],
          'isDeleted': false,
        };

        final result = ChatMessageModel.fromMap(map, 'msg1');

        expect(result.editedAt, testEditedAt);
      });

      test('defaults to text type for unknown type string', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {
            'id': 'user1',
            'displayName': 'John Doe',
            'photoUrl': null,
          },
          'type': 'unknownType',
          'text': 'Hello',
          'createdAt': Timestamp.fromDate(testDateTime),
        };

        final result = ChatMessageModel.fromMap(map, 'msg1');

        expect(result.type, ChatMessageType.text);
      });
    });

    group('toFirestore', () {
      test('converts ChatMessageModel to Firestore map', () {
        final result = testMessage.toFirestore();

        expect(result['expenseId'], 'expense1');
        expect(result['type'], 'text');
        expect(result['text'], 'Hello, world!');
        expect(result['isRead'], false);
        expect(result['readBy'], ['user2']);
        expect(result['isDeleted'], false);
        expect(result['sender'], isA<Map<String, dynamic>>());
        expect(result['createdAt'], isA<Timestamp>());
      });

      test('includes sender as map in Firestore output', () {
        final result = testMessage.toFirestore();

        final senderMap = result['sender'] as Map<String, dynamic>;
        expect(senderMap['id'], 'user1');
        expect(senderMap['displayName'], 'John Doe');
        expect(senderMap['photoUrl'], 'https://example.com/photo.jpg');
      });

      test('converts createdAt to Timestamp', () {
        final result = testMessage.toFirestore();

        expect(result['createdAt'], isA<Timestamp>());
        expect((result['createdAt'] as Timestamp).toDate(), testDateTime);
      });

      test('sets editedAt to null when not edited', () {
        final result = testMessage.toFirestore();

        expect(result['editedAt'], isNull);
      });

      test('converts editedAt to Timestamp when provided', () {
        final editedMessage = ChatMessageModel(
          id: 'msg1',
          expenseId: 'expense1',
          sender: const ChatSenderModel(
            id: 'user1',
            displayName: 'John Doe',
            photoUrl: null,
          ),
          type: ChatMessageType.text,
          text: 'Edited message',
          createdAt: testDateTime,
          editedAt: testEditedAt,
        );

        final result = editedMessage.toFirestore();

        expect(result['editedAt'], isA<Timestamp>());
        expect((result['editedAt'] as Timestamp).toDate(), testEditedAt);
      });
    });

    group('toNewMessageMap', () {
      test('creates new message map for text message', () {
        const sender = ChatSender(
          id: 'user1',
          displayName: 'John Doe',
          photoUrl: null,
        );

        final result = ChatMessageModel.toNewMessageMap(
          expenseId: 'expense1',
          sender: sender,
          type: ChatMessageType.text,
          text: 'Hello, world!',
        );

        expect(result['expenseId'], 'expense1');
        expect(result['type'], 'text');
        expect(result['text'], 'Hello, world!');
        expect(result['isRead'], false);
        expect(result['readBy'], isEmpty);
        expect(result['isDeleted'], false);
        expect(result['createdAt'], isA<FieldValue>());
        expect(result['editedAt'], isNull);
      });

      test('creates new message map for image message', () {
        const sender = ChatSender(
          id: 'user1',
          displayName: 'John Doe',
          photoUrl: null,
        );

        final result = ChatMessageModel.toNewMessageMap(
          expenseId: 'expense1',
          sender: sender,
          type: ChatMessageType.image,
          imageUrl: 'https://example.com/image.jpg',
        );

        expect(result['type'], 'image');
        expect(result['imageUrl'], 'https://example.com/image.jpg');
        expect(result['text'], isNull);
      });

      test('creates new message map for voice note', () {
        const sender = ChatSender(
          id: 'user1',
          displayName: 'John Doe',
          photoUrl: null,
        );

        final result = ChatMessageModel.toNewMessageMap(
          expenseId: 'expense1',
          sender: sender,
          type: ChatMessageType.voiceNote,
          voiceNoteUrl: 'https://example.com/voice.mp3',
          voiceNoteDurationMs: 5000,
        );

        expect(result['type'], 'voiceNote');
        expect(result['voiceNoteUrl'], 'https://example.com/voice.mp3');
        expect(result['voiceNoteDurationMs'], 5000);
      });

      test('includes sender as map', () {
        const sender = ChatSender(
          id: 'user1',
          displayName: 'John Doe',
          photoUrl: 'https://example.com/photo.jpg',
        );

        final result = ChatMessageModel.toNewMessageMap(
          expenseId: 'expense1',
          sender: sender,
          type: ChatMessageType.text,
          text: 'Hello',
        );

        final senderMap = result['sender'] as Map<String, dynamic>;
        expect(senderMap['id'], 'user1');
        expect(senderMap['displayName'], 'John Doe');
        expect(senderMap['photoUrl'], 'https://example.com/photo.jpg');
      });
    });

    group('fromEntity', () {
      test('creates ChatMessageModel from ChatMessageEntity', () {
        final entity = ChatMessageEntity(
          id: 'msg1',
          expenseId: 'expense1',
          sender: const ChatSender(
            id: 'user1',
            displayName: 'John Doe',
            photoUrl: 'https://example.com/photo.jpg',
          ),
          type: ChatMessageType.text,
          text: 'Hello',
          createdAt: testDateTime,
        );

        final result = ChatMessageModel.fromEntity(entity);

        expect(result.id, entity.id);
        expect(result.expenseId, entity.expenseId);
        expect(result.sender.id, entity.sender.id);
        expect(result.type, entity.type);
        expect(result.text, entity.text);
        expect(result.createdAt, entity.createdAt);
      });

      test('preserves all optional fields from entity', () {
        final entity = ChatMessageEntity(
          id: 'msg1',
          expenseId: 'expense1',
          sender: const ChatSender(
            id: 'user1',
            displayName: 'John Doe',
            photoUrl: null,
          ),
          type: ChatMessageType.voiceNote,
          voiceNoteUrl: 'https://example.com/voice.mp3',
          voiceNoteDurationMs: 5000,
          isRead: true,
          readBy: const ['user2', 'user3'],
          createdAt: testDateTime,
          editedAt: testEditedAt,
          isDeleted: true,
        );

        final result = ChatMessageModel.fromEntity(entity);

        expect(result.voiceNoteUrl, entity.voiceNoteUrl);
        expect(result.voiceNoteDurationMs, entity.voiceNoteDurationMs);
        expect(result.isRead, entity.isRead);
        expect(result.readBy, entity.readBy);
        expect(result.editedAt, entity.editedAt);
        expect(result.isDeleted, entity.isDeleted);
      });
    });

    group('inheritance', () {
      test('ChatMessageModel is a ChatMessageEntity', () {
        expect(testMessage, isA<ChatMessageEntity>());
      });

      test('can be used where ChatMessageEntity is expected', () {
        ChatMessageEntity entity = testMessage;
        expect(entity.id, 'msg1');
        expect(entity.type, ChatMessageType.text);
      });
    });

    group('type parsing', () {
      test('parses text type', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {'id': 'u1', 'displayName': 'User', 'photoUrl': null},
          'type': 'text',
          'text': 'Hello',
          'createdAt': Timestamp.fromDate(testDateTime),
        };

        final result = ChatMessageModel.fromMap(map, 'id');
        expect(result.type, ChatMessageType.text);
      });

      test('parses image type', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {'id': 'u1', 'displayName': 'User', 'photoUrl': null},
          'type': 'image',
          'imageUrl': 'url',
          'createdAt': Timestamp.fromDate(testDateTime),
        };

        final result = ChatMessageModel.fromMap(map, 'id');
        expect(result.type, ChatMessageType.image);
      });

      test('parses voiceNote type', () {
        final map = {
          'expenseId': 'expense1',
          'sender': {'id': 'u1', 'displayName': 'User', 'photoUrl': null},
          'type': 'voiceNote',
          'voiceNoteUrl': 'url',
          'createdAt': Timestamp.fromDate(testDateTime),
        };

        final result = ChatMessageModel.fromMap(map, 'id');
        expect(result.type, ChatMessageType.voiceNote);
      });
    });
  });
}
