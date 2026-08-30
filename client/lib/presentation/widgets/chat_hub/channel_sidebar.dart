import 'package:flutter/material.dart';
import '../../../core/chat/chat_models.dart';
import '../../../core/chat/chat_service.dart';
import '../../../core/local_discovery_service.dart';
import '../../../theme/everforest_colors.dart';

class ChannelSidebar extends StatefulWidget {
  const ChannelSidebar({super.key});

  @override
  State<ChannelSidebar> createState() => _ChannelSidebarState();
}

class _ChannelSidebarState extends State<ChannelSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService.instance;

  Future<void> _showNewChannelDialog() async {
    final nameController = TextEditingController();
    bool isDirect = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: EverforestColors.bg1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: EverforestColors.bg2),
          ),
          title: const Text('New Conversation', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: InputDecoration(
                  hintText: 'Channel or Contact Name',
                  hintStyle: const TextStyle(color: EverforestColors.grey),
                  filled: true,
                  fillColor: EverforestColors.bg0,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: EverforestColors.green)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: isDirect,
                    activeColor: EverforestColors.green,
                    onChanged: (v) => setModalState(() => isDirect = v ?? false),
                  ),
                  const Text('Direct 1-on-1 Message (DM)', style: TextStyle(color: EverforestColors.fg, fontSize: 13)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: EverforestColors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green, foregroundColor: EverforestColors.bg0),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  _chatService.createChannel(name, isDirect, [name]);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('CREATE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peers = LocalDiscoveryService.instance.peersNotifier;

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: EverforestColors.bg1,
        border: Border(right: BorderSide(color: EverforestColors.bg2, width: 1)),
      ),
      child: Column(
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.forum_rounded, color: EverforestColors.green, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Messages',
                  style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_comment_rounded, color: EverforestColors.green, size: 20),
                  tooltip: 'New Chat',
                  onPressed: _showNewChannelDialog,
                ),
              ],
            ),
          ),
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: EverforestColors.bg0,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: EverforestColors.bg2),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search chats & channels...',
                  hintStyle: TextStyle(color: EverforestColors.grey, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: EverforestColors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (q) => _chatService.fetchChannels(query: q),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Mesh Peers Live Bar
          ValueListenableBuilder<List<LocalPeer>>(
            valueListenable: peers,
            builder: (context, peerList, _) {
              if (peerList.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: EverforestColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EverforestColors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hub_rounded, size: 14, color: EverforestColors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '${peerList.length} Mesh Peer(s) Online',
                      style: const TextStyle(color: EverforestColors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1, color: EverforestColors.bg2),
          // Channel List
          Expanded(
            child: ValueListenableBuilder<List<ChatChannel>>(
              valueListenable: _chatService.channels,
              builder: (context, channels, _) {
                if (channels.isEmpty) {
                  return const Center(
                    child: Text('No conversations yet', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                  );
                }

                return ValueListenableBuilder<ChatChannel?>(
                  valueListenable: _chatService.activeChannel,
                  builder: (context, activeCh, _) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      itemCount: channels.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, idx) {
                        final ch = channels[idx];
                        final isSelected = activeCh?.id == ch.id;

                        return InkWell(
                          onTap: () => _chatService.selectChannel(ch),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? EverforestColors.green.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? EverforestColors.green.withValues(alpha: 0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: ch.isDirect
                                      ? EverforestColors.blue.withValues(alpha: 0.2)
                                      : EverforestColors.green.withValues(alpha: 0.2),
                                  child: Icon(
                                    ch.isDirect ? Icons.person_rounded : Icons.tag_rounded,
                                    size: 18,
                                    color: ch.isDirect ? EverforestColors.blue : EverforestColors.green,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ch.name,
                                        style: TextStyle(
                                          color: isSelected ? EverforestColors.green : EverforestColors.fg,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        ch.lastMessage?.content ?? (ch.isDirect ? 'Direct conversation' : 'Family channel'),
                                        style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
