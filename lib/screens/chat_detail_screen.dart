import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import 'meeting_screen.dart';
import 'profile_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String participantId;
  final String participantName;
  final String? participantRole;
  final String? participantCompany;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.participantId,
    required this.participantName,
    this.participantRole,
    this.participantCompany,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.loadMessages(widget.conversationId);
      chatProvider.markConversationRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(
      conversationId: widget.conversationId,
      senderId: auth.user!.id,
      receiverId: widget.participantId,
      text: text,
    );

    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _confirmAndStartVideoCall() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final colors = AppColors.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.videocam_rounded, color: colors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1-on-1 Video Call',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'with ${widget.participantName}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'A private call invitation will be sent to ${widget.participantName}. The video call room is strictly 1-to-1 and will start once accepted.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.videocam_rounded, size: 20),
                        label: const Text('Start Call'),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _initiateVideoCall();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _initiateVideoCall() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final convSnippet = widget.conversationId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final shortSnippet = convSnippet.length > 8 ? convSnippet.substring(0, 8) : convSnippet;
    final roomName = 'call_${shortSnippet}_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';

    // Send call invite to chat
    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(
      conversationId: widget.conversationId,
      senderId: auth.user!.id,
      receiverId: widget.participantId,
      text: '[CALL_INVITE:$roomName]',
    );

    // Open meeting screen for caller
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingScreen(
          customRoomName: roomName,
          peerName: widget.participantName,
        ),
      ),
    );
  }

  void _acceptVideoCall(String roomName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingScreen(
          customRoomName: roomName,
          peerName: widget.participantName,
        ),
      ),
    );
  }

  void _declineVideoCall(String roomName) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final chatProvider = context.read<ChatProvider>();
    chatProvider.sendMessage(
      conversationId: widget.conversationId,
      senderId: auth.user!.id,
      receiverId: widget.participantId,
      text: '[CALL_DECLINED:$roomName]',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final currentUserId = auth.user?.id ?? '';
    final initials = widget.participantName.isNotEmpty ? widget.participantName[0].toUpperCase() : 'N';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(profileId: widget.participantId),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.primary,
                child: Text(
                  initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.participantName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.participantRole != null && widget.participantRole!.isNotEmpty)
                      Text(
                        widget.participantRole!,
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            tooltip: '1-on-1 Video Call',
            onPressed: _confirmAndStartVideoCall,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'View Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(profileId: widget.participantId),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatProvider.getMessagesStream(widget.conversationId),
              initialData: chatProvider.getLoadedMessages(widget.conversationId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mark_chat_read_outlined, size: 48, color: colors.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Say hi to ${widget.participantName}!',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your chat conversation is live and private.',
                            style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Auto-scroll when messages update
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUserId;
                    final timeStr = DateFormat('h:mm a').format(msg.timestamp);

                    return _buildMessageBubble(msg, isMe, timeStr, colors);
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(colors),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, String timeStr, ThemePalette colors) {
    if (msg.text.startsWith('[CALL_INVITE:') && msg.text.endsWith(']')) {
      final roomName = msg.text.substring(13, msg.text.length - 1);
      return _buildCallInviteBubble(msg, isMe, roomName, timeStr, colors);
    }

    if (msg.text.startsWith('[CALL_DECLINED:') && msg.text.endsWith(']')) {
      return _buildCallDeclinedBubble(isMe, timeStr, colors);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? colors.primary : colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: isMe ? null : Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : colors.textPrimary,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isMe ? Colors.white.withValues(alpha: 0.7) : colors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 10.5,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallInviteBubble(
    ChatMessage msg,
    bool isMe,
    String roomName,
    String timeStr,
    ThemePalette colors,
  ) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? colors.primary.withValues(alpha: 0.4) : Colors.green.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isMe ? colors.primary : Colors.green).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isMe ? colors.primary : Colors.green).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.videocam_rounded,
                    color: isMe ? colors.primary : Colors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? '1-on-1 Video Call Initiated' : 'Incoming 1-on-1 Video Call',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isMe
                            ? 'Waiting for ${widget.participantName}...'
                            : '${widget.participantName} invited you to video call',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isMe)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.videocam_rounded, size: 18),
                  label: const Text('Rejoin Call'),
                  onPressed: () => _acceptVideoCall(roomName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _declineVideoCall(roomName),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.videocam_rounded, size: 18),
                      label: const Text('Accept Call'),
                      onPressed: () => _acceptVideoCall(roomName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                timeStr,
                style: TextStyle(fontSize: 10, color: colors.textSecondary.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallDeclinedBubble(bool isMe, String timeStr, ThemePalette colors) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_missed_rounded, size: 16, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              isMe ? 'Call was declined by you' : 'Call was declined',
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: TextStyle(fontSize: 10, color: colors.textSecondary.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer(ThemePalette colors) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _handleSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: colors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _handleSendMessage,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
