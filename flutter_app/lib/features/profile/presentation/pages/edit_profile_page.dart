import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/widgets/network_avatar.dart';
import '../../../auth/data/datasources/firebase_auth_datasource.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';

/// Edit Profile page for updating user information
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final LoggingService _log = LoggingService();
  late TextEditingController _displayNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  String? _selectedCurrency;
  File? _selectedImage;
  bool _hasChanges = false;
  bool _isInitialized = false;
  bool _isSaving = false;

  // Phone verification state
  bool _isPhoneChanged = false;
  bool _isVerifyingPhone = false;
  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;
  String? _phoneVerificationError;
  String? _originalPhone;
  bool _isPhoneVerified = false;

  late FirebaseAuthDataSource _authDataSource;

  @override
  void initState() {
    super.initState();
    _log.info('EditProfilePage opened', tag: LogTags.ui);
    _authDataSource = sl<FirebaseAuthDataSource>();
    _displayNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _selectedCurrency = 'INR';

    _displayNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onPhoneFieldChanged);

    // Try to initialize from existing profile data
    final profile = context.read<ProfileBloc>().state.profile;
    if (profile != null) {
      _initializeFormWithProfile(profile);
    }
  }

  void _initializeFormWithProfile(dynamic profile) {
    if (_isInitialized) return;
    _isInitialized = true;

    // Remove listeners temporarily to avoid triggering _hasChanges
    _displayNameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onPhoneFieldChanged);

    _displayNameController.text = profile.displayName ?? '';
    _phoneController.text = _extractPhoneDigits(profile.phone ?? '');
    _emailController.text = profile.email ?? '';
    _selectedCurrency = profile.defaultCurrency ?? 'INR';
    _originalPhone = _extractPhoneDigits(profile.phone ?? '');
    _isPhoneVerified = profile.isPhoneVerified ?? false;

    // Re-add listeners
    _displayNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onPhoneFieldChanged);

    // Reset hasChanges since we just initialized
    _hasChanges = false;
    _isPhoneChanged = false;
  }

  String _extractPhoneDigits(String phone) {
    // Remove +91 country code if present
    if (phone.startsWith('+91')) {
      return phone.substring(3);
    } else if (phone.startsWith('91') && phone.length > 10) {
      return phone.substring(2);
    }
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges && mounted) {
      setState(() => _hasChanges = true);
    }
  }

  void _onPhoneFieldChanged() {
    if (!mounted) return;
    final newPhone = _phoneController.text.trim();
    final phoneChanged = newPhone != _originalPhone;

    setState(() {
      _hasChanges = true;
      _isPhoneChanged = phoneChanged && newPhone.isNotEmpty;
      // Reset OTP state when phone changes
      if (phoneChanged) {
        _isOtpSent = false;
        _verificationId = null;
        _phoneVerificationError = null;
        _otpController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        // Log state changes
        _log.debug(
          'ProfileBloc state changed',
          tag: LogTags.ui,
          data: {
            'status': state.status.toString(),
            'hasProfile': state.profile != null,
            'hasError': state.hasError,
            'errorMessage': state.errorMessage,
            'isLoading': state.isLoading,
            'isSaving': _isSaving,
          },
        );

        // Initialize form when profile loads
        if (state.profile != null && !_isInitialized) {
          _log.debug('Initializing form with profile data', tag: LogTags.ui);
          setState(() {
            _initializeFormWithProfile(state.profile);
          });
        }

        // Handle status changes when saving
        if (_isSaving) {
          if (state.status == ProfileStatus.photoUpdated ||
              state.status == ProfileStatus.photoDeleted ||
              state.status == ProfileStatus.updated) {
            // Success - hide loader and navigate back
            _log.info(
              'Profile operation successful, hiding loader',
              tag: LogTags.ui,
            );

            // Clear the avatar image cache so the new/deleted image is properly reflected
            if (state.status == ProfileStatus.photoUpdated ||
                state.status == ProfileStatus.photoDeleted) {
              _log.debug(
                'Clearing NetworkAvatar cache for photo change',
                tag: LogTags.ui,
                data: {'status': state.status.toString()},
              );
              NetworkAvatar.clearAllCache();
            }

            // Sync the updated photoUrl to AuthBloc so dashboard and other screens update
            if (state.profile != null) {
              _log.info(
                'Syncing updated photoUrl to AuthBloc',
                tag: LogTags.ui,
                data: {'photoUrl': state.profile!.photoUrl},
              );
              context.read<AuthBloc>().add(
                AuthUserPhotoUpdated(photoUrl: state.profile!.photoUrl),
              );
            }

            if (mounted) {
              setState(() {
                _isSaving = false;
              });

              String successMessage;
              if (state.status == ProfileStatus.photoUpdated) {
                successMessage = 'Profile photo updated successfully';
              } else if (state.status == ProfileStatus.photoDeleted) {
                successMessage = 'Profile photo removed successfully';
              } else {
                successMessage = 'Profile updated successfully';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(successMessage),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
          } else if (state.hasError && state.errorMessage != null) {
            // Error - hide loader and show error
            _log.error(
              'Profile operation failed, hiding loader',
              tag: LogTags.ui,
              data: {'errorMessage': state.errorMessage},
            );
            if (mounted) {
              setState(() {
                _isSaving = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
          // Note: uploadingPhoto and updating states keep the loader visible
        }
      },
      builder: (context, state) {
        final profile = state.profile;

        return Stack(
          children: [
            // Main content
            Scaffold(
              appBar: AppBar(
                title: const Text('Edit Profile'),
                actions: [
                  if (_hasChanges || _selectedImage != null)
                    TextButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: const Text('Save'),
                    ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Photo
                      _buildPhotoSection(context, profile, state),
                      const SizedBox(height: 32),

                      // Display Name
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'Enter your name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_isSaving,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email (read-only)
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        enabled: false,
                      ),
                      const SizedBox(height: 16),

                      // Phone Field with India country code
                      _buildPhoneSection(context, profile),
                      const SizedBox(height: 16),

                      // Currency
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          labelText: 'Default Currency',
                          prefixIcon: Icon(Icons.currency_exchange),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'INR',
                            child: Text('INR (₹)'),
                          ),
                          DropdownMenuItem(
                            value: 'USD',
                            child: Text('USD (\$)'),
                          ),
                          DropdownMenuItem(
                            value: 'EUR',
                            child: Text('EUR (€)'),
                          ),
                          DropdownMenuItem(
                            value: 'GBP',
                            child: Text('GBP (£)'),
                          ),
                          DropdownMenuItem(
                            value: 'AUD',
                            child: Text('AUD (A\$)'),
                          ),
                          DropdownMenuItem(
                            value: 'CAD',
                            child: Text('CAD (C\$)'),
                          ),
                        ],
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedCurrency = value;
                                  _hasChanges = true;
                                });
                              },
                      ),
                      const SizedBox(height: 32),

                      // Delete Photo Button
                      if (profile?.photoUrl != null && _selectedImage == null)
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _deletePhoto,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove Profile Photo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Full-screen loading overlay
            if (_isSaving)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            _selectedImage != null
                                ? 'Uploading photo...'
                                : 'Saving profile...',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneSection(BuildContext context, dynamic profile) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Field with India country code
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed India country code prefix
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '+91',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Phone number input (10 digits only)
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'XXXXXXXXXX',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  suffixIcon: (_isPhoneVerified && !_isPhoneChanged)
                      ? const Icon(Icons.verified, color: Colors.green)
                      : null,
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                enabled: !_isSaving && !_isOtpSent,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final phone = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (phone.length != 10) {
                      return 'Enter a valid 10-digit mobile number';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        // Phone verification notice and OTP section
        if (_isPhoneChanged) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phone number change requires OTP verification',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (!_isOtpSent) ...[
            // Send OTP button
            FilledButton.tonal(
              onPressed: _isVerifyingPhone ? null : _sendOtp,
              child: _isVerifyingPhone
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send OTP to verify'),
            ),
          ] else ...[
            // OTP input field
            TextFormField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                hintText: '6-digit code',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              enabled: !_isSaving,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isVerifyingPhone
                      ? null
                      : () {
                          if (mounted) {
                            setState(() {
                              _isOtpSent = false;
                              _otpController.clear();
                            });
                          }
                        },
                  child: const Text('Change Number'),
                ),
                TextButton(
                  onPressed: _isVerifyingPhone ? null : _sendOtp,
                  child: const Text('Resend OTP'),
                ),
              ],
            ),
          ],
        ],

        // Error message
        if (_phoneVerificationError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _phoneVerificationError!,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      if (mounted) {
        setState(
          () => _phoneVerificationError = 'Please enter a valid 10-digit phone number',
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isVerifyingPhone = true;
        _phoneVerificationError = null;
      });
    }

    // Normalize phone number
    final normalizedPhone = '+91$phone';

    try {
      await _authDataSource.signInWithPhone(
        phoneNumber: normalizedPhone,
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isOtpSent = true;
            _isVerifyingPhone = false;
          });
          _log.info('OTP sent successfully for phone update', tag: LogTags.auth);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your phone'),
              backgroundColor: Colors.green,
            ),
          );
        },
        verificationCompleted: (credential) async {
          _log.info('Auto verification completed for phone update', tag: LogTags.auth);
          await _verifyAndLinkPhone(credential);
        },
        verificationFailed: (error) {
          _log.error(
            'Phone verification failed',
            tag: LogTags.auth,
            data: {'code': error.code, 'message': error.message},
          );
          if (!mounted) return;
          setState(() {
            _isVerifyingPhone = false;
            _phoneVerificationError = error.message ?? 'Phone verification failed';
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
        resendToken: _resendToken,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifyingPhone = false;
        _phoneVerificationError = 'Failed to send OTP: $e';
      });
    }
  }

  Future<void> _verifyAndLinkPhone(firebase_auth.PhoneAuthCredential credential) async {
    if (mounted) {
      setState(() => _isSaving = true);
    }

    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // First, check if there's an existing phone credential to unlink
        final phoneProviders = user.providerData
            .where((p) => p.providerId == 'phone')
            .toList();
        
        for (final provider in phoneProviders) {
          if (provider.uid != null) {
            try {
              await user.unlink('phone');
              _log.info('Unlinked existing phone credential', tag: LogTags.auth);
            } catch (e) {
              _log.debug(
                'No phone provider to unlink or unlink failed',
                tag: LogTags.auth,
                data: {'error': e.toString()},
              );
            }
          }
        }

        // Link the new phone credential
        await user.linkWithCredential(credential);

        // Update phone number in Firestore and mark as verified
        final phone = _phoneController.text.trim();
        await _authDataSource.markPhoneVerified(phoneNumber: phone);

        _log.info('Phone updated and verified successfully', tag: LogTags.auth);

        if (mounted) {
          // Reset phone change state
          _originalPhone = phone;
          _isPhoneChanged = false;
          _isOtpSent = false;
          _isPhoneVerified = true;

          // Now save the rest of the profile
          _saveProfileWithoutPhoneChange();
        }
      }
    } catch (e) {
      _log.error(
        'Failed to link phone credential',
        tag: LogTags.auth,
        data: {'error': e.toString()},
      );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _phoneVerificationError = 'Failed to update phone: ${e.toString()}';
      });
    }
  }

  Widget _buildPhotoSection(
    BuildContext context,
    dynamic profile,
    ProfileState state,
  ) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              // Avatar - Use local file if selected, otherwise encrypted network image
              if (_selectedImage != null)
                CircleAvatar(
                  radius: 60,
                  backgroundImage: FileImage(_selectedImage!),
                )
              else
                NetworkAvatar(
                  imageUrl: profile?.photoUrl,
                  radius: 60,
                  encryptionService: sl<EncryptionService>(),
                  child: Text(
                    profile?.initials ?? '?',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),

              // Edit button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: _isSaving ? null : _showImagePickerOptions,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to change photo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    _log.info(
      'Starting image pick',
      tag: LogTags.ui,
      data: {'source': source.toString()},
    );

    try {
      final picker = ImagePicker();
      _log.debug('ImagePicker initialized, requesting image', tag: LogTags.ui);

      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileExists = await file.exists();
        final fileSize = fileExists ? await file.length() : 0;

        _log.info(
          'Image picked successfully',
          tag: LogTags.ui,
          data: {
            'path': pickedFile.path,
            'name': pickedFile.name,
            'exists': fileExists,
            'sizeBytes': fileSize,
            'sizeMB': (fileSize / (1024 * 1024)).toStringAsFixed(2),
          },
        );

        if (!fileExists) {
          _log.error(
            'Picked file does not exist',
            tag: LogTags.ui,
            data: {'path': pickedFile.path},
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Selected image file not found'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }

        if (mounted) {
          setState(() {
            _selectedImage = file;
          });
        }
        _log.debug('Selected image set in state', tag: LogTags.ui);
      } else {
        _log.info('Image pick cancelled by user', tag: LogTags.ui);
      }
    } on PlatformException catch (e) {
      _log.error(
        'Platform exception picking image',
        tag: LogTags.ui,
        data: {
          'code': e.code,
          'message': e.message,
          'details': e.details?.toString(),
        },
      );
      if (mounted) {
        String message =
            'Failed to access ${source == ImageSource.camera ? 'camera' : 'gallery'}';
        if (e.code == 'camera_access_denied' ||
            e.code == 'photo_access_denied') {
          message =
              'Permission denied. Please enable ${source == ImageSource.camera ? 'camera' : 'photo library'} access in Settings.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () {
                // Could open app settings here
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      _log.error(
        'Unexpected error picking image',
        tag: LogTags.ui,
        data: {
          'error': e.toString(),
          'type': e.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      _log.warning('Profile form validation failed', tag: LogTags.ui);
      return;
    }

    // If phone has changed and OTP is sent but not verified, verify first
    if (_isPhoneChanged && _isOtpSent) {
      _verifyOtpAndSave();
      return;
    }

    // If phone has changed but OTP not sent yet, show error
    if (_isPhoneChanged && !_isOtpSent) {
      if (mounted) {
        setState(() {
          _phoneVerificationError = 'Please verify your new phone number with OTP';
        });
      }
      return;
    }

    // No phone change, proceed with normal save
    _log.info(
      'Profile save requested, showing loader',
      tag: LogTags.ui,
      data: {
        'hasImageToUpload': _selectedImage != null,
        'displayName': _displayNameController.text.trim(),
        'hasPhone': _phoneController.text.trim().isNotEmpty,
        'currency': _selectedCurrency,
      },
    );

    // Show the loading overlay
    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    // Upload photo first if selected
    if (_selectedImage != null) {
      _log.info(
        'Dispatching ProfilePhotoUpdateRequested event',
        tag: LogTags.ui,
        data: {'imagePath': _selectedImage!.path},
      );
      context.read<ProfileBloc>().add(
        ProfilePhotoUpdateRequested(imageFile: _selectedImage!),
      );
    } else {
      _saveProfileWithoutPhoneChange();
    }
  }

  void _saveProfileWithoutPhoneChange() {
    // No image, just update profile info
    _log.info('Dispatching ProfileUpdateRequested event', tag: LogTags.ui);
    context.read<ProfileBloc>().add(
      ProfileUpdateRequested(
        displayName: _displayNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : '+91${_phoneController.text.trim()}',
        defaultCurrency: _selectedCurrency,
      ),
    );
  }

  Future<void> _verifyOtpAndSave() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      if (mounted) {
        setState(() => _phoneVerificationError = 'Please enter a valid 6-digit OTP');
      }
      return;
    }

    if (_verificationId == null) {
      if (mounted) {
        setState(
          () => _phoneVerificationError = 'Verification session expired. Please request a new OTP',
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
        _phoneVerificationError = null;
      });
    }

    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _verifyAndLinkPhone(credential);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _phoneVerificationError = 'Invalid OTP: ${e.toString()}';
      });
    }
  }

  void _deletePhoto() {
    // Capture the ProfileBloc reference before showing the dialog
    // because the dialog's BuildContext won't have access to it
    final profileBloc = context.read<ProfileBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text(
          'Are you sure you want to remove your profile photo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (mounted) {
                setState(() {
                  _isSaving = true;
                });
              }
              profileBloc.add(const ProfilePhotoDeleteRequested());
            },
            child: Text(
              'Remove',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}