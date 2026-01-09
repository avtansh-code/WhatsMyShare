import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';

import '../errors/exceptions.dart';
import 'logging_service.dart';

/// Service for client-side encryption of files (images, audio, etc.)
/// Uses AES-256-GCM for encryption with per-user keys stored securely on device.
///
/// Architecture:
/// - Each user has a unique master encryption key generated on first use
/// - Keys are stored in platform-secure storage (Keychain on iOS, Keystore on Android)
/// - Files are encrypted with AES-256-GCM before upload
/// - Files are decrypted after download, only on the device
/// - The key NEVER leaves the device, making cloud data unreadable to anyone
class EncryptionService {
  static const String _masterKeyStorageKey = 'user_encryption_master_key';
  static const String _keyVersionStorageKey = 'user_encryption_key_version';
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _ivLength = 12; // 96 bits for GCM recommended IV size
  // Note: GCM auth tag length is 128 bits (handled internally by encrypt package)

  final FlutterSecureStorage _secureStorage;
  final LoggingService _log = LoggingService();

  // Cache the key in memory to avoid frequent secure storage reads
  Uint8List? _cachedKey;
  int? _cachedKeyVersion;

  EncryptionService({FlutterSecureStorage? secureStorage})
    : _secureStorage =
          secureStorage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              encryptedSharedPreferences: true,
              keyCipherAlgorithm:
                  KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
              storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
            ),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          ) {
    _log.debug('EncryptionService initialized', tag: LogTags.encryption);
  }

  /// Initialize the encryption service for a user
  /// This should be called after user authentication
  Future<void> initialize(String userId) async {
    _log.info('Initializing encryption for user', tag: LogTags.encryption);
    try {
      // Try to load existing key
      final existingKey = await _loadMasterKey(userId);
      if (existingKey != null) {
        _cachedKey = existingKey;
        _cachedKeyVersion = await _loadKeyVersion(userId);
        _log.debug(
          'Loaded existing encryption key',
          tag: LogTags.encryption,
          data: {'keyVersion': _cachedKeyVersion},
        );
      } else {
        // Generate new key for first-time users
        await _generateAndStoreMasterKey(userId);
        _log.info(
          'Generated new encryption key for user',
          tag: LogTags.encryption,
        );
      }
    } catch (e) {
      _log.error(
        'Failed to initialize encryption',
        tag: LogTags.encryption,
        data: {'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Clear cached key on logout
  void clearCache() {
    _cachedKey = null;
    _cachedKeyVersion = null;
    _log.debug('Cleared encryption key cache', tag: LogTags.encryption);
  }

  /// Encrypt a file and return the encrypted bytes
  /// Returns: Encrypted data with prepended IV (IV + encrypted data + auth tag)
  Future<Uint8List> encryptFile(File file) async {
    _log.debug('Encrypting file', tag: LogTags.encryption);

    if (_cachedKey == null) {
      throw const EncryptionException(message: 'Encryption not initialized');
    }

    try {
      final plainBytes = await file.readAsBytes();
      return _encryptBytes(plainBytes);
    } catch (e) {
      _log.error(
        'File encryption failed',
        tag: LogTags.encryption,
        data: {'error': e.toString()},
      );
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        message: 'Failed to encrypt file: ${e.toString()}',
      );
    }
  }

  /// Encrypt bytes directly
  /// Returns: Encrypted data with prepended IV (IV + encrypted data + auth tag)
  Uint8List _encryptBytes(Uint8List plainBytes) {
    if (_cachedKey == null) {
      throw const EncryptionException(message: 'Encryption not initialized');
    }

    // Generate random IV for each encryption
    final iv = _generateRandomBytes(_ivLength);

    // Create AES-GCM cipher
    final key = encrypt.Key(Uint8List.fromList(_cachedKey!));
    final ivObj = encrypt.IV(iv);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    // Encrypt
    final encrypted = encrypter.encryptBytes(plainBytes, iv: ivObj);

    // Combine IV + encrypted data (includes auth tag in GCM mode)
    final result = Uint8List(_ivLength + encrypted.bytes.length);
    result.setRange(0, _ivLength, iv);
    result.setRange(_ivLength, result.length, encrypted.bytes);

    _log.debug(
      'Encryption complete',
      tag: LogTags.encryption,
      data: {'inputSize': plainBytes.length, 'outputSize': result.length},
    );

    return result;
  }

  /// Decrypt bytes from encrypted data
  /// Input format: IV (12 bytes) + encrypted data + auth tag
  Future<Uint8List> decryptBytes(Uint8List encryptedData) async {
    _log.debug('Decrypting data', tag: LogTags.encryption);

    if (_cachedKey == null) {
      throw const EncryptionException(message: 'Encryption not initialized');
    }

    if (encryptedData.length < _ivLength + 16) {
      // Minimum: IV + auth tag
      throw const EncryptionException(message: 'Invalid encrypted data format');
    }

    try {
      // Extract IV from the beginning
      final iv = encryptedData.sublist(0, _ivLength);
      final ciphertext = encryptedData.sublist(_ivLength);

      // Create AES-GCM cipher
      final key = encrypt.Key(Uint8List.fromList(_cachedKey!));
      final ivObj = encrypt.IV(Uint8List.fromList(iv));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      // Decrypt
      final encrypted = encrypt.Encrypted(ciphertext);
      final decrypted = encrypter.decryptBytes(encrypted, iv: ivObj);

      _log.debug(
        'Decryption complete',
        tag: LogTags.encryption,
        data: {
          'inputSize': encryptedData.length,
          'outputSize': decrypted.length,
        },
      );

      return Uint8List.fromList(decrypted);
    } catch (e) {
      _log.error(
        'Decryption failed',
        tag: LogTags.encryption,
        data: {'error': e.toString()},
      );
      if (e is EncryptionException) rethrow;
      throw EncryptionException(
        message: 'Failed to decrypt data: ${e.toString()}',
      );
    }
  }

  /// Encrypt a file and save to a temporary location
  /// Returns the path to the encrypted file
  Future<String> encryptFileToTemp(File file) async {
    final encryptedBytes = await encryptFile(file);

    final tempDir = await getTemporaryDirectory();
    final encryptedFile = File(
      '${tempDir.path}/encrypted_${DateTime.now().millisecondsSinceEpoch}.enc',
    );
    await encryptedFile.writeAsBytes(encryptedBytes);

    return encryptedFile.path;
  }

  /// Decrypt a file from URL/path and return decrypted bytes
  Future<Uint8List> decryptFile(File encryptedFile) async {
    final encryptedBytes = await encryptedFile.readAsBytes();
    return decryptBytes(encryptedBytes);
  }

  /// Check if encryption is initialized
  bool get isInitialized => _cachedKey != null;

  /// Get current key version (useful for migration tracking)
  int? get keyVersion => _cachedKeyVersion;

  /// Export key for backup (should be protected by user password)
  /// This allows users to recover their data on a new device
  Future<String> exportKeyForBackup(String password) async {
    if (_cachedKey == null) {
      throw const EncryptionException(message: 'No key to export');
    }

    // Derive a key from password using PBKDF2
    final salt = _generateRandomBytes(16);
    final derivedKey = _deriveKeyFromPassword(password, salt);

    // Encrypt the master key with the derived key
    final iv = _generateRandomBytes(_ivLength);
    final key = encrypt.Key(derivedKey);
    final ivObj = encrypt.IV(iv);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.gcm),
    );

    final encrypted = encrypter.encryptBytes(_cachedKey!, iv: ivObj);

    // Combine: salt + iv + encrypted key
    final exportData = Uint8List(16 + _ivLength + encrypted.bytes.length);
    exportData.setRange(0, 16, salt);
    exportData.setRange(16, 16 + _ivLength, iv);
    exportData.setRange(16 + _ivLength, exportData.length, encrypted.bytes);

    return base64Encode(exportData);
  }

  /// Import key from backup
  Future<void> importKeyFromBackup(
    String userId,
    String exportedKey,
    String password,
  ) async {
    try {
      final exportData = base64Decode(exportedKey);

      if (exportData.length < 16 + _ivLength + 32) {
        throw const EncryptionException(message: 'Invalid backup data');
      }

      // Extract components
      final salt = exportData.sublist(0, 16);
      final iv = exportData.sublist(16, 16 + _ivLength);
      final encryptedKey = exportData.sublist(16 + _ivLength);

      // Derive key from password
      final derivedKey = _deriveKeyFromPassword(
        password,
        Uint8List.fromList(salt),
      );

      // Decrypt the master key
      final key = encrypt.Key(derivedKey);
      final ivObj = encrypt.IV(Uint8List.fromList(iv));
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );

      final encrypted = encrypt.Encrypted(encryptedKey);
      final masterKey = encrypter.decryptBytes(encrypted, iv: ivObj);

      // Store the imported key
      await _storeMasterKey(userId, Uint8List.fromList(masterKey));
      _cachedKey = Uint8List.fromList(masterKey);

      _log.info(
        'Successfully imported encryption key from backup',
        tag: LogTags.encryption,
      );
    } catch (e) {
      _log.error(
        'Failed to import key from backup',
        tag: LogTags.encryption,
        data: {'error': e.toString()},
      );
      throw const EncryptionException(
        message: 'Failed to import key. Check your password.',
      );
    }
  }

  // Private methods

  Future<Uint8List?> _loadMasterKey(String userId) async {
    final keyString = await _secureStorage.read(
      key: '${_masterKeyStorageKey}_$userId',
    );
    if (keyString == null) return null;
    return base64Decode(keyString);
  }

  Future<int?> _loadKeyVersion(String userId) async {
    final versionString = await _secureStorage.read(
      key: '${_keyVersionStorageKey}_$userId',
    );
    if (versionString == null) return 1;
    return int.tryParse(versionString) ?? 1;
  }

  Future<void> _generateAndStoreMasterKey(String userId) async {
    final key = _generateRandomBytes(_keyLength);
    await _storeMasterKey(userId, key);
    _cachedKey = key;
    _cachedKeyVersion = 1;
  }

  Future<void> _storeMasterKey(String userId, Uint8List key) async {
    await _secureStorage.write(
      key: '${_masterKeyStorageKey}_$userId',
      value: base64Encode(key),
    );
    await _secureStorage.write(
      key: '${_keyVersionStorageKey}_$userId',
      value: '1',
    );
  }

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  Uint8List _deriveKeyFromPassword(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 100000, _keyLength));

    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }
}

/// Custom exception for encryption errors
class EncryptionException extends AppException {
  const EncryptionException({required super.message});
}
