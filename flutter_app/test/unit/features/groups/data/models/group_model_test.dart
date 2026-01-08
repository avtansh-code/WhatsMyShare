import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whats_my_share/features/groups/data/models/group_model.dart';
import 'package:whats_my_share/features/groups/domain/entities/group_entity.dart';

void main() {
  group('GroupMemberModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('fromMap', () {
      test('creates GroupMemberModel from valid map', () {
        // Arrange
        final map = {
          'userId': 'user-123',
          'displayName': 'John Doe',
          'photoUrl': 'https://example.com/photo.jpg',
          'email': 'john@example.com',
          'joinedAt': Timestamp.fromDate(testDate),
          'role': 'admin',
        };

        // Act
        final result = GroupMemberModel.fromMap(map);

        // Assert
        expect(result.userId, 'user-123');
        expect(result.displayName, 'John Doe');
        expect(result.photoUrl, 'https://example.com/photo.jpg');
        expect(result.email, 'john@example.com');
        expect(result.joinedAt, testDate);
        expect(result.role, MemberRole.admin);
      });

      test('parses member role correctly', () {
        // Arrange
        final memberMap = {
          'userId': 'user-123',
          'displayName': 'John Doe',
          'email': 'john@example.com',
          'joinedAt': Timestamp.fromDate(testDate),
          'role': 'member',
        };

        // Act
        final result = GroupMemberModel.fromMap(memberMap);

        // Assert
        expect(result.role, MemberRole.member);
      });

      test('defaults to member role for unknown role', () {
        // Arrange
        final map = {
          'userId': 'user-123',
          'displayName': 'John Doe',
          'email': 'john@example.com',
          'joinedAt': Timestamp.fromDate(testDate),
          'role': 'unknown_role',
        };

        // Act
        final result = GroupMemberModel.fromMap(map);

        // Assert
        expect(result.role, MemberRole.member);
      });
    });

    group('toMap', () {
      test('converts GroupMemberModel to map', () {
        // Arrange
        final model = GroupMemberModel(
          userId: 'user-123',
          displayName: 'John Doe',
          photoUrl: 'https://example.com/photo.jpg',
          email: 'john@example.com',
          joinedAt: testDate,
          role: MemberRole.admin,
        );

        // Act
        final result = model.toMap();

        // Assert
        expect(result['userId'], 'user-123');
        expect(result['displayName'], 'John Doe');
        expect(result['photoUrl'], 'https://example.com/photo.jpg');
        expect(result['email'], 'john@example.com');
        expect(result['joinedAt'], isA<Timestamp>());
        expect(result['role'], 'admin');
      });

      test('converts member role to string', () {
        // Arrange
        final model = GroupMemberModel(
          userId: 'user-123',
          displayName: 'John Doe',
          email: 'john@example.com',
          joinedAt: testDate,
          role: MemberRole.member,
        );

        // Act
        final result = model.toMap();

        // Assert
        expect(result['role'], 'member');
      });
    });

    group('fromEntity', () {
      test('creates GroupMemberModel from GroupMember entity', () {
        // Arrange
        final entity = GroupMember(
          userId: 'user-456',
          displayName: 'Jane Doe',
          photoUrl: 'https://example.com/jane.jpg',
          email: 'jane@example.com',
          joinedAt: testDate,
          role: MemberRole.admin,
        );

        // Act
        final result = GroupMemberModel.fromEntity(entity);

        // Assert
        expect(result, isA<GroupMemberModel>());
        expect(result.userId, entity.userId);
        expect(result.displayName, entity.displayName);
        expect(result.photoUrl, entity.photoUrl);
        expect(result.email, entity.email);
        expect(result.joinedAt, entity.joinedAt);
        expect(result.role, entity.role);
      });
    });
  });

  group('SimplifiedDebtModel', () {
    group('fromMap', () {
      test('creates SimplifiedDebtModel from valid map', () {
        // Arrange
        final map = {
          'from': 'user-1',
          'fromName': 'Alice',
          'to': 'user-2',
          'toName': 'Bob',
          'amount': 5000,
        };

        // Act
        final result = SimplifiedDebtModel.fromMap(map);

        // Assert
        expect(result.fromUserId, 'user-1');
        expect(result.fromUserName, 'Alice');
        expect(result.toUserId, 'user-2');
        expect(result.toUserName, 'Bob');
        expect(result.amount, 5000);
      });

      test('handles missing names', () {
        // Arrange
        final map = {'from': 'user-1', 'to': 'user-2', 'amount': 5000};

        // Act
        final result = SimplifiedDebtModel.fromMap(map);

        // Assert
        expect(result.fromUserName, '');
        expect(result.toUserName, '');
      });
    });

    group('toMap', () {
      test('converts SimplifiedDebtModel to map', () {
        // Arrange
        const model = SimplifiedDebtModel(
          fromUserId: 'user-1',
          fromUserName: 'Alice',
          toUserId: 'user-2',
          toUserName: 'Bob',
          amount: 5000,
        );

        // Act
        final result = model.toMap();

        // Assert
        expect(result['from'], 'user-1');
        expect(result['fromName'], 'Alice');
        expect(result['to'], 'user-2');
        expect(result['toName'], 'Bob');
        expect(result['amount'], 5000);
      });
    });

    group('fromEntity', () {
      test('creates SimplifiedDebtModel from SimplifiedDebt entity', () {
        // Arrange
        const entity = SimplifiedDebt(
          fromUserId: 'user-1',
          fromUserName: 'Alice',
          toUserId: 'user-2',
          toUserName: 'Bob',
          amount: 5000,
        );

        // Act
        final result = SimplifiedDebtModel.fromEntity(entity);

        // Assert
        expect(result, isA<SimplifiedDebtModel>());
        expect(result.fromUserId, entity.fromUserId);
        expect(result.fromUserName, entity.fromUserName);
        expect(result.toUserId, entity.toUserId);
        expect(result.toUserName, entity.toUserName);
        expect(result.amount, entity.amount);
      });
    });
  });

  group('GroupEntity', () {
    final testDate = DateTime(2024, 1, 15);
    final testMember = GroupMember(
      userId: 'user-1',
      displayName: 'Alice',
      email: 'alice@example.com',
      joinedAt: testDate,
      role: MemberRole.admin,
    );

    final testGroup = GroupEntity(
      id: 'group-123',
      name: 'Trip to Paris',
      description: 'Our vacation expenses',
      type: GroupType.trip,
      members: [testMember],
      memberIds: ['user-1', 'user-2'],
      memberCount: 2,
      currency: 'EUR',
      simplifyDebts: true,
      createdBy: 'user-1',
      admins: ['user-1'],
      createdAt: testDate,
      updatedAt: testDate,
      totalExpenses: 100000,
      expenseCount: 5,
      balances: {'user-1': 5000, 'user-2': -5000},
    );

    group('typeIcon', () {
      test('returns correct icon for trip', () {
        expect(testGroup.typeIcon, '✈️');
      });

      test('returns correct icon for home', () {
        final homeGroup = testGroup.copyWith(type: GroupType.home);
        expect(homeGroup.typeIcon, '🏠');
      });

      test('returns correct icon for couple', () {
        final coupleGroup = testGroup.copyWith(type: GroupType.couple);
        expect(coupleGroup.typeIcon, '💑');
      });

      test('returns correct icon for other', () {
        final otherGroup = testGroup.copyWith(type: GroupType.other);
        expect(otherGroup.typeIcon, '👥');
      });
    });

    group('typeDisplayName', () {
      test('returns Trip for trip type', () {
        expect(testGroup.typeDisplayName, 'Trip');
      });

      test('returns Home for home type', () {
        final homeGroup = testGroup.copyWith(type: GroupType.home);
        expect(homeGroup.typeDisplayName, 'Home');
      });

      test('returns Couple for couple type', () {
        final coupleGroup = testGroup.copyWith(type: GroupType.couple);
        expect(coupleGroup.typeDisplayName, 'Couple');
      });

      test('returns Other for other type', () {
        final otherGroup = testGroup.copyWith(type: GroupType.other);
        expect(otherGroup.typeDisplayName, 'Other');
      });
    });

    group('isUserAdmin', () {
      test('returns true for admin user', () {
        expect(testGroup.isUserAdmin('user-1'), isTrue);
      });

      test('returns false for non-admin user', () {
        expect(testGroup.isUserAdmin('user-2'), isFalse);
      });
    });

    group('isUserCreator', () {
      test('returns true for creator', () {
        expect(testGroup.isUserCreator('user-1'), isTrue);
      });

      test('returns false for non-creator', () {
        expect(testGroup.isUserCreator('user-2'), isFalse);
      });
    });

    group('isUserMember', () {
      test('returns true for member', () {
        expect(testGroup.isUserMember('user-1'), isTrue);
        expect(testGroup.isUserMember('user-2'), isTrue);
      });

      test('returns false for non-member', () {
        expect(testGroup.isUserMember('user-999'), isFalse);
      });
    });

    group('getMember', () {
      test('returns member when found', () {
        final member = testGroup.getMember('user-1');
        expect(member, isNotNull);
        expect(member!.userId, 'user-1');
      });

      test('returns null when not found', () {
        final member = testGroup.getMember('user-999');
        expect(member, isNull);
      });
    });

    group('getBalanceForUser', () {
      test('returns correct balance for user', () {
        expect(testGroup.getBalanceForUser('user-1'), 5000);
        expect(testGroup.getBalanceForUser('user-2'), -5000);
      });

      test('returns 0 for user not in balances', () {
        expect(testGroup.getBalanceForUser('user-999'), 0);
      });
    });

    group('doesUserOwe', () {
      test('returns true for negative balance', () {
        expect(testGroup.doesUserOwe('user-2'), isTrue);
      });

      test('returns false for positive balance', () {
        expect(testGroup.doesUserOwe('user-1'), isFalse);
      });

      test('returns false for zero balance', () {
        final groupWithZero = testGroup.copyWith(
          balances: {'user-1': 0, 'user-2': 0},
        );
        expect(groupWithZero.doesUserOwe('user-1'), isFalse);
      });
    });

    group('isUserOwed', () {
      test('returns true for positive balance', () {
        expect(testGroup.isUserOwed('user-1'), isTrue);
      });

      test('returns false for negative balance', () {
        expect(testGroup.isUserOwed('user-2'), isFalse);
      });
    });

    group('isUserSettled', () {
      test('returns true for zero balance', () {
        final groupWithZero = testGroup.copyWith(balances: {'user-1': 0});
        expect(groupWithZero.isUserSettled('user-1'), isTrue);
      });

      test('returns false for non-zero balance', () {
        expect(testGroup.isUserSettled('user-1'), isFalse);
      });
    });

    group('getTotalOwedByUser', () {
      test('returns amount for negative balance', () {
        expect(testGroup.getTotalOwedByUser('user-2'), 5000);
      });

      test('returns 0 for positive balance', () {
        expect(testGroup.getTotalOwedByUser('user-1'), 0);
      });
    });

    group('getTotalOwedToUser', () {
      test('returns amount for positive balance', () {
        expect(testGroup.getTotalOwedToUser('user-1'), 5000);
      });

      test('returns 0 for negative balance', () {
        expect(testGroup.getTotalOwedToUser('user-2'), 0);
      });
    });

    group('copyWith', () {
      test('creates copy with updated name', () {
        final copy = testGroup.copyWith(name: 'New Name');
        expect(copy.name, 'New Name');
        expect(copy.id, testGroup.id);
      });

      test('creates copy with updated type', () {
        final copy = testGroup.copyWith(type: GroupType.home);
        expect(copy.type, GroupType.home);
      });

      test('creates copy with updated balances', () {
        final copy = testGroup.copyWith(
          balances: {'user-1': 10000, 'user-2': -10000},
        );
        expect(copy.balances['user-1'], 10000);
      });
    });
  });

  group('GroupMember', () {
    group('isAdmin', () {
      test('returns true for admin role', () {
        final member = GroupMember(
          userId: 'user-1',
          displayName: 'John',
          email: 'john@example.com',
          joinedAt: DateTime.now(),
          role: MemberRole.admin,
        );
        expect(member.isAdmin, isTrue);
      });

      test('returns false for member role', () {
        final member = GroupMember(
          userId: 'user-1',
          displayName: 'John',
          email: 'john@example.com',
          joinedAt: DateTime.now(),
          role: MemberRole.member,
        );
        expect(member.isAdmin, isFalse);
      });
    });

    group('initials', () {
      test('returns first letter for single word name', () {
        final member = GroupMember(
          userId: 'user-1',
          displayName: 'John',
          email: 'john@example.com',
          joinedAt: DateTime.now(),
          role: MemberRole.member,
        );
        expect(member.initials, 'J');
      });

      test('returns first and last initials for two word name', () {
        final member = GroupMember(
          userId: 'user-1',
          displayName: 'John Doe',
          email: 'john@example.com',
          joinedAt: DateTime.now(),
          role: MemberRole.member,
        );
        expect(member.initials, 'JD');
      });

      test('returns first and last initials for multi-word name', () {
        final member = GroupMember(
          userId: 'user-1',
          displayName: 'John Middle Doe',
          email: 'john@example.com',
          joinedAt: DateTime.now(),
          role: MemberRole.member,
        );
        expect(member.initials, 'JD');
      });

      test('returns uppercase initials', () {
        final member = GroupMember(
          userId: 'user-1',
          displayName: 'john doe',
          email: 'john@example.com',
          joinedAt: DateTime.now(),
          role: MemberRole.member,
        );
        expect(member.initials, 'JD');
      });
    });
  });

  group('GroupModel', () {
    group('fromEntity', () {
      test('creates GroupModel from GroupEntity', () {
        // Arrange
        final testDate = DateTime(2024, 1, 15);
        final entity = GroupEntity(
          id: 'group-123',
          name: 'Test Group',
          description: 'Description',
          type: GroupType.trip,
          members: [],
          memberIds: ['user-1'],
          memberCount: 1,
          currency: 'USD',
          simplifyDebts: true,
          createdBy: 'user-1',
          admins: ['user-1'],
          createdAt: testDate,
          updatedAt: testDate,
          totalExpenses: 5000,
          expenseCount: 2,
          balances: {'user-1': 0},
        );

        // Act
        final result = GroupModel.fromEntity(entity);

        // Assert
        expect(result, isA<GroupModel>());
        expect(result.id, entity.id);
        expect(result.name, entity.name);
        expect(result.description, entity.description);
        expect(result.type, entity.type);
        expect(result.currency, entity.currency);
        expect(result.simplifyDebts, entity.simplifyDebts);
      });
    });

    group('toUpdateMap', () {
      test('includes only specified fields', () {
        // Arrange
        final testDate = DateTime(2024, 1, 15);
        final model = GroupModel(
          id: 'group-123',
          name: 'Test Group',
          type: GroupType.trip,
          members: [],
          memberIds: [],
          memberCount: 0,
          currency: 'USD',
          simplifyDebts: true,
          createdBy: 'user-1',
          admins: [],
          createdAt: testDate,
          updatedAt: testDate,
          totalExpenses: 0,
          expenseCount: 0,
          balances: {},
        );

        // Act
        final result = model.toUpdateMap(name: 'Updated Name', currency: 'EUR');

        // Assert
        expect(result['name'], 'Updated Name');
        expect(result['currency'], 'EUR');
        expect(result.containsKey('updatedAt'), isTrue);
        expect(result.containsKey('description'), isFalse);
        expect(result.containsKey('type'), isFalse);
      });

      test('converts GroupType to string', () {
        // Arrange
        final testDate = DateTime(2024, 1, 15);
        final model = GroupModel(
          id: 'group-123',
          name: 'Test Group',
          type: GroupType.trip,
          members: [],
          memberIds: [],
          memberCount: 0,
          currency: 'USD',
          simplifyDebts: true,
          createdBy: 'user-1',
          admins: [],
          createdAt: testDate,
          updatedAt: testDate,
          totalExpenses: 0,
          expenseCount: 0,
          balances: {},
        );

        // Act
        final result = model.toUpdateMap(type: GroupType.home);

        // Assert
        expect(result['type'], 'home');
      });
    });
  });
}
