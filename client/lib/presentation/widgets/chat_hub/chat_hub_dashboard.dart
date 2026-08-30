import 'package:flutter/material.dart';
import '../../../core/chat/chat_models.dart';
import '../../../core/chat/chat_service.dart';
import '../../../theme/everforest_colors.dart';
import 'channel_sidebar.dart';
import 'chat_room_view.dart';

class ChatHubDashboard extends StatefulWidget {
  const ChatHubDashboard({super.key});

  @override
  State<ChatHubDashboard> createState() => _ChatHubDashboardState();
}

class _ChatHubDashboardState extends State<ChatHubDashboard> {
  final ChatService _chatService = ChatService.instance;

  @override
  void initState() {
    super.initState();
    _chatService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          return ValueListenableBuilder<ChatChannel?>(
            valueListenable: _chatService.activeChannel,
            builder: (context, activeChannel, _) {
              if (isMobile) {
                // On mobile, if a channel is selected, show the chat room, else sidebar
                if (activeChannel != null) {
                  return Stack(
                    children: [
                      ChatRoomView(channel: activeChannel),
                      Positioned(
                        top: 14,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: EverforestColors.fg),
                          onPressed: () => _chatService.activeChannel.value = null,
                        ),
                      ),
                    ],
                  );
                }
                return const ChannelSidebar();
              }

              // On Desktop / Tablet, split side-by-side view
              return Row(
                children: [
                  const ChannelSidebar(),
                  Expanded(
                    child: activeChannel != null
                        ? ChatRoomView(channel: activeChannel)
                        : const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, size: 48, color: EverforestColors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'Select a conversation to start chatting',
                                  style: TextStyle(color: EverforestColors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
