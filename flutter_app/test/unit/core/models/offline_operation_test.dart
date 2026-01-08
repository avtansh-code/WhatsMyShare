import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/core/models/offline_operation.dart';

void main() {
  group('OfflineOperation', () {
    final testDateTime = DateTime(2026, 1, 9, 12, 0, 0);
    final testData = {'description': 'Test expense', 'amount': 1000};

    final testOperation = OfflineOperation(
      id: 'op123',
      type: OperationType.createExpense,
      data: testData,
      createdAt: testDateTime,
      retryCount: 0,
      status: OperationStatus.pending,
      entityId: 'expense123',
      groupId: 'group123',
    );

    group('constructor', () {
      test('creates OfflineOperation with all fields', () {
        expect(testOperation.id, 'op123');
        expect(testOperation.type, OperationType.createExpense);
        expect(testOperation.data, testData);
        expect(testOperation.createdAt, testDateTime);
        expect(testOperation.retryCount, 0);
        expect(testOperation.status, OperationStatus.pending);
        expect(testOperation.entityId, 'expense123');
        expect(testOperation.groupId, 'group123');
        expect(testOperation.errorMessage, isNull);
      });

      test('creates OfflineOperation with default values', () {
        final minimalOperation = OfflineOperation(
          id: 'op123',
          type: OperationType.createExpense,
          data: testData,
          createdAt: testDateTime,
        );

        expect(minimalOperation.retryCount, 0);
        expect(minimalOperation.status, OperationStatus.pending);
        expect(minimalOperation.errorMessage, isNull);
        expect(minimalOperation.entityId, isNull);
        expect(minimalOperation.groupId, isNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated id', () {
        final copy = testOperation.copyWith(id: 'newId');

        expect(copy.id, 'newId');
        expect(copy.type, testOperation.type);
        expect(copy.data, testOperation.data);
      });

      test('creates copy with updated type', () {
        final copy = testOperation.copyWith(type: OperationType.updateExpense);

        expect(copy.type, OperationType.updateExpense);
        expect(copy.id, testOperation.id);
      });

      test('creates copy with updated status', () {
        final copy = testOperation.copyWith(status: OperationStatus.inProgress);

        expect(copy.status, OperationStatus.inProgress);
      });

      test('creates copy with updated retryCount', () {
        final copy = testOperation.copyWith(retryCount: 2);

        expect(copy.retryCount, 2);
      });

      test('creates copy with updated errorMessage', () {
        final copy = testOperation.copyWith(errorMessage: 'Network error');

        expect(copy.errorMessage, 'Network error');
      });

      test('preserves original values when not updated', () {
        final copy = testOperation.copyWith(id: 'newId');

        expect(copy.type, testOperation.type);
        expect(copy.data, testOperation.data);
        expect(copy.createdAt, testOperation.createdAt);
        expect(copy.retryCount, testOperation.retryCount);
        expect(copy.status, testOperation.status);
        expect(copy.entityId, testOperation.entityId);
        expect(copy.groupId, testOperation.groupId);
      });
    });

    group('incrementRetry', () {
      test('increments retry count by 1', () {
        final incremented = testOperation.incrementRetry();

        expect(incremented.retryCount, 1);
      });

      test('increments multiple times', () {
        final first = testOperation.incrementRetry();
        final second = first.incrementRetry();
        final third = second.incrementRetry();

        expect(third.retryCount, 3);
      });

      test('preserves other fields when incrementing', () {
        final incremented = testOperation.incrementRetry();

        expect(incremented.id, testOperation.id);
        expect(incremented.type, testOperation.type);
        expect(incremented.data, testOperation.data);
        expect(incremented.status, testOperation.status);
      });
    });

    group('markInProgress', () {
      test('sets status to inProgress', () {
        final inProgress = testOperation.markInProgress();

        expect(inProgress.status, OperationStatus.inProgress);
      });

      test('preserves other fields', () {
        final inProgress = testOperation.markInProgress();

        expect(inProgress.id, testOperation.id);
        expect(inProgress.type, testOperation.type);
        expect(inProgress.retryCount, testOperation.retryCount);
      });
    });

    group('markCompleted', () {
      test('sets status to completed', () {
        final completed = testOperation.markCompleted();

        expect(completed.status, OperationStatus.completed);
      });

      test('preserves other fields', () {
        final completed = testOperation.markCompleted();

        expect(completed.id, testOperation.id);
        expect(completed.type, testOperation.type);
      });
    });

    group('markFailed', () {
      test('sets status to failed with error message', () {
        final failed = testOperation.markFailed('Network timeout');

        expect(failed.status, OperationStatus.failed);
        expect(failed.errorMessage, 'Network timeout');
      });

      test('preserves other fields', () {
        final failed = testOperation.markFailed('Error');

        expect(failed.id, testOperation.id);
        expect(failed.type, testOperation.type);
        expect(failed.retryCount, testOperation.retryCount);
      });
    });

    group('hasExceededMaxRetries', () {
      test('returns false when retryCount is less than maxRetries', () {
        expect(testOperation.hasExceededMaxRetries, false);
      });

      test('returns false when retryCount is 2', () {
        final op = testOperation.copyWith(retryCount: 2);
        expect(op.hasExceededMaxRetries, false);
      });

      test('returns true when retryCount equals maxRetries', () {
        final op = testOperation.copyWith(retryCount: 3);
        expect(op.hasExceededMaxRetries, true);
      });

      test('returns true when retryCount exceeds maxRetries', () {
        final op = testOperation.copyWith(retryCount: 5);
        expect(op.hasExceededMaxRetries, true);
      });
    });

    group('maxRetries', () {
      test('maxRetries is 3', () {
        expect(OfflineOperation.maxRetries, 3);
      });
    });

    group('toJson', () {
      test('converts OfflineOperation to JSON map', () {
        final json = testOperation.toJson();

        expect(json['id'], 'op123');
        expect(json['type'], 'createExpense');
        expect(json['data'], testData);
        expect(json['createdAt'], testDateTime.toIso8601String());
        expect(json['retryCount'], 0);
        expect(json['status'], 'pending');
        expect(json['entityId'], 'expense123');
        expect(json['groupId'], 'group123');
        expect(json['errorMessage'], isNull);
      });

      test('includes errorMessage when present', () {
        final opWithError = testOperation.markFailed('Test error');
        final json = opWithError.toJson();

        expect(json['errorMessage'], 'Test error');
        expect(json['status'], 'failed');
      });

      test('converts all operation types correctly', () {
        for (final opType in OperationType.values) {
          final op = testOperation.copyWith(type: opType);
          final json = op.toJson();
          expect(json['type'], opType.name);
        }
      });

      test('converts all status types correctly', () {
        for (final status in OperationStatus.values) {
          final op = testOperation.copyWith(status: status);
          final json = op.toJson();
          expect(json['status'], status.name);
        }
      });
    });

    group('fromJson', () {
      test('creates OfflineOperation from JSON map', () {
        final json = {
          'id': 'op123',
          'type': 'createExpense',
          'data': testData,
          'createdAt': testDateTime.toIso8601String(),
          'retryCount': 1,
          'status': 'pending',
          'entityId': 'expense123',
          'groupId': 'group123',
          'errorMessage': null,
        };

        final result = OfflineOperation.fromJson(json);

        expect(result.id, 'op123');
        expect(result.type, OperationType.createExpense);
        expect(result.data, testData);
        expect(result.createdAt, testDateTime);
        expect(result.retryCount, 1);
        expect(result.status, OperationStatus.pending);
        expect(result.entityId, 'expense123');
        expect(result.groupId, 'group123');
        expect(result.errorMessage, isNull);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 'op123',
          'type': 'createExpense',
          'data': testData,
          'createdAt': testDateTime.toIso8601String(),
        };

        final result = OfflineOperation.fromJson(json);

        expect(result.retryCount, 0);
        expect(result.status, OperationStatus.pending);
        expect(result.entityId, isNull);
        expect(result.groupId, isNull);
      });

      test('defaults to createExpense for unknown operation type', () {
        final json = {
          'id': 'op123',
          'type': 'unknownType',
          'data': testData,
          'createdAt': testDateTime.toIso8601String(),
        };

        final result = OfflineOperation.fromJson(json);

        expect(result.type, OperationType.createExpense);
      });

      test('defaults to pending for unknown status', () {
        final json = {
          'id': 'op123',
          'type': 'createExpense',
          'data': testData,
          'createdAt': testDateTime.toIso8601String(),
          'status': 'unknownStatus',
        };

        final result = OfflineOperation.fromJson(json);

        expect(result.status, OperationStatus.pending);
      });

      test('parses all operation types correctly', () {
        for (final opType in OperationType.values) {
          final json = {
            'id': 'op123',
            'type': opType.name,
            'data': testData,
            'createdAt': testDateTime.toIso8601String(),
          };

          final result = OfflineOperation.fromJson(json);
          expect(result.type, opType);
        }
      });

      test('parses all status types correctly', () {
        for (final status in OperationStatus.values) {
          final json = {
            'id': 'op123',
            'type': 'createExpense',
            'data': testData,
            'createdAt': testDateTime.toIso8601String(),
            'status': status.name,
          };

          final result = OfflineOperation.fromJson(json);
          expect(result.status, status);
        }
      });
    });

    group('roundtrip conversion', () {
      test('toJson -> fromJson preserves all data', () {
        final original = OfflineOperation(
          id: 'op123',
          type: OperationType.updateExpense,
          data: {'amount': 5000, 'description': 'Updated'},
          createdAt: testDateTime,
          retryCount: 2,
          status: OperationStatus.failed,
          errorMessage: 'Network error',
          entityId: 'entity123',
          groupId: 'group123',
        );

        final json = original.toJson();
        final restored = OfflineOperation.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.type, original.type);
        expect(restored.data, original.data);
        expect(restored.createdAt, original.createdAt);
        expect(restored.retryCount, original.retryCount);
        expect(restored.status, original.status);
        expect(restored.errorMessage, original.errorMessage);
        expect(restored.entityId, original.entityId);
        expect(restored.groupId, original.groupId);
      });
    });

    group('Equatable', () {
      test('equal operations have same props', () {
        final op1 = OfflineOperation(
          id: 'op123',
          type: OperationType.createExpense,
          data: testData,
          createdAt: testDateTime,
        );

        final op2 = OfflineOperation(
          id: 'op123',
          type: OperationType.createExpense,
          data: testData,
          createdAt: testDateTime,
        );

        expect(op1, equals(op2));
      });

      test('different operations are not equal', () {
        final op1 = OfflineOperation(
          id: 'op123',
          type: OperationType.createExpense,
          data: testData,
          createdAt: testDateTime,
        );

        final op2 = OfflineOperation(
          id: 'op456',
          type: OperationType.createExpense,
          data: testData,
          createdAt: testDateTime,
        );

        expect(op1, isNot(equals(op2)));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final str = testOperation.toString();

        expect(str, contains('op123'));
        expect(str, contains('createExpense'));
        expect(str, contains('pending'));
        expect(str, contains('0'));
      });
    });

    group('OperationType', () {
      test('has all expected operation types', () {
        expect(OperationType.values, contains(OperationType.createExpense));
        expect(OperationType.values, contains(OperationType.updateExpense));
        expect(OperationType.values, contains(OperationType.deleteExpense));
        expect(OperationType.values, contains(OperationType.createGroup));
        expect(OperationType.values, contains(OperationType.updateGroup));
        expect(OperationType.values, contains(OperationType.createSettlement));
        expect(OperationType.values, contains(OperationType.updateSettlement));
        expect(OperationType.values, contains(OperationType.updateProfile));
        expect(OperationType.values, contains(OperationType.addGroupMember));
        expect(OperationType.values, contains(OperationType.removeGroupMember));
      });

      test('has 10 operation types', () {
        expect(OperationType.values.length, 10);
      });
    });

    group('OperationStatus', () {
      test('has all expected status types', () {
        expect(OperationStatus.values, contains(OperationStatus.pending));
        expect(OperationStatus.values, contains(OperationStatus.inProgress));
        expect(OperationStatus.values, contains(OperationStatus.completed));
        expect(OperationStatus.values, contains(OperationStatus.failed));
      });

      test('has 4 status types', () {
        expect(OperationStatus.values.length, 4);
      });
    });
  });
}
