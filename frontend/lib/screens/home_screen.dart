import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../themes/app_theme.dart';
import '../widgets/chatarea.dart';
import '../widgets/sidebar.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class ChatSession {
  final String id;
  String title;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // =====================================================
  // STATE
  // =====================================================

  final List<ChatSession> _chats = [];

  final FirestoreService _firestoreService =
  FirestoreService();

  String? _activeChatId;

  bool _isLoading = false;
  bool _isLoadingChats = true;

  // =====================================================
  // INITIALIZE
  // =====================================================

  @override
  void initState() {
    super.initState();

    _loadChats();
  }

  // =====================================================
  // LOAD CHATS FROM FIRESTORE
  // =====================================================

  Future<void> _loadChats() async {
    try {
      final chats =
      await _firestoreService.loadChats();

      if (!mounted) {
        return;
      }

      setState(() {
        _chats.clear();

        _chats.addAll(chats);

        if (_chats.isNotEmpty) {
          _activeChatId = _chats.first.id;
        }

        _isLoadingChats = false;
      });
    } catch (e) {
      debugPrint(
        'FIRESTORE LOAD ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingChats = false;
      });
    }
  }

  // =====================================================
  // CREATE NEW CHAT
  // =====================================================

  Future<void> _createNewChat() async {
    if (_isLoading) {
      return;
    }

    try {
      // -------------------------------------------------
      // 1. CREATE CHAT IN FIRESTORE
      // -------------------------------------------------

      final chatId =
      await _firestoreService.createChat();

      // -------------------------------------------------
      // 2. CREATE SAME CHAT IN FASTAPI / HINDSIGHT
      // -------------------------------------------------

      await ApiService.createChat(
        chatId,
      );

      // -------------------------------------------------
      // 3. CREATE LOCAL CHAT OBJECT
      // -------------------------------------------------

      final newChat = ChatSession(
        id: chatId,
        title: 'New Chat',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _chats.insert(
          0,
          newChat,
        );

        _activeChatId =
            newChat.id;
      });
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('CREATE CHAT FAILED');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CREATE CHAT ERROR:\n$e',
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  // =====================================================
  // SELECT CHAT
  // =====================================================

  void _selectChat(String chatId) {
    if (_isLoading) {
      return;
    }

    setState(() {
      _activeChatId = chatId;
    });
  }

  // =====================================================
  // RENAME CHAT
  // =====================================================

  Future<void> _renameChat(
      String chatId,
      String newName,
      ) async {
    if (newName.trim().isEmpty) {
      return;
    }

    final cleanName =
    newName.trim();

    // ---------------------------------------------------
    // UPDATE UI IMMEDIATELY
    // ---------------------------------------------------

    setState(() {
      final chatIndex =
      _chats.indexWhere(
            (chat) => chat.id == chatId,
      );

      if (chatIndex != -1) {
        _chats[chatIndex].title =
            cleanName;
      }
    });

    // ---------------------------------------------------
    // SAVE TO FIRESTORE
    // ---------------------------------------------------

    try {
      await _firestoreService.renameChat(
        chatId: chatId,
        newName: cleanName,
      );
    } catch (e) {
      debugPrint(
        'RENAME CHAT ERROR: $e',
      );
    }
  }

  // =====================================================
  // DELETE CHAT
  // =====================================================

  Future<void> _deleteChat(
      String chatId,
      ) async {
    if (_isLoading) {
      return;
    }

    // ---------------------------------------------------
    // REMOVE FROM UI
    // ---------------------------------------------------

    setState(() {
      _chats.removeWhere(
            (chat) => chat.id == chatId,
      );

      if (_activeChatId == chatId) {
        if (_chats.isNotEmpty) {
          _activeChatId =
              _chats.first.id;
        } else {
          _activeChatId = null;
        }
      }
    });

    // ---------------------------------------------------
    // DELETE FROM FIRESTORE
    // ---------------------------------------------------

    try {
      await _firestoreService.deleteChat(
        chatId,
      );
    } catch (e) {
      debugPrint(
        'DELETE CHAT ERROR: $e',
      );
    }
  }

  // =====================================================
  // SEND MESSAGE
  // =====================================================

  Future<void> _sendMessage(
      String message,
      ) async {
    final cleanMessage =
    message.trim();

    if (cleanMessage.isEmpty) {
      return;
    }

    if (_isLoading) {
      return;
    }

    // ---------------------------------------------------
    // MAKE SURE USER IS LOGGED IN
    // ---------------------------------------------------

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    // ---------------------------------------------------
    // MAKE SURE CHAT EXISTS
    // ---------------------------------------------------

    if (_activeChatId == null) {
      await _createNewChat();
    }

    // If creating the chat failed,
    // stop here.
    if (_activeChatId == null) {
      return;
    }

    // ---------------------------------------------------
    // FIND ACTIVE CHAT
    // ---------------------------------------------------

    final chat =
    _chats.firstWhere(
          (chat) =>
      chat.id == _activeChatId,
    );

    // ---------------------------------------------------
    // ADD USER MESSAGE TO UI
    // ---------------------------------------------------

    setState(() {
      // Automatically create title
      // from first message.

      if (chat.messages.isEmpty) {
        chat.title =
            _generateChatTitle(
              cleanMessage,
            );
      }

      chat.messages.add(
        ChatMessage(
          text: cleanMessage,
          isUser: true,
        ),
      );

      _isLoading = true;
    });

    try {
      // =================================================
      // SAVE USER MESSAGE TO FIRESTORE
      // =================================================

      await _firestoreService.saveMessage(
        chatId: chat.id,
        text: cleanMessage,
        isUser: true,
      );

      // -------------------------------------------------
      // SAVE AUTO-GENERATED TITLE
      // -------------------------------------------------

      if (chat.messages.length == 1) {
        await _firestoreService.renameChat(
          chatId: chat.id,
          newName: chat.title,
        );
      }

      // =================================================
      // SEND TO FASTAPI
      // =================================================
      //
      // IMPORTANT:
      //
      // We send CHAT ID, not Firebase UID.
      //
      // This allows the backend/Hindsight
      // to maintain separate memory for
      // every conversation.
      //
      // =================================================

      final aiResponse =
      await ApiService.sendMessage(
        chat.id,
        cleanMessage,
      );

      if (!mounted) {
        return;
      }

      // =================================================
      // ADD AI RESPONSE TO UI
      // =================================================

      setState(() {
        chat.messages.add(
          ChatMessage(
            text: aiResponse,
            isUser: false,
          ),
        );

        _isLoading = false;
      });

      // =================================================
      // SAVE AI RESPONSE TO FIRESTORE
      // =================================================

      await _firestoreService.saveMessage(
        chatId: chat.id,
        text: aiResponse,
        isUser: false,
      );
    } catch (e) {
      debugPrint(
        'API/FIRESTORE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        chat.messages.add(
          ChatMessage(
            text:
            'Sorry, I could not connect '
                'to the AI server.\n\n'
                'Please make sure FastAPI '
                'is running.',
            isUser: false,
          ),
        );

        _isLoading = false;
      });
    }
  }

  // =====================================================
  // GENERATE CHAT TITLE
  // =====================================================

  String _generateChatTitle(
      String message,
      ) {
    final cleanMessage =
    message.trim();

    if (cleanMessage.length <= 30) {
      return cleanMessage;
    }

    return '${cleanMessage.substring(0, 30)}...';
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    ChatSession? activeChat;

    // ---------------------------------------------------
    // FIND ACTIVE CHAT
    // ---------------------------------------------------

    for (final chat in _chats) {
      if (chat.id == _activeChatId) {
        activeChat = chat;
        break;
      }
    }

    // ---------------------------------------------------
    // CURRENT FIREBASE USER
    // ---------------------------------------------------

    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
      AppTheme.background,

      body: Row(
        children: [
          // =================================================
          // SIDEBAR
          // =================================================

          Sidebar(
            chats: _chats,

            activeChatId:
            _activeChatId,

            onNewChat:
            _isLoading ||
                _isLoadingChats
                ? () {}
                : _createNewChat,

            onSelectChat:
            _selectChat,

            onDeleteChat:
            _deleteChat,

            onRenameChat:
            _renameChat,

            user: user,
          ),

          // =================================================
          // MAIN CHAT
          // =================================================

          Expanded(
            child: Container(
              color:
              AppTheme.background,

              child:
              _isLoadingChats
                  ? const Center(
                child:
                CircularProgressIndicator(),
              )
                  : ChatArea(
                chat: activeChat,

                onSendMessage:
                _sendMessage,

                isLoading:
                _isLoading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}