import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../api_client.dart';
import '../event_hub.dart';
import '../local_discovery_service.dart';
import '../p2p_transfer_service.dart';
import 'chat_models.dart';

class ChatService {
  static final ChatService instance = ChatService._internal();
  ChatService._internal();

  final ValueNotifier<List<ChatChannel>> channels = ValueNotifier([]);
  final ValueNotifier<ChatChannel?> activeChannel = ValueNotifier(null);
  final ValueNotifier<List<ChatMessage>> activeMessages = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String> currentUserID = ValueNotifier('panospds');

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // 1. Listen to Live Push Events from Host Daemon
    EventHub.instance.events.listen((event) {
      final topic = event['topic'];
      if (topic == 'chat:message') {
        final payload = event['payload'];
        if (payload is Map<String, dynamic>) {
          final msg = ChatMessage.fromJson(payload);
          _handleIncomingMessage(msg);
        }
      } else if (topic == 'chat:channel_created') {
        fetchChannels();
      }
    });

    // 2. Listen to P2P Offline Mesh Messages
    P2PTransferService.instance.onChatMessageReceived = (data) {
      final msg = ChatMessage.fromJson(data);
      _handleIncomingMessage(msg);
    };

    fetchChannels();
  }

  void _handleIncomingMessage(ChatMessage msg) {
    if (activeChannel.value?.id == msg.channelID) {
      final current = List<ChatMessage>.from(activeMessages.value);
      if (!current.any((m) => m.id == msg.id)) {
        current.add(msg);
        activeMessages.value = current;
      }
    }
    // Refresh channel previews
    fetchChannels();
  }

  Future<void> fetchChannels({String query = ''}) async {
    isLoading.value = true;
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/chat/channels?q=$query');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['channels'] as List?) ?? [];
        channels.value = list.map((e) => ChatChannel.fromJson(e)).toList();

        // Select first channel if none active
        if (activeChannel.value == null && channels.value.isNotEmpty) {
          selectChannel(channels.value.first);
        }
      }
    } catch (e) {
      debugPrint('[Chat] Failed to fetch channels: $e');
      // If offline, maintain default channels
      if (channels.value.isEmpty) {
        channels.value = [
          ChatChannel(
            id: 'chan-family-lounge',
            name: 'Family Lounge (Offline Mesh)',
            isDirect: false,
            members: ['panospds', 'all'],
            createdAt: DateTime.now(),
            lastMessageAt: DateTime.now(),
          ),
        ];
        if (activeChannel.value == null) {
          selectChannel(channels.value.first);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectChannel(ChatChannel channel) async {
    activeChannel.value = channel;
    activeMessages.value = [];
    await fetchMessages(channel.id);
  }

  Future<void> fetchMessages(String channelID) async {
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/chat/messages?channel_id=$channelID&limit=100');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['messages'] as List?) ?? [];
        activeMessages.value = list.map((e) => ChatMessage.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('[Chat] Offline: reading local cached messages: $e');
    }
  }

  Future<bool> sendMessage(String content, {String? attachmentUrl, String? attachmentType}) async {
    final channel = activeChannel.value;
    if (channel == null || content.trim().isEmpty) return false;

    final tempMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      channelID: channel.id,
      senderID: currentUserID.value,
      senderName: currentUserID.value,
      content: content.trim(),
      attachmentURL: attachmentUrl,
      attachmentType: attachmentType,
      createdAt: DateTime.now(),
      status: 'sent',
    );

    // Optimistic UI Append
    final updated = List<ChatMessage>.from(activeMessages.value)..add(tempMsg);
    activeMessages.value = updated;

    bool sentOnline = false;

    // 1. Try sending via Daemon Server Relay
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/chat/messages');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'channel_id': channel.id,
          'content': content.trim(),
          'attachment_url': attachmentUrl,
          'attachment_type': attachmentType,
        }),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        sentOnline = true;
      }
    } catch (_) {}

    // 2. If server failed or offline, broadcast direct to nearby P2P Mesh peers!
    if (!sentOnline) {
      final peers = LocalDiscoveryService.instance.peersNotifier.value;
      for (final peer in peers) {
        P2PTransferService.instance.sendDirectChatMessage(peer.address, peer.port, tempMsg.toJson());
      }
    }

    return true;
  }

  Future<bool> sendVoiceMessage(Duration duration, {String? audioUrl}) async {
    final channel = activeChannel.value;
    if (channel == null) return false;

    final seconds = duration.inSeconds;
    final content = 'Voice message (${seconds}s)';

    final tempMsg = ChatMessage(
      id: 'voice-${DateTime.now().millisecondsSinceEpoch}',
      channelID: channel.id,
      senderID: currentUserID.value,
      senderName: currentUserID.value,
      content: content,
      attachmentURL: audioUrl ?? '/api/v1/chat/attachment?id=voice-sample',
      attachmentType: 'audio',
      createdAt: DateTime.now(),
      status: 'sent',
    );

    // Optimistic UI Append
    final updated = List<ChatMessage>.from(activeMessages.value)..add(tempMsg);
    activeMessages.value = updated;

    bool sentOnline = false;
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/chat/messages');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'channel_id': channel.id,
          'content': content,
          'attachment_url': tempMsg.attachmentURL,
          'attachment_type': 'audio',
        }),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        sentOnline = true;
      }
    } catch (_) {}

    if (!sentOnline) {
      final peers = LocalDiscoveryService.instance.peersNotifier.value;
      for (final peer in peers) {
        P2PTransferService.instance.sendDirectChatMessage(peer.address, peer.port, tempMsg.toJson());
      }
    }

    return true;
  }

  Future<ChatChannel?> createChannel(String name, bool isDirect, List<String> members) async {
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/chat/channels');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'is_direct': isDirect,
          'members': members,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final ch = ChatChannel.fromJson(jsonDecode(res.body));
        await fetchChannels();
        selectChannel(ch);
        return ch;
      }
    } catch (_) {}
    return null;
  }
}
