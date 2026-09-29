import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../themes/app_theme.dart';

class Sidebar extends StatelessWidget {
  final List<ChatSession> chats;
  final String? activeChatId;

  final VoidCallback onNewChat;
  final Function(String) onSelectChat;
  final Function(String) onDeleteChat;
  final Function(String, String) onRenameChat;

  // Firebase user
  final User? user;

  const Sidebar({
    super.key,
    required this.chats,
    required this.activeChatId,
    required this.onNewChat,
    required this.onSelectChat,
    required this.onDeleteChat,
    required this.onRenameChat,
    required this.user,
  });

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> _logout(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) {
        return;
      }

      // Directly go to LoginScreen
      // and remove HomeScreen from navigation stack.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      debugPrint(
        'LOGOUT ERROR: $e',
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? 'No email';

    // Create username from email.
    //
    // example@gmail.com
    //       ↓
    // example

    final username = email.contains('@')
        ? email.split('@').first
        : 'Account';

    return Container(
      width: 260,

      color: AppTheme.sidebar,

      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          // =================================================
          // LOGO
          // =================================================

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),

            child: Row(
              children: [
                Icon(
                  Icons.memory,
                  size: 24,
                  color: AppTheme.primaryText,
                ),

                SizedBox(width: 10),

                Text(
                  'CodeZero',

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // =================================================
          // NEW CHAT
          // =================================================

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: onNewChat,

              icon: const Icon(
                Icons.add,
              ),

              label: const Text(
                'New Chat',
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor:
                AppTheme.primaryText,

                side: const BorderSide(
                  color: AppTheme.border,
                ),

                padding:
                const EdgeInsets.symmetric(
                  vertical: 14,
                ),

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // =================================================
          // RECENTS
          // =================================================

          const Text(
            'RECENTS',

            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: AppTheme.secondaryText,
            ),
          ),

          const SizedBox(height: 12),

          // =================================================
          // CHAT LIST
          // =================================================

          Expanded(
            child: chats.isEmpty
                ? const Center(
              child: Text(
                'No conversations yet',

                style: TextStyle(
                  color:
                  AppTheme.secondaryText,
                  fontSize: 12,
                ),
              ),
            )
                : ListView.builder(
              itemCount:
              chats.length,

              itemBuilder:
                  (context, index) {
                final chat =
                chats[index];

                final isActive =
                    chat.id ==
                        activeChatId;

                return _chatItem(
                  context,
                  chat,
                  isActive,
                );
              },
            ),
          ),

          // =================================================
          // ACCOUNT
          // =================================================

          Container(
            padding:
            const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: AppTheme.surface,

              borderRadius:
              BorderRadius.circular(10),

              border: Border.all(
                color: AppTheme.border,
              ),
            ),

            child: Row(
              children: [
                // =================================================
                // USER AVATAR
                // =================================================

                CircleAvatar(
                  radius: 17,

                  backgroundColor:
                  AppTheme.surfaceLight,

                  child: Text(
                    username.isNotEmpty
                        ? username[0]
                        .toUpperCase()
                        : 'U',

                    style:
                    const TextStyle(
                      color:
                      AppTheme.primaryText,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // =================================================
                // USER DETAILS
                // =================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      Text(
                        username,

                        maxLines: 1,

                        overflow:
                        TextOverflow.ellipsis,

                        style:
                        const TextStyle(
                          color:
                          AppTheme.primaryText,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        email,

                        maxLines: 1,

                        overflow:
                        TextOverflow.ellipsis,

                        style:
                        const TextStyle(
                          color:
                          AppTheme.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================
                // LOGOUT BUTTON
                // =================================================

                IconButton(
                  tooltip: 'Logout',

                  onPressed: () {
                    _showLogoutDialog(
                      context,
                    );
                  },

                  icon: const Icon(
                    Icons.logout,
                    size: 19,
                    color:
                    AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // LOGOUT CONFIRMATION
  // =====================================================

  Future<void> _showLogoutDialog(
      BuildContext context,
      ) async {
    final shouldLogout =
    await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor:
          AppTheme.surface,

          title: const Text(
            'Logout?',

            style: TextStyle(
              color:
              AppTheme.primaryText,
            ),
          ),

          content: const Text(
            'Are you sure you want to logout?',

            style: TextStyle(
              color:
              AppTheme.secondaryText,
            ),
          ),

          actions: [
            // CANCEL
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child: const Text(
                'Cancel',

                style: TextStyle(
                  color:
                  AppTheme.secondaryText,
                ),
              ),
            ),

            // LOGOUT
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child: const Text(
                'Logout',

                style: TextStyle(
                  color:
                  AppTheme.primaryText,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _logout(context);
    }
  }

  // =====================================================
  // CHAT ITEM
  // =====================================================

  Widget _chatItem(
      BuildContext context,
      ChatSession chat,
      bool isActive,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 4,
      ),

      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.surfaceLight
            : Colors.transparent,

        borderRadius:
        BorderRadius.circular(7),
      ),

      child: ListTile(
        dense: true,

        contentPadding:
        const EdgeInsets.only(
          left: 10,
          right: 4,
        ),

        title: Text(
          chat.title,

          maxLines: 1,

          overflow:
          TextOverflow.ellipsis,

          style: TextStyle(
            color: isActive
                ? AppTheme.primaryText
                : AppTheme.secondaryText,

            fontSize: 13,
          ),
        ),

        // =================================================
        // CHAT OPTIONS
        // =================================================

        trailing:
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_horiz,
            size: 18,
            color:
            AppTheme.secondaryText,
          ),

          color: AppTheme.surface,

          onSelected:
              (value) async {
            // -------------------------------------------------
            // RENAME
            // -------------------------------------------------

            if (value == 'rename') {
              final newName =
              await _showRenameDialog(
                context,
                chat,
              );

              if (newName != null &&
                  newName.trim()
                      .isNotEmpty) {
                onRenameChat(
                  chat.id,
                  newName.trim(),
                );
              }
            }

            // -------------------------------------------------
            // DELETE
            // -------------------------------------------------

            if (value == 'delete') {
              onDeleteChat(
                chat.id,
              );
            }
          },

          itemBuilder:
              (context) {
            return [
              const PopupMenuItem(
                value: 'rename',

                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                    ),

                    SizedBox(width: 10),

                    Text(
                      'Rename',
                    ),
                  ],
                ),
              ),

              const PopupMenuItem(
                value: 'delete',

                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                    ),

                    SizedBox(width: 10),

                    Text(
                      'Delete',
                    ),
                  ],
                ),
              ),
            ];
          },
        ),

        // =================================================
        // SELECT CHAT
        // =================================================

        onTap: () {
          onSelectChat(
            chat.id,
          );
        },
      ),
    );
  }

  // =====================================================
  // RENAME DIALOG
  // =====================================================

  Future<String?> _showRenameDialog(
      BuildContext context,
      ChatSession chat,
      ) async {
    final controller =
    TextEditingController(
      text: chat.title == 'New Chat'
          ? ''
          : chat.title,
    );

    final newName =
    await showDialog<String>(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor:
          AppTheme.surface,

          title: const Text(
            'Rename chat',

            style: TextStyle(
              color:
              AppTheme.primaryText,
            ),
          ),

          content: TextField(
            controller: controller,

            autofocus: true,

            maxLength: 50,

            style: const TextStyle(
              color:
              AppTheme.primaryText,
            ),

            decoration:
            const InputDecoration(
              hintText:
              'Enter chat name',

              hintStyle:
              TextStyle(
                color:
                AppTheme.secondaryText,
              ),

              counterStyle:
              TextStyle(
                color:
                AppTheme.secondaryText,
              ),

              enabledBorder:
              UnderlineInputBorder(
                borderSide:
                BorderSide(
                  color:
                  AppTheme.border,
                ),
              ),

              focusedBorder:
              UnderlineInputBorder(
                borderSide:
                BorderSide(
                  color:
                  AppTheme.primaryText,
                ),
              ),
            ),

            onSubmitted:
                (value) {
              Navigator.pop(
                context,
                value.trim(),
              );
            },
          ),

          actions: [
            // CANCEL
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },

              child: const Text(
                'Cancel',

                style: TextStyle(
                  color:
                  AppTheme.secondaryText,
                ),
              ),
            ),

            // SAVE
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  controller.text
                      .trim(),
                );
              },

              child: const Text(
                'Save',

                style: TextStyle(
                  color:
                  AppTheme.primaryText,
                ),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return newName;
  }
}