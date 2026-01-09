import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/encryption_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/widgets/network_avatar.dart';
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
  String? _selectedCurrency;
  File? _selectedImage;
  bool _hasChanges = false;
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _log.info('EditProfilePage opened', tag: LogTags.ui);
    _displayNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _selectedCurrency = 'INR';

    _displayNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);

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
    _phoneController.removeListener(_onFieldChanged);
    
    _displayNameController.text = profile.displayName ?? '';
    _phoneController.text = profile.phone ?? '';
    _emailController.text = profile.email ?? '';
    _selectedCurrency = profile.defaultCurrency ?? 'INR';
    
    // Re-add listeners
    _displayNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    
    // Reset hasChanges since we just initialized
    _hasChanges = false;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
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
              state.status == ProfileStatus.updated) {
            // Success - hide loader and navigate back
            _log.info('Profile operation successful, hiding loader', tag: LogTags.ui);
            
            // Clear the avatar image cache so the new image is fetched
            if (state.status == ProfileStatus.photoUpdated) {
              _log.debug('Clearing NetworkAvatar cache for new photo', tag: LogTags.ui);
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
            
            setState(() {
              _isSaving = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.status == ProfileStatus.photoUpdated
                      ? 'Profile photo updated successfully'
                      : 'Profile updated successfully',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state.hasError && state.errorMessage != null) {
            // Error - hide loader and show error
            _log.error(
              'Profile operation failed, hiding loader',
              tag: LogTags.ui,
              data: {'errorMessage': state.errorMessage},
            );
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

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+91 XXXXX XXXXX',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        enabled: !_isSaving,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
                            if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
                              return 'Please enter a valid phone number';
                            }
                          }
                          return null;
                        },
                      ),
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
                          DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                          DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                          DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                          DropdownMenuItem(value: 'AUD', child: Text('AUD (A\$)')),
                          DropdownMenuItem(value: 'CAD', child: Text('CAD (C\$)')),
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
                            foregroundColor: Theme.of(context).colorScheme.error,
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        
        setState(() {
          _selectedImage = file;
        });
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
        String message = 'Failed to access ${source == ImageSource.camera ? 'camera' : 'gallery'}';
        if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
          message = 'Permission denied. Please enable ${source == ImageSource.camera ? 'camera' : 'photo library'} access in Settings.';
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
    setState(() {
      _isSaving = true;
    });

    // Upload photo first if selected
    if (_selectedImage != null) {
      _log.info(
        'Dispatching ProfilePhotoUpdateRequested event',
        tag: LogTags.ui,
        data: {
          'imagePath': _selectedImage!.path,
        },
      );
      context.read<ProfileBloc>().add(
        ProfilePhotoUpdateRequested(imageFile: _selectedImage!),
      );
    } else {
      // No image, just update profile info
      _log.info('Dispatching ProfileUpdateRequested event', tag: LogTags.ui);
      context.read<ProfileBloc>().add(
        ProfileUpdateRequested(
          displayName: _displayNameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          defaultCurrency: _selectedCurrency,
        ),
      );
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
              setState(() {
                _isSaving = true;
              });
              profileBloc.add(
                const ProfilePhotoDeleteRequested(),
              );
            },
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}