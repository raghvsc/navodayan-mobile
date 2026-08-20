import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../models/notification_item.dart';
import '../models/profile.dart';
import '../services/analytics_service.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  NotificationProvider? _notificationProvider;
  String? _currentUserId;

  List<ChatRequest> _requests = [];
  List<ChatConversation> _conversations = [];
  final Map<String, List<ChatMessage>> _messagesByConversation = {};
  bool _loading = true;

  StreamSubscription<List<ChatRequest>>? _requestsSub;
  StreamSubscription<List<ChatConversation>>? _conversationsSub;

  ChatProvider() {
    _init();
  }

  void updateNotificationProvider(NotificationProvider notifProvider) {
    _notificationProvider = notifProvider;
  }

  void updateAuthProvider(AuthProvider authProvider) {
    final nextUserId = authProvider.user?.id;
    if (nextUserId != _currentUserId) {
      _currentUserId = nextUserId;
      _setupUserStreams();
    }
  }

  List<ChatRequest> get requests => _requests;
  List<ChatRequest> get pendingRequests =>
      _requests.where((r) => r.status == ChatRequestStatus.pending && r.receiverId == _currentUserId).toList();
  List<ChatConversation> get conversations => _conversations;
  bool get loading => _loading;

  int get totalUnreadCount =>
      _conversations.fold<int>(0, (sum, c) => sum + c.unreadCount) +
      pendingRequests.length;

  Future<void> _init() async {
    _requests = await _chatService.getChatRequests();
    _conversations = await _chatService.getConversations(_currentUserId);
    _loading = false;
    notifyListeners();
  }

  void _setupUserStreams() {
    _requestsSub?.cancel();
    _conversationsSub?.cancel();

    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return;

    _requestsSub = _chatService.streamChatRequests(uid).listen((reqs) {
      _requests = reqs;
      notifyListeners();
    });

    _conversationsSub = _chatService.streamConversations(uid).listen((convs) {
      _conversations = convs;
      notifyListeners();
    });
  }

  bool hasChat(String participantId) {
    return _conversations.any((c) => c.participantId == participantId);
  }

  ChatRequest? getPendingRequestFor(String participantId) {
    try {
      return _requests.firstWhere(
        (r) =>
            (r.senderId == participantId || r.receiverId == participantId) &&
            r.status == ChatRequestStatus.pending,
      );
    } catch (_) {
      return null;
    }
  }

  String _getConversationId(String userA, String userB) {
    final list = [userA, userB]..sort();
    return 'conv_${list[0]}_${list[1]}';
  }

  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    return _chatService.streamMessages(conversationId);
  }

  Future<void> sendChatRequest({
    required String senderId,
    required String senderName,
    String? senderRole,
    String? senderCompany,
    required Profile recipient,
    String? message,
  }) async {
    final reqId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    final request = ChatRequest(
      id: reqId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      senderCompany: senderCompany,
      receiverId: recipient.id,
      receiverName: recipient.displayName,
      message: message,
      status: ChatRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    _requests.insert(0, request);
    notifyListeners();

    // Firestore & Local Cache
    await _chatService.sendChatRequestToFirestore(request);
    await _chatService.saveChatRequests(_requests);

    // Analytics
    AnalyticsService.instance.logChatRequestSent(
      recipientId: recipient.id,
      recipientName: recipient.displayName,
    );

    // Dispatch Push & In-app Notification
    _notificationProvider?.addNotification(
      title: 'Chat Request Sent to ${recipient.displayName}',
      body: 'Your chat request was sent. You will be able to text once they accept.',
      type: NotificationType.chatRequest,
      data: {'requestId': reqId, 'recipientId': recipient.id},
      showPush: true,
    );
  }

  Future<void> acceptChatRequest(String requestId) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final req = _requests[index];
    final updatedReq = req.copyWith(status: ChatRequestStatus.accepted);
    _requests[index] = updatedReq;

    final convId = _getConversationId(req.senderId, req.receiverId);

    // Check if conversation exists locally
    final convIndex = _conversations.indexWhere((c) => c.id == convId);
    final initialMessage = req.message?.isNotEmpty == true
        ? req.message!
        : 'Chat request accepted. You can now chat!';

    if (convIndex == -1) {
      final newConv = ChatConversation(
        id: convId,
        participantId: req.senderId,
        participantName: req.senderName,
        participantRole: req.senderRole,
        participantCompany: req.senderCompany,
        lastMessage: initialMessage,
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
      );
      _conversations.insert(0, newConv);
    }

    // Sync to Firestore
    await _chatService.updateChatRequestStatus(requestId, ChatRequestStatus.accepted);
    await _chatService.createOrUpdateConversationInFirestore(
      conversationId: convId,
      userAId: req.receiverId,
      userAName: req.receiverName,
      userBId: req.senderId,
      userBName: req.senderName,
      userBRole: req.senderRole,
      userBCompany: req.senderCompany,
      lastMessage: initialMessage,
    );

    // Add initial message if request had intro note
    final messages = await _chatService.getMessages(convId);
    if (req.message != null && req.message!.isNotEmpty) {
      final msg = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: convId,
        senderId: req.senderId,
        receiverId: req.receiverId,
        text: req.message!,
        timestamp: req.createdAt,
        isRead: true,
      );
      messages.add(msg);
      await _chatService.sendMessageToFirestore(msg);
      _messagesByConversation[convId] = messages;
    }

    notifyListeners();
    await _chatService.saveChatRequests(_requests);
    await _chatService.saveConversations(_conversations);

    // Analytics
    AnalyticsService.instance.logChatRequestResponded(
      requestId: requestId,
      action: 'accepted',
    );

    _notificationProvider?.addNotification(
      title: 'Chat Request Accepted',
      body: 'You accepted chat request from ${req.senderName}. Start talking now!',
      type: NotificationType.chatAccepted,
      data: {'conversationId': convId, 'participantId': req.senderId},
      showPush: true,
    );
  }

  Future<void> declineChatRequest(String requestId) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    _requests[index] = _requests[index].copyWith(status: ChatRequestStatus.declined);
    notifyListeners();

    await _chatService.updateChatRequestStatus(requestId, ChatRequestStatus.declined);
    await _chatService.saveChatRequests(_requests);

    AnalyticsService.instance.logChatRequestResponded(
      requestId: requestId,
      action: 'declined',
    );
  }

  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    final msgs = await _chatService.getMessages(conversationId);
    _messagesByConversation[conversationId] = msgs;
    notifyListeners();
    return msgs;
  }

  List<ChatMessage> getLoadedMessages(String conversationId) {
    return _messagesByConversation[conversationId] ?? [];
  }

  void updateMessagesForConversation(String conversationId, List<ChatMessage> messages) {
    _messagesByConversation[conversationId] = messages;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final msgId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final newMsg = ChatMessage(
      id: msgId,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      text: text.trim(),
      timestamp: DateTime.now(),
      isRead: true,
    );

    final currentMsgs = List<ChatMessage>.from(_messagesByConversation[conversationId] ?? []);
    currentMsgs.add(newMsg);
    _messagesByConversation[conversationId] = currentMsgs;

    // Update conversation locally
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex != -1) {
      final conv = _conversations[convIndex];
      _conversations[convIndex] = conv.copyWith(
        lastMessage: text.trim(),
        lastMessageTime: DateTime.now(),
      );
      final updated = _conversations.removeAt(convIndex);
      _conversations.insert(0, updated);
    }

    notifyListeners();

    // Sync to Firestore & cache
    await _chatService.sendMessageToFirestore(newMsg);
    await _chatService.saveMessages(conversationId, currentMsgs);
    await _chatService.saveConversations(_conversations);

    // Analytics
    AnalyticsService.instance.logChatMessageSent(
      conversationId: conversationId,
      receiverId: receiverId,
    );
  }

  Future<void> markConversationRead(String conversationId) async {
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex != -1) {
      _conversations[convIndex] = _conversations[convIndex].copyWith(unreadCount: 0);
      notifyListeners();
      await _chatService.saveConversations(_conversations);
    }
    if (_currentUserId != null) {
      await _chatService.markConversationReadInFirestore(conversationId, _currentUserId!);
    }
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    _conversationsSub?.cancel();
    super.dispose();
  }
}

