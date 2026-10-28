import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctro/features/consultation/videoCall/VideoCall/overlay_handler.dart';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:doctro/core/constants/app_string.dart';
import 'package:doctro/theme/ayureze_theme.dart';
import 'package:doctro/core/localization/localization_constant.dart';
import 'package:doctro/features/consultation/videoCall/view_models/video_call_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:hugeicons/hugeicons.dart';
import 'package:pip_view/pip_view.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:provider/provider.dart';

class VideoCall extends StatefulWidget {
  final bool callEnd;
  final int? id;
  final String? flag;

  const VideoCall({
    super.key,
    required this.callEnd,
    this.id,
    this.flag,
  });
  @override
  State<VideoCall> createState() => _VideoCallState();
}

class _VideoCallState extends State<VideoCall> {
  Offset offset = const Offset(20.0, 50.0);
  int? boxNumberIsDragged;
  late VideoCallViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VideoCallViewModel();
    // Initialize view model logic without blocking build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.init(context, widget.callEnd, widget.id, widget.flag);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Widget _toolbar(VideoCallViewModel viewModel) {
    return Consumer<OverlayHandlerProvider>(
      builder: (context, overlayProvider, _) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: AyurezeTheme.space3xl),
            padding: const EdgeInsets.symmetric(
                horizontal: AyurezeTheme.spaceXl,
                vertical: AyurezeTheme.spaceMd),
            decoration: BoxDecoration(
              color: AyurezeTheme.surfaceDark.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AyurezeTheme.radius2xl),
              border: Border.all(
                  color: AyurezeTheme.border.withValues(alpha: 0.35), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Mute Audio
                _buildControlButton(
                  onPressed: () => viewModel.toggleMute(),
                  icon: viewModel.muted ? AppIcons.micOff : AppIcons.mic,
                  color: viewModel.muted
                      ? AyurezeTheme.remoteRed100
                      : AyurezeTheme.textPrimary,
                  bgColor: viewModel.muted
                      ? AyurezeTheme.surface
                      : AyurezeTheme.surface.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 15),

                // Mute Video
                _buildControlButton(
                  onPressed: () => viewModel.toggleVideo(),
                  icon: viewModel.mutedVideo
                      ? AppIcons.videoCallOff
                      : AppIcons.videoCall,
                  color: viewModel.mutedVideo
                      ? AyurezeTheme.remoteRed100
                      : AyurezeTheme.textPrimary,
                  bgColor: viewModel.mutedVideo
                      ? AyurezeTheme.surface
                      : AyurezeTheme.surface.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 15),

                // Switch Camera
                _buildControlButton(
                  onPressed: () => viewModel.switchCamera(),
                  icon: AppIcons.cameraFlip,
                  color: AyurezeTheme.textPrimary,
                  bgColor: AyurezeTheme.surface.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 25),

                // End Call
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    viewModel.endCall(context);
                  },
                  child: Container(
                    height: 55,
                    width: 55,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: HugeIcon(
                        icon: AppIcons.callEnd, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required List<List<dynamic>> icon,
    required Color color,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: HugeIcon(icon: icon, color: color, size: 22),
      ),
    );
  }

  Widget _localPreview(VideoCallViewModel viewModel) {
    if (!viewModel.isEngineInitialized || viewModel.engine == null) {
      return Container();
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: viewModel.engine!,
        canvas: const VideoCanvas(
          uid: 0,
          renderMode: RenderModeType.renderModeHidden,
        ),
      ),
    );
  }

  Widget _remoteVideo(VideoCallViewModel viewModel) {
    if (viewModel.remoteUid != null &&
        viewModel.channelName != null &&
        viewModel.isEngineInitialized &&
        viewModel.engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: viewModel.engine!,
          canvas: VideoCanvas(
            uid: viewModel.remoteUid!,
            renderMode: RenderModeType.renderModeHidden,
          ),
          connection: RtcConnection(channelId: viewModel.channelName!),
        ),
      );
    } else {
      return Container(
        decoration: const BoxDecoration(
          gradient: AyurezeTheme.callWaitingGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AyurezeTheme.surface.withValues(alpha: 0.15),
                child: HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    size: 50,
                    color: AyurezeTheme.callForeground.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 25),
              ScalingText(
                widget.callEnd == true
                    ? getTranslated(context, AppString.disconnect_call)
                        .toString()
                    : widget.flag == "OutGoing"
                        ? getTranslated(context, AppString.ringing).toString()
                        : getTranslated(context, AppString.connect_call)
                            .toString(),
                style: AyurezeTheme.font(AyurezeTheme.textXl, FontWeight.w500,
                    AyurezeTheme.callForeground,
                    letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return ChangeNotifierProvider<VideoCallViewModel>.value(
      value: _viewModel,
      child: PIPView(
        builder: (context, isFloating) {
          return Scaffold(
            backgroundColor: AyurezeTheme.callBackground,
            body: Consumer2<VideoCallViewModel, OverlayHandlerProvider>(
              builder: (context, viewModel, overlayProvider, _) {
                return Stack(
                  children: [
                    // Remote Video (Background)
                    Positioned.fill(
                      child: _remoteVideo(viewModel),
                    ),

                    // Top Status Bar (Duration / Name)
                    if (viewModel.remoteUid != null)
                      Positioned(
                        top: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AyurezeTheme.spaceLg,
                                vertical: AyurezeTheme.spaceSm),
                            decoration: BoxDecoration(
                              color: AyurezeTheme.surfaceDark
                                  .withValues(alpha: 0.7),
                              borderRadius:
                                  BorderRadius.circular(AyurezeTheme.radiusLg),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AyurezeTheme.remoteRed100,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AyurezeTheme.spaceSm),
                                Text(
                                  "Live Consultation",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AyurezeTheme.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Local Preview (Floating)
                    if (!widget.callEnd)
                      Positioned(
                        right: 20,
                        top: 100,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              // Boundary checks
                              double newX = offset.dx + details.delta.dx;
                              double newY = offset.dy + details.delta.dy;
                              if (newX > 0 &&
                                  newX < width - 120 &&
                                  newY > 0 &&
                                  newY < height - 160) {
                                offset = Offset(newX, newY);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 120,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AyurezeTheme.radiusLg),
                              border: Border.all(
                                  color: AyurezeTheme.border
                                      .withValues(alpha: 0.5),
                                  width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                    color: AyurezeTheme.callTileShadow,
                                    blurRadius: 10,
                                    spreadRadius: 2)
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AyurezeTheme.radiusLg),
                              child: viewModel.localUserJoined &&
                                      !viewModel.mutedVideo
                                  ? _localPreview(viewModel)
                                  : Container(
                                      color: AyurezeTheme.surfaceDark,
                                      child: HugeIcon(
                                          icon: HugeIcons.strokeRoundedVideoOff,
                                          color: AyurezeTheme.textMuted,
                                          size: 30),
                                    ),
                            ),
                          ),
                        ),
                      ),

                    // Bottom Toolbar
                    _toolbar(viewModel),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
