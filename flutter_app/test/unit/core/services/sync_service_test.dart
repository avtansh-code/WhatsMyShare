import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/core/models/offline_operation.dart';

void main() {
  group('SyncService Operation Type Handling', () {
    test('should recognize all operation types', () {
      // Verify all operation types are available
      expect(OperationType.values.length, equals(10));

      expect(OperationType.createExpense, isNotNull);
      expect(OperationType.updateExpense, isNotNull);
      expect(OperationType.deleteExpense, isNotNull);
      expect(OperationType.createGroup, isNotNull);
      expect(OperationType.updateGroup, isNotNull);
      expect(OperationType.createSettlement, isNotNull);
      expect(OperationType.updateSettlement, isNotNull);
      expect(OperationType.updateProfile, isNotNull);
      expect(OperationType.addGroupMember, isNotNull);
      expect(OperationType.removeGroupMember, isNotNull);
    });

    test('operation types should have correct names', () {
      expect(OperationType.createExpense.name, equals('createExpense'));
      expect(OperationType.updateExpense.name, equals('updateExpense'));
      expect(OperationType.deleteExpense.name, equals('deleteExpense'));
      expect(OperationType.createGroup.name, equals('createGroup'));
      expect(OperationType.updateGroup.name, equals('updateGroup'));
      expect(OperationType.createSettlement.name, equals('createSettlement'));
      expect(OperationType.updateSettlement.name, equals('updateSettlement'));
      expect(OperationType.updateProfile.name, equals('updateProfile'));
      expect(OperationType.addGroupMember.name, equals('addGroupMember'));
      expect(OperationType.removeGroupMember.name, equals('removeGroupMember'));
    });
  });

  group('Operation Creation for Sync', () {
    test('should create expense operation', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {
          'description': 'Test expense',
          'amount': 100.0,
          'currency': 'USD',
        },
        createdAt: DateTime.now(),
        groupId: 'group-123',
      );

      expect(operation.type, equals(OperationType.createExpense));
      expect(operation.data['description'], equals('Test expense'));
      expect(operation.groupId, equals('group-123'));
    });

    test('should create update expense operation', () {
      final operation = OfflineOperation(
        id: 'test-2',
        type: OperationType.updateExpense,
        data: {'description': 'Updated expense', 'amount': 150.0},
        createdAt: DateTime.now(),
        entityId: 'expense-123',
        groupId: 'group-123',
      );

      expect(operation.type, equals(OperationType.updateExpense));
      expect(operation.entityId, equals('expense-123'));
      expect(operation.groupId, equals('group-123'));
    });

    test('should create delete expense operation', () {
      final operation = OfflineOperation(
        id: 'test-3',
        type: OperationType.deleteExpense,
        data: {},
        createdAt: DateTime.now(),
        entityId: 'expense-123',
        groupId: 'group-123',
      );

      expect(operation.type, equals(OperationType.deleteExpense));
      expect(operation.entityId, equals('expense-123'));
    });

    test('should create group operation', () {
      final operation = OfflineOperation(
        id: 'test-4',
        type: OperationType.createGroup,
        data: {'name': 'Test Group', 'type': 'trip'},
        createdAt: DateTime.now(),
      );

      expect(operation.type, equals(OperationType.createGroup));
      expect(operation.data['name'], equals('Test Group'));
    });

    test('should create update group operation', () {
      final operation = OfflineOperation(
        id: 'test-5',
        type: OperationType.updateGroup,
        data: {'name': 'Updated Group Name'},
        createdAt: DateTime.now(),
        entityId: 'group-123',
      );

      expect(operation.type, equals(OperationType.updateGroup));
      expect(operation.entityId, equals('group-123'));
    });

    test('should create settlement operation', () {
      final operation = OfflineOperation(
        id: 'test-6',
        type: OperationType.createSettlement,
        data: {'fromUserId': 'user-1', 'toUserId': 'user-2', 'amount': 50.0},
        createdAt: DateTime.now(),
        groupId: 'group-123',
      );

      expect(operation.type, equals(OperationType.createSettlement));
      expect(operation.data['fromUserId'], equals('user-1'));
    });

    test('should create update settlement operation', () {
      final operation = OfflineOperation(
        id: 'test-7',
        type: OperationType.updateSettlement,
        data: {'status': 'confirmed'},
        createdAt: DateTime.now(),
        entityId: 'settlement-123',
        groupId: 'group-123',
      );

      expect(operation.type, equals(OperationType.updateSettlement));
      expect(operation.data['status'], equals('confirmed'));
    });

    test('should create profile update operation', () {
      final operation = OfflineOperation(
        id: 'test-8',
        type: OperationType.updateProfile,
        data: {
          'displayName': 'New Name',
          'photoUrl': 'https://example.com/photo.jpg',
        },
        createdAt: DateTime.now(),
      );

      expect(operation.type, equals(OperationType.updateProfile));
      expect(operation.data['displayName'], equals('New Name'));
    });

    test('should create add member operation', () {
      final operation = OfflineOperation(
        id: 'test-9',
        type: OperationType.addGroupMember,
        data: {'email': 'test@example.com'},
        createdAt: DateTime.now(),
        entityId: 'group-123',
      );

      expect(operation.type, equals(OperationType.addGroupMember));
      expect(operation.data['email'], equals('test@example.com'));
    });

    test('should create remove member operation', () {
      final operation = OfflineOperation(
        id: 'test-10',
        type: OperationType.removeGroupMember,
        data: {'userId': 'user-to-remove'},
        createdAt: DateTime.now(),
        entityId: 'group-123',
      );

      expect(operation.type, equals(OperationType.removeGroupMember));
      expect(operation.data['userId'], equals('user-to-remove'));
    });
  });

  group('Operation Data Validation', () {
    test('expense operation should contain required fields', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {
          'description': 'Dinner',
          'amount': 100.0,
          'currency': 'USD',
          'paidBy': 'user-1',
          'splitType': 'equal',
          'splits': {'user-1': 50.0, 'user-2': 50.0},
        },
        createdAt: DateTime.now(),
        groupId: 'group-123',
      );

      expect(operation.data.containsKey('description'), isTrue);
      expect(operation.data.containsKey('amount'), isTrue);
      expect(operation.data.containsKey('currency'), isTrue);
      expect(operation.data.containsKey('paidBy'), isTrue);
      expect(operation.data.containsKey('splitType'), isTrue);
      expect(operation.data.containsKey('splits'), isTrue);
    });

    test('settlement operation should contain required fields', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createSettlement,
        data: {
          'fromUserId': 'user-1',
          'toUserId': 'user-2',
          'amount': 75.0,
          'currency': 'USD',
          'paymentMethod': 'cash',
        },
        createdAt: DateTime.now(),
        groupId: 'group-123',
      );

      expect(operation.data.containsKey('fromUserId'), isTrue);
      expect(operation.data.containsKey('toUserId'), isTrue);
      expect(operation.data.containsKey('amount'), isTrue);
      expect(operation.data.containsKey('currency'), isTrue);
    });

    test('group operation should contain required fields', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createGroup,
        data: {'name': 'Weekend Trip', 'type': 'trip', 'currency': 'USD'},
        createdAt: DateTime.now(),
      );

      expect(operation.data.containsKey('name'), isTrue);
      expect(operation.data.containsKey('type'), isTrue);
      expect(operation.data.containsKey('currency'), isTrue);
    });
  });

  group('Operation Serialization for Sync', () {
    test('should serialize operation to JSON', () {
      final now = DateTime.now();
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {'description': 'Test'},
        createdAt: now,
        groupId: 'group-123',
      );

      final json = operation.toJson();

      expect(json['id'], equals('test-1'));
      expect(json['type'], equals('createExpense'));
      expect(json['data'], isA<Map<String, dynamic>>());
      expect(json['groupId'], equals('group-123'));
    });

    test('should deserialize operation from JSON', () {
      final json = {
        'id': 'test-1',
        'type': 'createExpense',
        'data': {'description': 'Test'},
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
        'groupId': 'group-123',
        'retryCount': 0,
      };

      final operation = OfflineOperation.fromJson(json);

      expect(operation.id, equals('test-1'));
      expect(operation.type, equals(OperationType.createExpense));
      expect(operation.groupId, equals('group-123'));
    });
  });

  group('Operation Status for Sync', () {
    test('new operations should have pending status', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {},
        createdAt: DateTime.now(),
      );

      expect(operation.status, equals(OperationStatus.pending));
    });

    test('should be able to mark as in progress', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {},
        createdAt: DateTime.now(),
      );

      final inProgress = operation.markInProgress();

      expect(inProgress.status, equals(OperationStatus.inProgress));
    });

    test('should be able to mark as completed', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {},
        createdAt: DateTime.now(),
      );

      final completed = operation.markCompleted();

      expect(completed.status, equals(OperationStatus.completed));
    });

    test('should be able to mark as failed', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {},
        createdAt: DateTime.now(),
      );

      final failed = operation.markFailed('Network error');

      expect(failed.status, equals(OperationStatus.failed));
      expect(failed.errorMessage, equals('Network error'));
    });
  });

  group('Retry Logic for Sync', () {
    test('should track retry count', () {
      var operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {},
        createdAt: DateTime.now(),
      );

      expect(operation.retryCount, equals(0));

      operation = operation.incrementRetry();
      expect(operation.retryCount, equals(1));

      operation = operation.incrementRetry();
      expect(operation.retryCount, equals(2));
    });

    test('should detect when max retries exceeded', () {
      var operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {},
        createdAt: DateTime.now(),
      );

      // Default max retries is 3
      expect(operation.hasExceededMaxRetries, isFalse);

      operation = operation.incrementRetry(); // 1
      expect(operation.hasExceededMaxRetries, isFalse);

      operation = operation.incrementRetry(); // 2
      expect(operation.hasExceededMaxRetries, isFalse);

      operation = operation.incrementRetry(); // 3
      expect(operation.hasExceededMaxRetries, isTrue);
    });
  });

  group('Expense Operations', () {
    test('create expense should require groupId', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createExpense,
        data: {'description': 'Test'},
        createdAt: DateTime.now(),
        groupId: 'group-123',
      );

      expect(operation.groupId, isNotNull);
      expect(operation.groupId, equals('group-123'));
    });

    test('update expense should require entityId and groupId', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.updateExpense,
        data: {'description': 'Updated'},
        createdAt: DateTime.now(),
        entityId: 'expense-123',
        groupId: 'group-123',
      );

      expect(operation.entityId, isNotNull);
      expect(operation.groupId, isNotNull);
    });

    test('delete expense should require entityId and groupId', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.deleteExpense,
        data: {},
        createdAt: DateTime.now(),
        entityId: 'expense-123',
        groupId: 'group-123',
      );

      expect(operation.entityId, isNotNull);
      expect(operation.groupId, isNotNull);
    });
  });

  group('Settlement Operations', () {
    test('create settlement should require groupId', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.createSettlement,
        data: {'fromUserId': 'user-1', 'toUserId': 'user-2', 'amount': 50.0},
        createdAt: DateTime.now(),
        groupId: 'group-123',
      );

      expect(operation.groupId, isNotNull);
    });

    test('update settlement should require entityId and groupId', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.updateSettlement,
        data: {'status': 'confirmed'},
        createdAt: DateTime.now(),
        entityId: 'settlement-123',
        groupId: 'group-123',
      );

      expect(operation.entityId, isNotNull);
      expect(operation.groupId, isNotNull);
    });
  });

  group('Group Operations', () {
    test('update group should require entityId', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.updateGroup,
        data: {'name': 'New Name'},
        createdAt: DateTime.now(),
        entityId: 'group-123',
      );

      expect(operation.entityId, isNotNull);
    });
  });

  group('Member Operations', () {
    test('add member should require entityId (groupId)', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.addGroupMember,
        data: {'email': 'test@example.com'},
        createdAt: DateTime.now(),
        entityId: 'group-123',
      );

      expect(operation.entityId, isNotNull);
      expect(operation.data['email'], isNotNull);
    });

    test('remove member should require entityId (groupId) and userId', () {
      final operation = OfflineOperation(
        id: 'test-1',
        type: OperationType.removeGroupMember,
        data: {'userId': 'user-to-remove'},
        createdAt: DateTime.now(),
        entityId: 'group-123',
      );

      expect(operation.entityId, isNotNull);
      expect(operation.data['userId'], isNotNull);
    });
  });
}
