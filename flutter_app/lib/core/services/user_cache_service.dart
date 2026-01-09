import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'logging_service.dart';

/// Cached user information for display purposes
/// This is used to resolve user details from UIDs stored in friends/groups/expenses
class CachedUser {
  final String id;
  final String? displayName;
  final String? phone;
  final String? photoUrl;
  final DateTime cachedAt;

  const CachedUser({
    required this.id,
    this.displayName,
    this.phone,
    this.photoUrl,
    required this.cachedAt,
  });

  /// Get display name or fallback to phone suffix
  String get displayNameOrPhone {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (phone != null && phone!.length >= 4) {
      return '****${phone!.substring(phone!.length - 4)}';
    }
    return 'Unknown';
  }

  /// Get user initials for avatar
  String get initials {
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    if (phone != null && phone!.length >= 2) {
      return phone!.substring(phone!.length - 2);
    }
    return '??';
  }

  /// Check if cache is stale (older than 5 minutes)
  bool get isStale {
    return DateTime.now().difference(cachedAt).inMinutes > 5;
  }

  factory CachedUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return CachedUser(id: doc.id, cachedAt: DateTime.now());
    }
    return CachedUser(
      id: doc.id,
      displayName: data['displayName'] as String?,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
      cachedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'phone': phone,
      'photoUrl': photoUrl,
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  factory CachedUser.fromMap(Map<String, dynamic> map) {
    return CachedUser(
      id: map['id'] as String,
      displayName: map['displayName'] as String?,
      phone: map['phone'] as String?,
      photoUrl: map['photoUrl'] as String?,
      cachedAt: DateTime.parse(map['cachedAt'] as String),
    );
  }

  CachedUser copyWith({
    String? id,
    String? displayName,
    String? phone,
    String? photoUrl,
    DateTime? cachedAt,
  }) {
    return CachedUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}

/// Service to cache and resolve user information from UIDs
/// This is the central service for looking up user details across the app
class UserCacheService {
  final FirebaseFirestore _firestore;
  final LoggingService _log = LoggingService();

  /// In-memory cache of user data
  final Map<String, CachedUser> _cache = {};

  /// Pending fetch operations to avoid duplicate requests
  final Map<String, Completer<CachedUser?>> _pendingFetches = {};

  /// Stream controllers for real-time user updates
  final Map<String, StreamController<CachedUser>> _userStreams = {};

  UserCacheService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _log.debug('UserCacheService initialized', tag: LogTags.cache);
  }

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get a cached user by ID, fetching from Firestore if not cached or stale
  Future<CachedUser?> getUser(String userId) async {
    if (userId.isEmpty) return null;

    // Check in-memory cache first
    final cached = _cache[userId];
    if (cached != null && !cached.isStale) {
      _log.debug(
        'User found in cache',
        tag: LogTags.cache,
        data: {'userId': userId},
      );
      return cached;
    }

    // Check if there's already a pending fetch for this user
    if (_pendingFetches.containsKey(userId)) {
      _log.debug(
        'Waiting for pending fetch',
        tag: LogTags.cache,
        data: {'userId': userId},
      );
      return _pendingFetches[userId]!.future;
    }

    // Start a new fetch
    final completer = Completer<CachedUser?>();
    _pendingFetches[userId] = completer;

    try {
      _log.debug(
        'Fetching user from Firestore',
        tag: LogTags.cache,
        data: {'userId': userId},
      );

      final doc = await _usersCollection.doc(userId).get();

      CachedUser? user;
      if (doc.exists) {
        user = CachedUser.fromFirestore(doc);
        _cache[userId] = user;
        _log.debug(
          'User cached successfully',
          tag: LogTags.cache,
          data: {'userId': userId, 'displayName': user.displayName},
        );
      } else {
        _log.warning(
          'User not found in Firestore',
          tag: LogTags.cache,
          data: {'userId': userId},
        );
      }

      completer.complete(user);
      return user;
    } catch (e) {
      _log.error(
        'Failed to fetch user',
        tag: LogTags.cache,
        data: {'userId': userId, 'error': e.toString()},
      );
      completer.complete(null);
      return null;
    } finally {
      _pendingFetches.remove(userId);
    }
  }

  /// Get multiple users by IDs (batch fetch)
  Future<Map<String, CachedUser>> getUsers(List<String> userIds) async {
    if (userIds.isEmpty) return {};

    final result = <String, CachedUser>{};
    final toFetch = <String>[];

    // Check cache first
    for (final userId in userIds) {
      if (userId.isEmpty) continue;

      final cached = _cache[userId];
      if (cached != null && !cached.isStale) {
        result[userId] = cached;
      } else {
        toFetch.add(userId);
      }
    }

    if (toFetch.isEmpty) {
      _log.debug(
        'All users found in cache',
        tag: LogTags.cache,
        data: {'count': result.length},
      );
      return result;
    }

    _log.debug(
      'Batch fetching users from Firestore',
      tag: LogTags.cache,
      data: {'count': toFetch.length, 'cached': result.length},
    );

    // Batch fetch from Firestore (max 10 at a time due to Firestore limits)
    for (var i = 0; i < toFetch.length; i += 10) {
      final batch = toFetch.skip(i).take(10).toList();

      try {
        final snapshots = await Future.wait(
          batch.map((id) => _usersCollection.doc(id).get()),
        );

        for (final doc in snapshots) {
          if (doc.exists) {
            final user = CachedUser.fromFirestore(doc);
            _cache[doc.id] = user;
            result[doc.id] = user;
          }
        }
      } catch (e) {
        _log.error(
          'Failed to batch fetch users',
          tag: LogTags.cache,
          data: {'error': e.toString()},
        );
      }
    }

    return result;
  }

  /// Watch a user for real-time updates
  Stream<CachedUser> watchUser(String userId) {
    if (_userStreams.containsKey(userId)) {
      return _userStreams[userId]!.stream;
    }

    final controller = StreamController<CachedUser>.broadcast(
      onCancel: () {
        _userStreams[userId]?.close();
        _userStreams.remove(userId);
      },
    );

    _userStreams[userId] = controller;

    _usersCollection
        .doc(userId)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              final user = CachedUser.fromFirestore(doc);
              _cache[userId] = user;
              controller.add(user);
            }
          },
          onError: (e) {
            _log.error(
              'Error watching user',
              tag: LogTags.cache,
              data: {'userId': userId, 'error': e.toString()},
            );
          },
        );

    return controller.stream;
  }

  /// Search for registered users by phone number
  Future<List<CachedUser>> searchUsersByPhone(String phone) async {
    if (phone.isEmpty || phone.length < 4) return [];

    _log.debug(
      'Searching users by phone',
      tag: LogTags.cache,
      data: {'phone': phone},
    );

    try {
      // Normalize phone number
      String normalizedPhone = phone;
      if (!phone.startsWith('+')) {
        normalizedPhone = '+91$phone'; // Default to India
      }

      final querySnapshot = await _usersCollection
          .where('phone', isEqualTo: normalizedPhone)
          .limit(10)
          .get();

      final users = querySnapshot.docs.map((doc) {
        final user = CachedUser.fromFirestore(doc);
        _cache[user.id] = user;
        return user;
      }).toList();

      _log.debug(
        'Phone search completed',
        tag: LogTags.cache,
        data: {'phone': phone, 'results': users.length},
      );

      return users;
    } catch (e) {
      _log.error(
        'Failed to search users by phone',
        tag: LogTags.cache,
        data: {'phone': phone, 'error': e.toString()},
      );
      return [];
    }
  }

  /// Search for registered users by display name
  Future<List<CachedUser>> searchUsersByName(String name) async {
    if (name.isEmpty || name.length < 2) return [];

    _log.debug(
      'Searching users by name',
      tag: LogTags.cache,
      data: {'name': name},
    );

    try {
      final queryLower = name.toLowerCase();

      final querySnapshot = await _usersCollection
          .where('displayNameLower', isGreaterThanOrEqualTo: queryLower)
          .where('displayNameLower', isLessThanOrEqualTo: '$queryLower\uf8ff')
          .limit(10)
          .get();

      final users = querySnapshot.docs.map((doc) {
        final user = CachedUser.fromFirestore(doc);
        _cache[user.id] = user;
        return user;
      }).toList();

      _log.debug(
        'Name search completed',
        tag: LogTags.cache,
        data: {'name': name, 'results': users.length},
      );

      return users;
    } catch (e) {
      _log.error(
        'Failed to search users by name',
        tag: LogTags.cache,
        data: {'name': name, 'error': e.toString()},
      );
      return [];
    }
  }

  /// Get user by phone number (exact match)
  Future<CachedUser?> getUserByPhone(String phone) async {
    if (phone.isEmpty) return null;

    _log.debug(
      'Getting user by phone',
      tag: LogTags.cache,
      data: {'phone': phone},
    );

    // Check cache first
    for (final user in _cache.values) {
      if (user.phone == phone && !user.isStale) {
        return user;
      }
    }

    try {
      String normalizedPhone = phone;
      if (!phone.startsWith('+')) {
        normalizedPhone = '+91$phone';
      }

      final querySnapshot = await _usersCollection
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _log.debug(
          'User not found by phone',
          tag: LogTags.cache,
          data: {'phone': phone},
        );
        return null;
      }

      final user = CachedUser.fromFirestore(querySnapshot.docs.first);
      _cache[user.id] = user;
      return user;
    } catch (e) {
      _log.error(
        'Failed to get user by phone',
        tag: LogTags.cache,
        data: {'phone': phone, 'error': e.toString()},
      );
      return null;
    }
  }

  /// Update cache when a user profile changes
  void updateCache(String userId, CachedUser user) {
    _cache[userId] = user;
    _log.debug(
      'Cache updated for user',
      tag: LogTags.cache,
      data: {'userId': userId},
    );
  }

  /// Invalidate cache for a specific user
  void invalidateUser(String userId) {
    _cache.remove(userId);
    _log.debug(
      'Cache invalidated for user',
      tag: LogTags.cache,
      data: {'userId': userId},
    );
  }

  /// Clear entire cache
  void clearCache() {
    _cache.clear();
    _log.debug('Cache cleared', tag: LogTags.cache);
  }

  /// Get cache size
  int get cacheSize => _cache.length;

  /// Get cached display name (synchronous, for UI display)
  /// Returns user ID suffix if not cached
  String getCachedDisplayName(String userId) {
    final cached = _cache[userId];
    if (cached != null &&
        cached.displayName != null &&
        cached.displayName!.isNotEmpty) {
      return cached.displayName!;
    }
    // Return masked ID if not cached
    if (userId.length >= 4) {
      return '****${userId.substring(userId.length - 4)}';
    }
    return 'Unknown';
  }

  /// Get cached photo URL (synchronous, for UI display)
  /// Returns null if not cached
  String? getCachedPhotoUrl(String userId) {
    return _cache[userId]?.photoUrl;
  }

  /// Get cached phone (synchronous, for UI display)
  /// Returns null if not cached
  String? getCachedPhone(String userId) {
    return _cache[userId]?.phone;
  }

  /// Dispose of resources
  void dispose() {
    for (final controller in _userStreams.values) {
      controller.close();
    }
    _userStreams.clear();
    _cache.clear();
    _log.debug('UserCacheService disposed', tag: LogTags.cache);
  }
}
