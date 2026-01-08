import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/logging_service.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

/// Chat page for expense discussions
class ExpenseChatPage extends StatefulWidget {
  final ExpenseEntity expense;
  final String currentUserId;

  const ExpenseChatPage({
    super.key,
    required this.expense,
    required this.currentUserId,
  });

  @override
  State<ExpenseChatPage> createState() => _ExpenseChatPageState();
}

class _ExpenseChatPageState extends State<ExpenseChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final LoggingService _log = LoggingService();

  @override
  void initState() {
    super.initState();
    _log.info(
      'ExpenseChatPage opened',
      tag: LogTags.ui,
      data: {
        'expenseId': widget.expense.id,
        'expenseDescription': widget.expense.description,
      },
    );
    // Subscribe to real-time chat updates
    context.read<ChatBloc>().add(SubscribeToChatStream(widget.expense.id));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<ChatBloc>().add(const UnsubscribeFromChatStream());
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _log.debug('Sending text message', tag: LogTags.ui);

    context.read<ChatBloc>().add(
      SendTextMessage(expenseId: widget.expense.id, text: text),
    );

    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (image != null && mounted) {
      context.read<ChatBloc>().add(
        SendImageMessage(
          expenseId: widget.expense.id,
          imageFile: File(image.path),
        ),
      );
      _scrollToBottom();
    }
  }

  Future<void> _takeAndSendPhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (image != null && mounted) {
      context.read<ChatBloc>().add(
        SendImageMessage(
          expenseId: widget.expense.id,
          imageFile: File(image.path),
        ),
      );
      _scrollToBottom();
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takeAndSendPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Voice Note'),
              onTap: () {
                Navigator.pop(context);
                _showVoiceRecordingSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVoiceRecordingSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) => _VoiceRecordingSheet(
        expenseId: widget.expense.id,
        onRecordingComplete: _scrollToBottom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.expense.description,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.expense.formattedAmount,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state.hasError && state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            context.read<ChatBloc>().add(const ClearChatError());
          }

          // Scroll to bottom when new messages arrive
          if (state.hasMessages) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Messages list
              Expanded(
                child: state.isLoading && !state.hasMessages
                    ? const Center(child: CircularProgressIndicator())
                    : state.hasMessages
                    ? _buildMessagesList(state.messages)
                    : _buildEmptyState(),
              ),
              // Input area
              _buildInputArea(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation about this expense',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessageEntity> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final previousMessage = index > 0 ? messages[index - 1] : null;
        final showDateDivider =
            previousMessage == null ||
            !_isSameDay(message.createdAt, previousMessage.createdAt);

        return Column(
          children: [
            if (showDateDivider) _buildDateDivider(message.createdAt),
            _ChatMessageBubble(
              message: message,
              currentUserId: widget.currentUserId,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final isYesterday = _isSameDay(date, now.subtract(const Duration(days: 1)));

    String dateText;
    if (isToday) {
      dateText = 'Today';
    } else if (isYesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: state.isSending ? null : _showAttachmentOptions,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                enabled: !state.isSending,
                onSubmitted: (_) => _sendTextMessage(),
              ),
            ),
            const SizedBox(width: 8),
            state.isSending
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendTextMessage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ],
        ),
      ),
    );
  }
}

/// Chat message bubble widget
class _ChatMessageBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final String currentUserId;

  const _ChatMessageBubble({
    required this.message,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.sender.id == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.sender.photoUrl != null
                  ? NetworkImage(message.sender.photoUrl!)
                  : null,
              child: message.sender.photoUrl == null
                  ? Text(message.sender.displayName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.sender.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  _buildMessageContent(context, isMe),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Theme.of(
                              context,
                            ).colorScheme.onPrimary.withValues(alpha: 0.7)
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isMe) {
    switch (message.type) {
      case ChatMessageType.text:
        return Text(
          message.text ?? '',
          style: TextStyle(
            color: isMe
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        );
      case ChatMessageType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () => _showFullScreenImage(context),
            child: Image.network(
              message.imageUrl ?? '',
              width: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: 200,
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: 200,
                height: 150,
                color: Theme.of(context).colorScheme.errorContainer,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        );
      case ChatMessageType.voiceNote:
        return _VoiceNotePlayer(
          url: message.voiceNoteUrl ?? '',
          durationMs: message.voiceNoteDurationMs ?? 0,
          isMe: isMe,
        );
    }
  }

  void _showFullScreenImage(BuildContext context) {
    if (message.imageUrl == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(child: Image.network(message.imageUrl!)),
        ),
      ),
    );
  }
}

/// Voice note player widget
class _VoiceNotePlayer extends StatefulWidget {
  final String url;
  final int durationMs;
  final bool isMe;

  const _VoiceNotePlayer({
    required this.url,
    required this.durationMs,
    required this.isMe,
  });

  @override
  State<_VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<_VoiceNotePlayer> {
  bool _isPlaying = false;
  final double _progress = 0.0;

  String get _formattedDuration {
    final seconds = widget.durationMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    // TODO: Implement actual audio playback with audioplayers package
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _togglePlayback,
          color: color,
          iconSize: 32,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: color.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              const SizedBox(height: 4),
              Text(
                _formattedDuration,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Voice recording sheet widget
class _VoiceRecordingSheet extends StatefulWidget {
  final String expenseId;
  final VoidCallback onRecordingComplete;

  const _VoiceRecordingSheet({
    required this.expenseId,
    required this.onRecordingComplete,
  });

  @override
  State<_VoiceRecordingSheet> createState() => _VoiceRecordingSheetState();
}

class _VoiceRecordingSheetState extends State<_VoiceRecordingSheet> {
  bool _isRecording = false;
  int _durationMs = 0;

  String get _formattedDuration {
    final seconds = _durationMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _durationMs = 0;
    });
    context.read<ChatBloc>().add(const StartVoiceRecording());
    // TODO: Start actual recording with record package
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    context.read<ChatBloc>().add(const StopVoiceRecording());
    // TODO: Get recorded file path and send
    // For now, just close the sheet
    Navigator.pop(context);
  }

  void _cancelRecording() {
    setState(() {
      _isRecording = false;
      _durationMs = 0;
    });
    context.read<ChatBloc>().add(const CancelVoiceRecording());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isRecording ? 'Recording...' : 'Tap to record',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Text(
            _formattedDuration,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: _cancelRecording,
                child: const Text('Cancel'),
              ),
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              TextButton(
                onPressed: _isRecording ? _stopRecording : null,
                child: const Text('Send'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
