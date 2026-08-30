import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/chat/chat_models.dart';
import 'package:lifeos_client/core/chat/chat_service.dart';

void main() {
  group('LifeOS Chat & P2P Models Tests', () {
    test('ChatMessage JSON serialization and deserialization', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 'msg-test-123',
        channelID: 'chan-family-lounge',
        senderID: 'panospds',
        senderName: 'Panagiotis',
        content: 'Testing LifeOS Mesh Messenger!',
        attachmentURL: 'https://example.com/image.jpg',
        attachmentType: 'image',
        createdAt: now,
        status: 'delivered',
      );

      final jsonMap = msg.toJson();
      expect(jsonMap['id'], 'msg-test-123');
      expect(jsonMap['content'], 'Testing LifeOS Mesh Messenger!');
      expect(jsonMap['attachment_type'], 'image');

      final fromJson = ChatMessage.fromJson(jsonMap);
      expect(fromJson.id, msg.id);
      expect(fromJson.senderID, 'panospds');
      expect(fromJson.content, msg.content);
    });

    test('ChatChannel JSON serialization and DM detection', () {
      final channelJson = {
        'id': 'dm-test-456',
        'name': 'Panos & Nick',
        'is_direct': true,
        'members': ['panospds', 'nick'],
        'created_at': 1725000000,
        'last_message_at': 1725000050,
      };

      final channel = ChatChannel.fromJson(channelJson);
      expect(channel.id, 'dm-test-456');
      expect(channel.isDirect, isTrue);
      expect(channel.members.length, 2);
    });

    test('ChatService optimistic message dispatch', () async {
      final chatService = ChatService.instance;
      final channel = ChatChannel(
        id: 'chan-test-dispatch',
        name: 'Test Channel',
        isDirect: false,
        members: ['panospds'],
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );

      chatService.activeChannel.value = channel;
      chatService.activeMessages.value = [];

      final success = await chatService.sendMessage('Hello Optimistic UI!');
      expect(success, isTrue);
      expect(chatService.activeMessages.value.isNotEmpty, isTrue);
      expect(chatService.activeMessages.value.last.content, 'Hello Optimistic UI!');
    });

    test('ChatService optimistic voice message dispatch', () async {
      final chatService = ChatService.instance;
      final channel = ChatChannel(
        id: 'chan-test-voice',
        name: 'Voice Channel',
        isDirect: false,
        members: ['panospds'],
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );

      chatService.activeChannel.value = channel;
      chatService.activeMessages.value = [];

      final success = await chatService.sendVoiceMessage(const Duration(seconds: 15));
      expect(success, isTrue);
      expect(chatService.activeMessages.value.isNotEmpty, isTrue);
      final voiceMsg = chatService.activeMessages.value.last;
      expect(voiceMsg.attachmentType, 'audio');
      expect(voiceMsg.content, contains('15s'));
    });
  });
}
