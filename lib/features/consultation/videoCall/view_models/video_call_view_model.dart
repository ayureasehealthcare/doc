import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctro/features/consultation/videoCall/VideoCall/overlay_service.dart';
import 'package:doctro/core/constants/preferences.dart';
import 'package:doctro/core/constants/pref_constant.dart';
import 'package:doctro/network/api_header.dart';
import 'package:doctro/models/video_call_history_add_model.dart';
import 'package:doctro/network/base_model.dart';
import 'package:doctro/network/network_api.dart';
import 'package:doctro/network/server_error.dart';
import 'package:doctro/features/dashboard/login_home.dart';
import 'package:doctro/widgets/osler_toast.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:doctro/services/astra_api_service.dart';
import 'package:doctro/utils/logger.dart';
import 'package:doctro/features/consultation/videoCall/video_call.dart';

class VideoCallViewModel extends ChangeNotifier {
  int? remoteUid;
  bool localUserJoined = false;
  bool muted = false;
  bool mutedVideo = false;

  RtcEngine? engine;
  bool isEngineInitialized = false;

  String? appId;
  int uid = 0;
  String? token;
  String? channelName;
  int? doctorId = 0;

  int? callDuration = 0;
  String? callTime = "";
  String? callDate = "";

  ChannelMediaOptions options = const ChannelMediaOptions(
    clientRoleType: ClientRoleType.clientRoleBroadcaster,
    channelProfile: ChannelProfileType.channelProfileCommunication,
  );

  bool isDisposed = false;

  Future<void> init(
      BuildContext context, bool callEnd, int? id, String? flag) async {
    isDisposed = false;
    await _fetchAgoraConfigAndToken(context, callEnd, id, flag);
  }

  /// Notify listeners only while the view model is still alive.
  /// Agora callbacks fire on background threads, so guard against
  /// notifications after dispose().
  void _safeNotify() {
    if (isDisposed) return;
    notifyListeners();
  }

  /// Fetches the Agora App ID and an RTC token, then starts the engine.
  /// `doctorProfile()`/`settingRequest()` (the previous sources for these)
  /// and the old `/video/token` route are all dead legacy endpoints (404
  /// on the live backend) - the App ID and token now both come from live
  /// Astra endpoints, the same way regardless of who placed the call.
  Future<void> _fetchAgoraConfigAndToken(
      BuildContext context, bool callEnd, int? id, String? flag) async {
    try {
      doctorId = int.tryParse(
          SharedPreferenceHelper.getStringOrNull(Preferences.doctorId) ?? '');

      final configResponse = await AstraApiService().getVideoConfig();
      appId = configResponse['app_id'] as String?;
      if (!context.mounted) return;

      final tokenResponse =
          await AstraApiService().generateVideoToken(toId: '$id', uid: 0);
      if (tokenResponse['success'] == true) {
        final data = tokenResponse['data'] as Map<String, dynamic>?;
        token = data?['token'] as String?;
        channelName = data?['cn'] as String?;
        if (!context.mounted) return;
        await initAgora(context, callEnd, id, flag);
        notifyListeners();
      } else {
        if (!context.mounted) return;
        OslerToast.error(
            context, "Failed to call the patient! Unable to connect!");
        Navigator.pop(context);
      }
    } catch (error, stacktrace) {
      logger.e("Exception occur: $error stackTrace: $stacktrace");
      if (!context.mounted) return;
      OslerToast.error(
          context, "Failed to call the patient! Unable to connect!");
      Navigator.pop(context);
    }
  }

  Future<void> initAgora(
      BuildContext context, bool callEnd, int? id, String? flag) async {
    try {
      var statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      if (statuses[Permission.camera] != PermissionStatus.granted ||
          statuses[Permission.microphone] != PermissionStatus.granted) {
        throw Exception('Camera or Microphone permission not granted');
      }
      engine = createAgoraRtcEngine();
      await engine!.initialize(RtcEngineContext(
          appId: appId ??
              SharedPreferenceHelper.getString(Preferences.agoraAppId)));
      isEngineInitialized = true;
      await engine!.enableVideo();
      await engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 360),
          frameRate: 15,
          bitrate: 0,
          orientationMode: OrientationMode.orientationModeFixedPortrait,
        ),
      );

      engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            localUserJoined = true;
            _safeNotify();
          },
          onUserJoined:
              (RtcConnection connection, int remoteUidParam, int elapsed) {
            DateTime now = DateTime.now();
            callTime = DateFormat('h:mm a').format(now);
            callDate = DateFormat('yyyy-MM-dd').format(now);
            remoteUid = remoteUidParam;
            _safeNotify();
          },
          onUserOffline: (RtcConnection connection, int remoteUidParam,
              UserOfflineReasonType reason) {
            remoteUid = null;
            engine?.leaveChannel();
            if (!isDisposed && context.mounted) {
              OslerToast.info(context, "Call Ended");
            }
            _safeNotify();
          },
          onLeaveChannel: (RtcConnection connection, RtcStats details) {
            if (isDisposed) return;
            if (flag == "OutGoing") {
              callDuration = details.duration;
              OverlayService().removeVideosOverlay(
                  context,
                  VideoCall(
                    id: id,
                    callEnd: false,
                  ));
            } else {
              callDuration = details.duration;
              if (callTime != "" && callDate != "" && callEnd == false) {
                callApiAddVideoCallHistory(context, id);
                if (context.mounted) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LoginHomeScreen(chat: "")));
                }
              } else {
                if (context.mounted) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LoginHomeScreen(chat: "")));
                }
              }
            }
            _safeNotify();
          },
        ),
      );
      if (token != null &&
          channelName != null &&
          token!.isNotEmpty &&
          channelName!.isNotEmpty) {
        await engine!.startPreview();
        engine!.joinChannel(
          token: '$token',
          channelId: '$channelName',
          uid: uid,
          options: options,
        );
      }
    } catch (e) {
      logger.e(e);
    }
  }

  Future<BaseModel<VideoCallHistoryAddModel>> callApiAddVideoCallHistory(
      BuildContext context, int? id) async {
    VideoCallHistoryAddModel response;
    Map<String, dynamic> body = {
      "user_id": id,
      "date": callDate,
      "start_time": callTime,
      "duration": callDuration,
      "doctor_id": doctorId,
    };
    try {
      response = await RestClient(await RetroApi().dioData(context))
          .videoCallHistoryAddRequest(body);
    } catch (error) {
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  void toggleVideo() {
    mutedVideo = !mutedVideo;
    if (isEngineInitialized) {
      engine?.muteLocalVideoStream(mutedVideo);
    }
    notifyListeners();
  }

  void toggleMute() {
    muted = !muted;
    if (isEngineInitialized) {
      engine?.muteLocalAudioStream(muted);
    }
    notifyListeners();
  }

  void switchCamera() {
    if (isEngineInitialized) {
      engine?.switchCamera();
    }
    notifyListeners();
  }

  void endCall(BuildContext context) {
    try {
      localUserJoined = false;
      remoteUid = null;
      if (isEngineInitialized) {
        engine?.leaveChannel();
      }
      _safeNotify();
    } catch (e) {
      logger.e(e);
    }
    if (!isDisposed && context.mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    if (!isDisposed) {
      try {
        if (isEngineInitialized) {
          engine?.leaveChannel();
          engine?.release();
        }
      } catch (e) {
        logger.e(e);
      }
      isDisposed = true;
    }
    super.dispose();
  }
}
