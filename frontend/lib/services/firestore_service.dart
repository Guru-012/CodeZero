import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/home_screen.dart';

class FirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ─────────────────────────────────────────
  // CURRENT USER
  // ─────────────────────────────────────────

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user is logged in.');
    }

    return user.uid;
  }

  // ─────────────────────────────────────────
  // USER CHAT COLLECTION
  // ─────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> get _chatCollection {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('chats');
  }

  // ─────────────────────────────────────────
  // CREATE CHAT
  // ─────────────────────────────────────────

  Future<String> createChat({
    String title = 'New Chat',
  }) async {
    final doc = await _chatCollection.add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // ─────────────────────────────────────────
  // LOAD ALL CHATS
  // ─────────────────────────────────────────

  Future<List<ChatSession>> loadChats() async {
    final snapshot = await _chatCollection
        .orderBy(
      'updatedAt',
      descending: true,
    )
        .get();

    final List<ChatSession> chats = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final messagesData =
          data['messages'] as List<dynamic>? ?? [];

      final messages = messagesData.map((message) {
        final messageData =
        Map<String, dynamic>.from(message);

        return ChatMessage(
          text: messageData['text'] ?? '',
          isUser: messageData['isUser'] ?? false,
        );
      }).toList();

      chats.add(
        ChatSession(
          id: doc.id,
          title: data['title'] ?? 'New Chat',
          messages: messages,
        ),
      );
    }

    return chats;
  }

  // ─────────────────────────────────────────
  // SAVE MESSAGE
  // ─────────────────────────────────────────

  Future<void> saveMessage({
    required String chatId,
    required String text,
    required bool isUser,
  }) async {
    final chatRef =
    _chatCollection.doc(chatId);

    await chatRef.update({
      'messages': FieldValue.arrayUnion([
        {
          'text': text,
          'isUser': isUser,
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────
  // RENAME CHAT
  // ─────────────────────────────────────────

  Future<void> renameChat({
    required String chatId,
    required String newName,
  }) async {
    await _chatCollection.doc(chatId).update({
      'title': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────
  // DELETE CHAT
  // ─────────────────────────────────────────

  Future<void> deleteChat(String chatId) async {
    await _chatCollection.doc(chatId).delete();
  }
}