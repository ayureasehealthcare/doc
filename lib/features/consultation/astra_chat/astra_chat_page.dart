import 'package:flutter/material.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:provider/provider.dart';
import 'package:doctro/core/astra/astra_core.dart';
import 'package:doctro/core/astra/widgets/widgets.dart';
import 'package:doctro/theme/app_motion.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/widgets/osler_state_view.dart';
import 'package:doctro/widgets/swastu.dart';
import 'package:doctro/widgets/content_origin_badge.dart';

/// Astra AI Chat Page
///
/// A dedicated chat interface for interacting with Astra AI Brain.
/// This page is separate from the existing patient-to-doctor chat
/// and provides AI-powered assistance.
class AstraChatPage extends StatefulWidget {
  /// Optional patient ID for context
  final String? patientId;

  /// Optional patient name for display
  final String? patientName;

  /// Optional appointment ID for context
  final String? appointmentId;

  const AstraChatPage({
    super.key,
    this.patientId,
    this.patientName,
    this.appointmentId,
  });

  @override
  State<AstraChatPage> createState() => _AstraChatPageState();
}

class _AstraChatPageState extends State<AstraChatPage> {
  late AstraController _controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _useStreaming = false;

  @override
  void initState() {
    super.initState();
    _controller = AstraController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initialize(
      patientId: widget.patientId,
      patientName: widget.patientName,
      appointmentId: widget.appointmentId,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_useStreaming) return _sendMessageStreaming();
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await _controller.sendMessage(text);

    // Scroll to bottom after sending
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  Future<void> _sendMessageStreaming() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await _controller.sendMessageStreaming(text);

    await Future.delayed(const Duration(milliseconds: 100));
    _scrollToBottom();
  }

