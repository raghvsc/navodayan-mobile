import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';

class ChatService {
  static const String _requestsKey = 'navodayan_chat_requests';
  static const String _conversationsKey = 'navodayan_chat_conversations';
  static const String _messagesKeyPrefix = 'navodayan_chat_msgs_';

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? get _firestore {
    if (!_isFirebaseAvailable) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // FIRESTORE REAL-TIME STREAMS
  // -------------------------------------------------------------

  /// Stream real-time chat requests for a given user
  Stream<List<ChatRequest>> streamChatRequests(String userId) {
    if (userId.isEmpty || !_isFirebaseAvailable || _firestore == null) return const Stream.empty();

    return _firestore!
        .collection('chat_requests')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return ChatRequest.fromJson(data);
      }).toList();

      // Sort newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      saveChatRequests(list); // async cache update
      return list;
    }).handleError((e) {
      debugPrint('Firestore streamChatRequests error: $e');
      return <ChatRequest>[];
    });
  }

  /// Stream real-time conversations for a given user
  Stream<List<ChatConversation>> streamConversations(String userId) {
    if (userId.isEmpty || !_isFirebaseAvailable || _firestore == null) return const Stream.empty();

    return _firestore!
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return ChatConversation.fromJson(data, userId);
      }).toList();

      // Sort by newest last message time
      list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      saveConversations(list); // async cache update
      return list;
    }).handleError((e) {
      debugPrint('Firestore streamConversations error: $e');
      return <ChatConversation>[];
    });
  }

  /// Stream real-time messages for a conversation
  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    if (conversationId.isEmpty || !_isFirebaseAvailable || _firestore == null) return const Stream.empty();

    return _firestore!
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return ChatMessage.fromJson(data);
      }).toList();

      saveMessages(conversationId, list); // async cache update
      return list;
    }).handleError((e) {
      debugPrint('Firestore streamMessages error: $e');
      return <ChatMessage>[];
    });
  }

  // -------------------------------------------------------------
  // FIRESTORE WRITE OPERATIONS
  // -------------------------------------------------------------

  /// Create and send a chat request in Firestore
  Future<void> sendChatRequestToFirestore(ChatRequest request) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore.collection('chat_requests').doc(request.id).set({
        'id': request.id,
        'senderId': request.senderId,
        'senderName': request.senderName,
        'senderRole': request.senderRole,
        'senderCompany': request.senderCompany,
        'receiverId': request.receiverId,
        'receiverName': request.receiverName,
        'message': request.message,
        'status': request.status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [request.senderId, request.receiverId],
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error sending chat request to Firestore: $e');
    }
  }

  /// Update chat request status (e.g. accepted or declined)
  Future<void> updateChatRequestStatus(String requestId, ChatRequestStatus status) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore.collection('chat_requests').doc(requestId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating request status: $e');
    }
  }

  /// Create or update conversation document in Firestore
  Future<void> createOrUpdateConversationInFirestore({
    required String conversationId,
    required String userAId,
    required String userAName,
    String? userARole,
    String? userACompany,
    required String userBId,
    required String userBName,
    String? userBRole,
    String? userBCompany,
    required String lastMessage,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore.collection('conversations').doc(conversationId).set({
        'id': conversationId,
        'participantIds': [userAId, userBId],
        'participants': {
          userAId: {
            'name': userAName,
            'role': ?userARole,
            'company': ?userACompany,
          },
          userBId: {
            'name': userBName,
            'role': ?userBRole,
            'company': ?userBCompany,
          },
        },
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': userAId,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creating/updating conversation in Firestore: $e');
    }
  }

  /// Send message to Firestore and update parent conversation
  Future<void> sendMessageToFirestore(ChatMessage message) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final batch = firestore.batch();

      final msgDocRef = firestore
          .collection('conversations')
          .doc(message.conversationId)
          .collection('messages')
          .doc(message.id);

      batch.set(msgDocRef, {
        'id': message.id,
        'conversationId': message.conversationId,
        'senderId': message.senderId,
        'receiverId': message.receiverId,
        'text': message.text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      final convDocRef = firestore.collection('conversations').doc(message.conversationId);
      batch.set(convDocRef, {
        'lastMessage': message.text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': message.senderId,
        'unreadCounts.${message.receiverId}': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Error sending message to Firestore: $e');
    }
  }

  /// Mark conversation as read in Firestore
  Future<void> markConversationReadInFirestore(String conversationId, String currentUserId) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore.collection('conversations').doc(conversationId).update({
        'unreadCounts.$currentUserId': 0,
      });
    } catch (e) {
      debugPrint('Error marking conversation read in Firestore: $e');
    }
  }

  // -------------------------------------------------------------
  // LOCAL STORAGE PERSISTENCE (OFFLINE FALLBACK & FAST LOAD)
  // -------------------------------------------------------------

  Future<List<ChatRequest>> getChatRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_requestsKey);
      if (stored != null && stored.isNotEmpty) {
        final List decoded = jsonDecode(stored) as List;
        return decoded
            .map((item) => ChatRequest.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading chat requests: $e');
    }
    return [];
  }

  Future<void> saveChatRequests(List<ChatRequest> requests) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(requests.map((r) => r.toJson()).toList());
      await prefs.setString(_requestsKey, data);
    } catch (e) {
      debugPrint('Error saving chat requests: $e');
    }
  }

  Future<List<ChatConversation>> getConversations([String? currentUserId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_conversationsKey);
      if (stored != null && stored.isNotEmpty) {
        final List decoded = jsonDecode(stored) as List;
        return decoded
            .map((item) => ChatConversation.fromJson(item as Map<String, dynamic>, currentUserId))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
    return [];
  }

  Future<void> saveConversations(List<ChatConversation> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(conversations.map((c) => c.toJson()).toList());
      await prefs.setString(_conversationsKey, data);
    } catch (e) {
      debugPrint('Error saving conversations: $e');
    }
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('$_messagesKeyPrefix$conversationId');
      if (stored != null && stored.isNotEmpty) {
        final List decoded = jsonDecode(stored) as List;
        return decoded
            .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading messages for $conversationId: $e');
    }
    return [];
  }

  Future<void> saveMessages(String conversationId, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(messages.map((m) => m.toJson()).toList());
      await prefs.setString('$_messagesKeyPrefix$conversationId', data);
    } catch (e) {
      debugPrint('Error saving messages for $conversationId: $e');
    }
  }
}

