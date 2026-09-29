import 'package:flutter/material.dart';

class ChatArea extends StatefulWidget {
  final dynamic chat;
  final Function(String) onSendMessage;
  final bool isLoading;

  const ChatArea({
    super.key,
    required this.chat,
    required this.onSendMessage,
    required this.isLoading,
  });

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _animationController.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────
  // SEND MESSAGE
  // ─────────────────────────────────────────

  void _send() {
    final message = _controller.text.trim();

    if (message.isEmpty) {
      return;
    }

    if (widget.isLoading) {
      return;
    }

    widget.onSendMessage(message);

    _controller.clear();

    _scrollToBottom();
  }

  // ─────────────────────────────────────────
  // SCROLL TO BOTTOM
  // ─────────────────────────────────────────

  void _scrollToBottom() {
    Future.delayed(
      const Duration(milliseconds: 150),
          () {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chat = widget.chat;

    return Column(
      children: [
        // ─────────────────────────────────────
        // TOP BAR
        // ─────────────────────────────────────

        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(
            horizontal: 26,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF252525),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chat?.title ?? 'New Chat',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.more_horiz,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),

        // ─────────────────────────────────────
        // CHAT MESSAGES
        // ─────────────────────────────────────

        Expanded(
          child: chat == null || chat.messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              32,
              30,
              32,
              180,
            ),
            itemCount: chat.messages.length +
                (widget.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator
              if (widget.isLoading &&
                  index == chat.messages.length) {
                return _buildThinkingIndicator();
              }

              final message = chat.messages[index];

              return _buildMessage(
                text: message.text,
                isUser: message.isUser,
              );
            },
          ),
        ),

        // ─────────────────────────────────────
        // INPUT
        // ─────────────────────────────────────

        _buildInput(),
      ],
    );
  }

  // ─────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 42,
            color: Colors.white24,
          ),
          SizedBox(height: 18),
          Text(
            'How can I help you?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ask anything and Memory AI will remember what matters.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // MESSAGE BUBBLE
  // ─────────────────────────────────────────

  Widget _buildMessage({
    required String text,
    required bool isUser,
  }) {
    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 850,
        ),
        margin: const EdgeInsets.only(
          bottom: 24,
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isUser)
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(
                  right: 12,
                  top: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius:
                  BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF292929),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 17,
                  color: Colors.white70,
                ),
              ),

            Flexible(
              child: Container(
                padding: isUser
                    ? const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 13,
                )
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xFF242424)
                      : Colors.transparent,
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child: SelectableText(
                  text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(
                      isUser ? 0.92 : 0.88,
                    ),
                    fontSize: 15.5,
                    height: 1.55,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // THINKING INDICATOR
  // ─────────────────────────────────────────

  Widget _buildThinkingIndicator() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final progress =
            _animationController.value;

        return Container(
          margin: const EdgeInsets.only(
            bottom: 24,
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(
                  right: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius:
                  BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF292929),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 17,
                  color: Colors.white70,
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius:
                  BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF242424),
                  ),
                ),
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    _buildDot(progress, 0.0),
                    const SizedBox(width: 5),
                    _buildDot(progress, 0.2),
                    const SizedBox(width: 5),
                    _buildDot(progress, 0.4),
                    const SizedBox(width: 10),
                    const Text(
                      'Thinking...',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // ANIMATED DOT
  // ─────────────────────────────────────────

  Widget _buildDot(
      double progress,
      double offset,
      ) {
    final value =
        (progress + offset) % 1.0;

    double opacity;

    if (value < 0.5) {
      opacity =
          0.35 + (value * 2 * 0.65);
    } else {
      opacity =
          1.0 - ((value - 0.5) * 2 * 0.65);
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // INPUT AREA
  // ─────────────────────────────────────────

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        18,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 950,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF191919),
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF292929),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,

                      // Disable input while AI responds.
                      enabled: !widget.isLoading,

                      minLines: 1,
                      maxLines: 6,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),

                      // Press ENTER to send.
                      onSubmitted: (_) {
                        _send();
                      },

                      decoration:
                      const InputDecoration(
                        hintText:
                        'Describe a situation...',
                        hintStyle: TextStyle(
                          color: Colors.white38,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding:
                    const EdgeInsets.only(
                      right: 8,
                      bottom: 8,
                    ),
                    child: GestureDetector(
                      onTap: widget.isLoading
                          ? null
                          : _send,
                      child: AnimatedContainer(
                        duration:
                        const Duration(
                          milliseconds: 200,
                        ),
                        width: 40,
                        height: 40,
                        decoration:
                        BoxDecoration(
                          color: widget.isLoading
                              ? const Color(
                            0xFF252525,
                          )
                              : const Color(
                            0xFF292929,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: widget.isLoading
                            ? const Padding(
                          padding:
                          EdgeInsets.all(
                            11,
                          ),
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                            Colors.white38,
                          ),
                        )
                            : const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Memory AI can make mistakes. Verify important decisions.',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}