  void _onActionTap(String actionType, Map<String, dynamic>? params) {
    final action = AstraNavigationAction(
      type: AstraActionType.values.firstWhere(
        (t) => t.name == actionType,
        orElse: () => AstraActionType.unknown,
      ),
      params: params,
    );
    _controller.executeAction(action);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AyurezeTheme.canvas,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Brain status indicator
            _buildStatusBar(),

            // Messages list
            Expanded(
              child: _buildMessagesList(),
            ),

            // Pending actions
            _buildPendingActions(),

            // Input area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AyurezeTheme.canvas,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          color: AyurezeTheme.iconPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Swastu is Astra's face, as in the patient app.
          const Swastu(mood: SwastuMood.listening, size: 40, named: false),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Astra AI',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AyurezeTheme.textPrimary,
                    ),
              ),
              if (widget.patientName != null)
                Text(
                  widget.patientName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AyurezeTheme.textSecondary,
                      ),
                ),
            ],
          ),
        ],
      ),
      centerTitle: true,
      // Every reply on this screen is Astra's, so it is labelled once here
      // rather than on each bubble.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AyurezeTheme.spaceSm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ContentOriginBadge(origin: ContentOrigin.astraSuggestion),
              const SizedBox(width: AyurezeTheme.spaceSm),
              Flexible(
                child: Text(
                  'Replies are not clinical decisions',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AyurezeTheme.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // More options
        PopupMenuButton<String>(
          icon: HugeIcon(
              icon: HugeIcons.strokeRoundedMoreVertical,
              color: AyurezeTheme.iconPrimary),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 20),
                  SizedBox(width: 8),
                  Text('Clear Chat'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'health',
              child: Row(
                children: [
                  HugeIcon(
                      icon: HugeIcons.strokeRoundedFavouriteCircle, size: 20),
                  SizedBox(width: 8),
                  Text('Check Health'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Consumer<AstraController>(
      builder: (context, controller, _) {
        return Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AyurezeTheme.spaceLg, vertical: AyurezeTheme.spaceSm),
          // Tint pairs (shade 10 behind shade 100) read in both themes;
          // orange-on-pale-orange did not.
          color: controller.isBrainHealthy
              ? AyurezeTheme.healingGreen10
              : AyurezeTheme.sunshineYellow10,
          child: Row(
            children: [
              HugeIcon(
                icon: controller.isBrainHealthy
                    ? HugeIcons.strokeRoundedCheckmarkCircle01
                    : HugeIcons.strokeRoundedAlert01,
                size: 16,
                color: controller.isBrainHealthy
                    ? AyurezeTheme.healingGreen100
                    : AyurezeTheme.sunshineYellow100,
              ),
              const SizedBox(width: 8),
              Text(
                controller.isBrainHealthy
                    ? 'Astra Brain is online'
                    : 'Astra Brain is offline',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: controller.isBrainHealthy
                          ? AyurezeTheme.healingGreen100
                          : AyurezeTheme.sunshineYellow100,
                    ),
              ),
              const Spacer(),
              if (controller.errorMessage != null)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(controller.errorMessage!),
                        backgroundColor: AyurezeTheme.remoteRedFill,
                      ),
                    );
                  },
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    size: 16,
                    color: Colors.orange,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesList() {
    return Consumer<AstraController>(
      builder: (context, controller, _) {
        if (!controller.isInitialized) {
          return const OslerLoadingView(message: 'Connecting to Astra…');
        }

        if (controller.messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
              horizontal: AyurezeTheme.spaceLg, vertical: AyurezeTheme.spaceSm),
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            final message = controller.messages[index];
            return AstraChatBubble(
              message: message,
              isUser: message.role == MessageRole.user,
              onActionTap: _onActionTap,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ScreenEntrance(
        child: Padding(
          padding: const EdgeInsets.all(AyurezeTheme.space3xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Swastu(mood: SwastuMood.greeting, size: 140),
              const SizedBox(height: AyurezeTheme.space2xl),
              Text(
                'Chat with Astra AI',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AyurezeTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ask questions about patients, prescriptions, or get AI-powered assistance for your consultations.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AyurezeTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              // Quick action chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildQuickAction('Summarize patient'),
                  _buildQuickAction('Check medications'),
                  _buildQuickAction('Generate prescription'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: AyurezeTheme.surface,
      side: BorderSide(color: AyurezeTheme.border),
      onPressed: () {
        _textController.text = text;
        _sendMessage();
      },
    );
  }

  Widget _buildPendingActions() {
    return Consumer<AstraController>(
      builder: (context, controller, _) {
        if (controller.pendingActions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(AyurezeTheme.spaceMd),
          decoration: BoxDecoration(
            color: AyurezeTheme.surface,
            border: Border(
              top: BorderSide(color: AyurezeTheme.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suggested Actions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AyurezeTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              AstraActionChipList(
                actions: controller.pendingActions,
                onActionTap: (action) {
                  controller.executeAction(action);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Consumer<AstraController>(
      builder: (context, controller, _) {
        return Container(
          padding: const EdgeInsets.all(AyurezeTheme.spaceMd),
          decoration: BoxDecoration(
            // Input tray must follow the theme: a hardcoded white here left
            // white-on-white text in dark mode.
            color: AyurezeTheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Stream toggle
                IconButton(
                  icon: HugeIcon(
                    icon: controller.isStreaming
                        ? HugeIcons.strokeRoundedStopCircle
                        : (_useStreaming
                            ? HugeIcons.strokeRoundedSparkles
                            : HugeIcons.strokeRoundedSparkle),
                    color: controller.isStreaming
                        ? Colors.red
                        : (_useStreaming
                            ? AyurezeTheme.accent
                            : AyurezeTheme.textSecondary),
                  ),
                  onPressed: controller.isLoading
                      ? null
                      : () {
                          if (controller.isStreaming) {
                            controller.cancelStream();
                            return;
                          }
                          setState(() => _useStreaming = !_useStreaming);
                        },
                  tooltip: controller.isStreaming
                      ? 'Stop streaming'
                      : (_useStreaming
                          ? 'Streaming on - tap to disable'
                          : 'Enable streaming'),
                ),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    enabled: !controller.isLoading && !controller.isStreaming,
                    decoration: InputDecoration(
                      hintText: 'Ask Astra AI...',
                      // The theme's warm filled field, as a pill.
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AyurezeTheme.radiusPill),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AyurezeTheme.radiusPill),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AyurezeTheme.radiusPill),
                        borderSide: BorderSide(
                          color: AyurezeTheme.accent,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AyurezeTheme.spaceLg,
                        vertical: AyurezeTheme.spaceMd,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                Container(
                  decoration: BoxDecoration(
                    // White glyph -> healingGreenFill (5.78:1); the mint
                    // was 1.9:1. Kept while busy so the white spinner shows.
                    color: AyurezeTheme.healingGreenFill,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: controller.isLoading || controller.isStreaming
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : HugeIcon(icon: AppIcons.send, color: Colors.white),
                    onPressed: controller.isLoading || controller.isStreaming
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            _sendMessage();
                          },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear':
        _showClearConfirmation();
        break;
      case 'health':
        _checkBrainHealth();
        break;
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear the conversation history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _controller.clearConversation();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _checkBrainHealth() async {
    await _controller.refreshBrainHealth();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.isBrainHealthy
                ? '✅ Astra Brain is healthy and ready!'
                : '⚠️ Astra Brain is currently unavailable',
          ),
          backgroundColor:
              _controller.isBrainHealthy ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}
