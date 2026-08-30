import 'package:flutter/material.dart';
import '../../../core/chat/chat_models.dart';
import '../../../core/chat/chat_service.dart';
import '../../../theme/everforest_colors.dart';
import 'chat_message_bubble.dart';
import 'voice_recorder_bar.dart';

class ChatRoomView extends StatefulWidget {
  final ChatChannel channel;

  const ChatRoomView({super.key, required this.channel});

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService.instance;
  bool _isVoiceRecording = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _chatService.sendMessage(text);
    _scrollToBottom();
  }

  void _handleSendVoiceMessage(Duration duration) {
    setState(() => _isVoiceRecording = false);
    _chatService.sendVoiceMessage(duration);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      child: Column(
        children: [
          // Chat Room Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: EverforestColors.bg1,
              border: Border(bottom: BorderSide(color: EverforestColors.bg2, width: 1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: widget.channel.isDirect
                      ? EverforestColors.blue.withValues(alpha: 0.2)
                      : EverforestColors.green.withValues(alpha: 0.2),
                  child: Icon(
                    widget.channel.isDirect ? Icons.person_rounded : Icons.tag_rounded,
                    size: 20,
                    color: widget.channel.isDirect ? EverforestColors.blue : EverforestColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.channel.name,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: EverforestColors.green,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Dual Transport (Server Relay + P2P Mesh)',
                            style: TextStyle(color: EverforestColors.green, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: EverforestColors.grey, size: 20),
                  onPressed: () {},
                  tooltip: 'Channel Info',
                ),
              ],
            ),
          ),
          // Messages Feed
          Expanded(
            child: ValueListenableBuilder<List<ChatMessage>>(
              valueListenable: _chatService.activeMessages,
              builder: (context, messages, _) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: EverforestColors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'No messages here yet',
                          style: TextStyle(color: EverforestColors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Say hello or send a voice message to start chatting!',
                          style: TextStyle(color: EverforestColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, idx) {
                    final msg = messages[idx];
                    final isMe = msg.senderID == _chatService.currentUserID.value;
                    return ChatMessageBubble(message: msg, isMe: isMe);
                  },
                );
              },
            ),
          ),
          // Composer Input Bar or Voice Recorder Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: EverforestColors.bg1,
              border: Border(top: BorderSide(color: EverforestColors.bg2, width: 1)),
            ),
            child: _isVoiceRecording
                ? VoiceRecorderBar(
                    onCancel: () => setState(() => _isVoiceRecording = false),
                    onSend: _handleSendVoiceMessage,
                  )
                : Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file_rounded, color: EverforestColors.grey, size: 22),
                        tooltip: 'Attach Media or Document',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: EverforestColors.bg1,
                              content: Text('File attachment integration ready via P2P Beam.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: EverforestColors.bg0,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EverforestColors.bg2),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: EverforestColors.fg, fontSize: 14),
                            maxLines: 4,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _handleSendMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Type a message... (Enter to send)',
                              hintStyle: TextStyle(color: EverforestColors.grey, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mic or Send Button
                      if (_textController.text.trim().isEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: EverforestColors.green.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: EverforestColors.green.withValues(alpha: 0.4)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.mic_rounded, color: EverforestColors.green, size: 22),
                            onPressed: () => setState(() => _isVoiceRecording = true),
                            tooltip: 'Record Voice Note',
                          ),
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            color: EverforestColors.green,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: EverforestColors.bg0, size: 20),
                            onPressed: _handleSendMessage,
                            tooltip: 'Send',
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
