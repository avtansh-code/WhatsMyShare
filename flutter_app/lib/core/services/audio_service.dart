import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

/// Audio recording and playback state
enum AudioRecordingState {
  idle,
  recording,
  paused,
  stopped,
}

enum AudioPlaybackState {
  idle,
  playing,
  paused,
  stopped,
  completed,
}

/// Service for audio recording and playback
/// Handles voice note recording for expense chat
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  
  // Recording state
  AudioRecordingState _recordingState = AudioRecordingState.idle;
  int _recordingDurationMs = 0;
  
  // Playback state
  AudioPlaybackState _playbackState = AudioPlaybackState.idle;
  String? _currentlyPlayingUrl;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  // Stream controllers for state updates
  final _recordingStateController = StreamController<AudioRecordingState>.broadcast();
  final _recordingDurationController = StreamController<int>.broadcast();
  final _playbackStateController = StreamController<AudioPlaybackState>.broadcast();
  final _playbackPositionController = StreamController<Duration>.broadcast();

  // Public streams
  Stream<AudioRecordingState> get recordingStateStream => _recordingStateController.stream;
  Stream<int> get recordingDurationStream => _recordingDurationController.stream;
  Stream<AudioPlaybackState> get playbackStateStream => _playbackStateController.stream;
  Stream<Duration> get playbackPositionStream => _playbackPositionController.stream;

  // Public getters
  AudioRecordingState get recordingState => _recordingState;
  int get recordingDurationMs => _recordingDurationMs;
  AudioPlaybackState get playbackState => _playbackState;
  Duration get playbackPosition => _playbackPosition;
  Duration get playbackDuration => _playbackDuration;
  String? get currentRecordingPath => _currentRecordingPath;

  AudioService() {
    _initializePlayer();
  }

  void _initializePlayer() {
    // Listen to player state changes
    _player.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          _updatePlaybackState(AudioPlaybackState.playing);
          break;
        case PlayerState.paused:
          _updatePlaybackState(AudioPlaybackState.paused);
          break;
        case PlayerState.stopped:
          _updatePlaybackState(AudioPlaybackState.stopped);
          break;
        case PlayerState.completed:
          _updatePlaybackState(AudioPlaybackState.completed);
          _playbackPosition = Duration.zero;
          _playbackPositionController.add(_playbackPosition);
          break;
        case PlayerState.disposed:
          _updatePlaybackState(AudioPlaybackState.idle);
          break;
      }
    });

    // Listen to position changes
    _player.onPositionChanged.listen((position) {
      _playbackPosition = position;
      _playbackPositionController.add(position);
    });

    // Listen to duration changes
    _player.onDurationChanged.listen((duration) {
      _playbackDuration = duration;
    });
  }

  // ==================== Recording Methods ====================

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission
      if (!await hasPermission()) {
        return false;
      }

      // Get temp directory for recording
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_note_$timestamp.m4a';

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      );

      // Start recording
      await _recorder.start(config, path: _currentRecordingPath!);

      // Update state
      _recordingStartTime = DateTime.now();
      _recordingDurationMs = 0;
      _updateRecordingState(AudioRecordingState.recording);

      // Start duration timer
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (_recordingStartTime != null) {
          _recordingDurationMs = DateTime.now().difference(_recordingStartTime!).inMilliseconds;
          _recordingDurationController.add(_recordingDurationMs);
        }
      });

      return true;
    } catch (e) {
      _updateRecordingState(AudioRecordingState.idle);
      return false;
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (_recordingState != AudioRecordingState.recording) return;
    
    try {
      await _recorder.pause();
      _recordingTimer?.cancel();
      _updateRecordingState(AudioRecordingState.paused);
    } catch (e) {
      // Handle error
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (_recordingState != AudioRecordingState.paused) return;
    
    try {
      await _recorder.resume();
      
      // Resume timer
      final pausedDuration = _recordingDurationMs;
      _recordingStartTime = DateTime.now().subtract(Duration(milliseconds: pausedDuration));
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (_recordingStartTime != null) {
          _recordingDurationMs = DateTime.now().difference(_recordingStartTime!).inMilliseconds;
          _recordingDurationController.add(_recordingDurationMs);
        }
      });
      
      _updateRecordingState(AudioRecordingState.recording);
    } catch (e) {
      // Handle error
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (_recordingState == AudioRecordingState.idle) return null;
    
    try {
      _recordingTimer?.cancel();
      final path = await _recorder.stop();
      _updateRecordingState(AudioRecordingState.stopped);
      
      // Return the path if file exists
      if (path != null && await File(path).exists()) {
        return path;
      }
      return _currentRecordingPath;
    } catch (e) {
      _updateRecordingState(AudioRecordingState.idle);
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    _recordingTimer?.cancel();
    
    try {
      await _recorder.stop();
    } catch (e) {
      // Ignore errors when stopping
    }

    // Delete the file if it exists
    if (_currentRecordingPath != null) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore deletion errors
      }
    }

    _currentRecordingPath = null;
    _recordingDurationMs = 0;
    _recordingStartTime = null;
    _updateRecordingState(AudioRecordingState.idle);
    _recordingDurationController.add(0);
  }

  void _updateRecordingState(AudioRecordingState state) {
    _recordingState = state;
    _recordingStateController.add(state);
  }

  // ==================== Playback Methods ====================

  /// Play audio from URL or file path
  Future<bool> play(String source) async {
    try {
      // Stop current playback if different source
      if (_currentlyPlayingUrl != source && _playbackState == AudioPlaybackState.playing) {
        await stop();
      }

      _currentlyPlayingUrl = source;

      // Determine source type
      if (source.startsWith('http://') || source.startsWith('https://')) {
        await _player.play(UrlSource(source));
      } else {
        await _player.play(DeviceFileSource(source));
      }

      return true;
    } catch (e) {
      _updatePlaybackState(AudioPlaybackState.idle);
      return false;
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      // Handle error
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await _player.resume();
    } catch (e) {
      // Handle error
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _player.stop();
      _currentlyPlayingUrl = null;
      _playbackPosition = Duration.zero;
      _playbackPositionController.add(_playbackPosition);
    } catch (e) {
      // Handle error
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      // Handle error
    }
  }

  /// Set playback speed
  Future<void> setPlaybackRate(double rate) async {
    try {
      await _player.setPlaybackRate(rate);
    } catch (e) {
      // Handle error
    }
  }

  void _updatePlaybackState(AudioPlaybackState state) {
    _playbackState = state;
    _playbackStateController.add(state);
  }

  // ==================== Utility Methods ====================

  /// Get recording file as File object
  File? getRecordingFile() {
    if (_currentRecordingPath == null) return null;
    return File(_currentRecordingPath!);
  }

  /// Get formatted duration string from milliseconds
  static String formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted duration string from Duration
  static String formatDurationFromDuration(Duration duration) {
    return formatDuration(duration.inMilliseconds);
  }

  /// Check if currently playing a specific URL
  bool isPlaying(String url) {
    return _currentlyPlayingUrl == url && _playbackState == AudioPlaybackState.playing;
  }

  /// Get progress percentage (0.0 - 1.0)
  double getPlaybackProgress() {
    if (_playbackDuration.inMilliseconds == 0) return 0.0;
    return _playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds;
  }

  /// Dispose resources
  Future<void> dispose() async {
    _recordingTimer?.cancel();
    
    await _recordingStateController.close();
    await _recordingDurationController.close();
    await _playbackStateController.close();
    await _playbackPositionController.close();
    
    await _recorder.dispose();
    await _player.dispose();
  }
}