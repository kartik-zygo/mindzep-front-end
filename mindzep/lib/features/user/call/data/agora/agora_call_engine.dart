import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraCallEngine {
  RtcEngine? _engine;
  bool _isInChannel = false;

  bool get isInitialized => _engine != null;
  RtcEngine? get rtcEngine => _engine;

  Future<void> initialize({
    required String appId,
    required RtcEngineEventHandler eventHandler,
  }) async {
    if (_engine != null) {
      // Engine already exists — leave any current channel first so a
      // subsequent joinChannel() cannot trigger ERR_JOIN_CHANNEL_REJECTED (-17).
      if (_isInChannel) {
        await _engine!.leaveChannel();
        _isInChannel = false;
      }
      _engine!.registerEventHandler(eventHandler);
      return;
    }

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    engine.registerEventHandler(eventHandler);
    await engine.enableAudio();
    await engine.enableVideo();

    _engine = engine;
  }

  Future<void> joinChannel({
    required String token,
    required String channelName,
    int uid = 0,
    bool enableVideo = true,
  }) async {
    final engine = _engine;
    if (engine == null) return;

    // Guard: if the native engine is already in a channel, leave first.
    // This prevents ERR_JOIN_CHANNEL_REJECTED (-17) on re-entry.
    if (_isInChannel) {
      await engine.leaveChannel();
      _isInChannel = false;
    }

    await engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: enableVideo,
        autoSubscribeAudio: true,
        // Always subscribe to remote video so the caller's video is visible
        // even when this user joined with their own camera off.
        autoSubscribeVideo: true,
      ),
    );

    _isInChannel = true;
  }

  Future<void> muteLocalAudio(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> muteLocalVideo(bool muted) async {
    await _engine?.muteLocalVideoStream(muted);
  }

  Future<void> setSpeakerphone(bool enabled) async {
    await _engine?.setEnableSpeakerphone(enabled);
  }

  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
    _isInChannel = false;
  }

  Future<void> dispose() async {
    final engine = _engine;
    if (engine == null) return;

    await engine.leaveChannel();
    await engine.release();
    _engine = null;
    _isInChannel = false;
  }
}
