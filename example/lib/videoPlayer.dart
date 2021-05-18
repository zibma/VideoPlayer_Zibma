import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:newpipeextractor_dart/newpipeextractor_dart.dart';
import 'package:newpipeextractor_dart_example/playPauseButton.dart';
import 'package:newpipeextractor_dart_example/playerAppBar.dart';
import 'package:newpipeextractor_dart_example/playerProgressBar.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';
// import 'package:volume/volume.dart';

class StreamManifestPlayer extends StatefulWidget {
  final String videoTitle;
  final List<dynamic> streams;
  final AudioOnlyStream? audioStream;
  final Function? onAutoPlay;
  final bool? isFullscreen;
  final Function? onEnterPipMode;
  final bool forceHideControls;
  final String quality;
  final Function onBackArrow;
  final Function(String)? onQualityChanged;
  final List<StreamSegment> segments;
  final Function(double)? onAspectRatioInit;

  StreamManifestPlayer(
      {Key? key,
      required this.videoTitle,
      required this.streams,
      this.audioStream,
      this.onAutoPlay,
      this.isFullscreen,
      this.onEnterPipMode,
      this.forceHideControls = false,
      required this.quality,
      this.onQualityChanged,
      required this.onBackArrow,
      this.segments = const [],
      this.onAspectRatioInit})
      : super(key: key);

  @override
  StreamManifestPlayerState createState() => StreamManifestPlayerState();
}

class StreamManifestPlayerState extends State<StreamManifestPlayer> {
  // Player Variables (width is set automatically)
  bool? isPlaying;
  bool hideControls = false;
  bool videoEnded = false;
  bool buffering = true;
  bool isSeeking = false;
  String? currentQuality;

  // Reverse and Forward Animation
  bool showReverse = false;
  bool showForward = false;

  // Current Aspect Ratio
  double? aspectRatio;

  // UI
  bool _showControls = true;

  bool get showControls => _showControls;

  set showControls(bool value) {
    if (value == false) {
      _showControls = false;
    } else {
      if (!widget.forceHideControls) {
        _showControls = true;
      }
    }
  }

  bool _showBackdrop = true;

  bool get showBackdrop => _showBackdrop;

  set showBackdrop(bool value) {
    if (value == false) {
      _showBackdrop = false;
    } else {
      if (!widget.forceHideControls) {
        _showBackdrop = true;
      }
    }
  }

  // Show quality menu
  bool showStreamQualityMenu = false;

  String? currentVolumePercentage;
  String? currentBrightnessPercentage;

  // Gestures
  bool showVolumeUI = false;
  bool showBrightnessUI = false;
  int tapId = 0;

  VideoPlayerController? _controller;

  VideoPlayerController get controller => _controller!;

  @override
  void initState() {
    super.initState();
    isPlaying = false;
    currentQuality = widget.quality;
    // Volume.controlVolume(AudioManager.STREAM_MUSIC).then((value) async {
    //   currentVolumePercentage =
    //       "${(((await Volume.getVol) / (await Volume.getMaxVol)) * 100).round()}";
    // });

    PerfectVolumeControl.getVolume().then((value) => {
          // debugPrint('PerfectVolumeControl getVolume-> ${value}');
          currentVolumePercentage = '${(value * 100).round()}'
          // "${(((await Volume.getVol) / (await Volume.getMaxVol)) * 100).round()}";
        });
    PerfectVolumeControl.hideUI = true;
    Screen.brightness.then((value) {
      currentBrightnessPercentage = "${((value / 1) * 100).round()}";
    });
    Screen.keepOn(true);
    Future.delayed(Duration(seconds: 2), () {
      setState(() => hideControls = true);
    });
    List<String> playerStreamsUrls = [];
    widget.streams.forEach((element) {
      debugPrint('initialize element-> ${element.url}');
      playerStreamsUrls.add(element.url);
    });
    int indexToPlay = widget.streams
        .indexWhere((element) => element.resolution.contains(widget.quality));
    if (indexToPlay == -1) {
      indexToPlay = 0;
      currentQuality = widget.streams[indexToPlay].resolution.split("p").first;
    }
    _controller = VideoPlayerController.network(widget.streams[indexToPlay].url,
        audioDataSource: widget.streams[indexToPlay] is VideoOnlyStream
            ? widget.audioStream!.url
            : null,
        formatHint: VideoFormat.other)
      ..initialize().then((value) {
        _controller!.play().then((_) {
          setState(() {
            isPlaying = true;
            buffering = false;
          });
          setState(() {
            showControls = false;
            showBackdrop = false;
          });
        });

        if (aspectRatio != controller.value.aspectRatio) {
          widget.onAspectRatioInit!(controller.value.aspectRatio);
          setState(() => aspectRatio = controller.value.aspectRatio);
        }
      });
    _controller!.addListener(() {
      if (_controller!.value.isBuffering && buffering == false) {
        setState(() => buffering = true);
      }
      if (!_controller!.value.isBuffering && buffering == true) {
        setState(() => buffering = false);
      }
    });
    Future.delayed(Duration(seconds: 10), () {
      _controller!.addListener(() {
        int currentPosition = (_controller?.value.position.inSeconds ?? null)!;
        int totalDuration = (_controller?.value.duration.inSeconds ?? null)!;
        bool autoPlayEnabled = true;
        if (currentPosition == totalDuration &&
            currentPosition != null &&
            totalDuration != null &&
            autoPlayEnabled) {
          if (!videoEnded) {
            videoEnded = true;
            Future.delayed((Duration(seconds: 2)), () => widget.onAutoPlay!());
          }
        }
      });
    });
  }

  @override
  void dispose() {
    Screen.keepOn(false);
    if (_controller != null) _controller!.dispose();
    super.dispose();
  }

  Future<void> handleVolumeGesture(double primaryDelta) async {
    tapId = Random().nextInt(10);
    int currentId = tapId;
    double maxVolume = 1.0;
    double currentVolume = await PerfectVolumeControl.getVolume();
    double newVolume = ((currentVolume + primaryDelta) * 0.1 * (-1));

    currentVolumePercentage = newVolume > maxVolume
        ? "100"
        : newVolume < 0
            ? "0"
            : "${((newVolume / maxVolume) * 100).round()}";
    setState(() {});
    debugPrint('PerfectVolumeControl newVolume-> ${newVolume}');
    await PerfectVolumeControl.setVolume(
        newVolume > maxVolume ? maxVolume : newVolume);

    if (!showVolumeUI) {
      setState(() {
        showControls = false;
        showVolumeUI = true;
        showBackdrop = true;
        showBrightnessUI = false;
      });
    }
    Future.delayed(Duration(seconds: 3), () {
      if (currentId == tapId && mounted) {
        setState(() {
          showControls = false;
          showVolumeUI = false;
          showBackdrop = false;
          showBrightnessUI = false;
        });
      }
    });
  }

  void handleBrightnessGesture(double primaryDelta) async {
    tapId = Random().nextInt(10);
    int currentId = tapId;
    double currentBrightness = await Screen.brightness;
    double newBrightness = currentBrightness + ((primaryDelta * -1) * 0.01);
    currentBrightnessPercentage = newBrightness > 1
        ? "100"
        : newBrightness < 0
            ? "0"
            : "${((newBrightness / 1) * 100).round()}";
    setState(() {});
    Screen.setBrightness(newBrightness > 1
        ? 1
        : newBrightness < 0
            ? 0
            : newBrightness);
    if (!showVolumeUI) {
      setState(() {
        showControls = false;
        showVolumeUI = false;
        showBackdrop = true;
        showBrightnessUI = true;
      });
    }
    Future.delayed(Duration(seconds: 3), () {
      if (currentId == tapId && mounted) {
        setState(() {
          showControls = false;
          showVolumeUI = false;
          showBackdrop = false;
          showBrightnessUI = false;
        });
      }
    });
  }

  void showControlsHandler() {
    if (!showControls) {
      tapId = Random().nextInt(10);
      int currentId = tapId;
      setState(() {
        showControls = true;
        showBackdrop = true;
      });
      if (controller.value.isPlaying) {
        Future.delayed(Duration(seconds: 5), () {
          if (currentId == tapId &&
              mounted &&
              showControls == true &&
              !isSeeking) {
            setState(() {
              showControls = false;
              showBackdrop = false;
            });
          }
        });
      }
    } else {
      setState(() {
        showControls = false;
        showBackdrop = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Video Beign Played
          Container(
            child: _controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller?.value?.aspectRatio ?? 16 / 9,
                    child: VideoPlayer(_controller!))
                : Container(color: Colors.black),
          ),
          // Player Controls and Gestures
          AnimatedSwitcher(
              duration: Duration(milliseconds: 400),
              child: showStreamQualityMenu
                  ? _playbackQualityOverlay()
                  : _playbackControlsOverlay())
        ],
      ),
    );
  }

  // Full UI for playback controls and gestures
  Widget _playbackControlsOverlay() {
    return Stack(
      children: [
        // Player Gestures Detector
        Flex(
          direction: Axis.horizontal,
          children: [
            Flexible(
              flex: 1,
              child: GestureDetector(
                onTap: () => showControlsHandler(),
                onDoubleTap: () {
                  if (_controller!.value.isInitialized) {
                    Duration seekNewPosition;
                    if (_controller!.value.position < Duration(seconds: 10)) {
                      seekNewPosition = Duration.zero;
                    } else {
                      seekNewPosition =
                          _controller!.value.position - Duration(seconds: 10);
                    }
                    _controller!.seekTo(seekNewPosition);
                    setState(() => showReverse = true);
                    Future.delayed(Duration(milliseconds: 250),
                        () => setState(() => showReverse = false));
                  }
                },
                onVerticalDragUpdate:
                    MediaQuery.of(context).orientation == Orientation.landscape
                        ? (update) {
                            // handleBrightnessGesture(update.primaryDelta!);
                          }
                        : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  width: double.infinity,
                  height: double.infinity,
                  color: !showBackdrop
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.3),
                  child: Center(
                    child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 250),
                        reverseDuration: Duration(milliseconds: 500),
                        child: showBrightnessUI
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(EvaIcons.sun,
                                      color: Colors.white, size: 32),
                                  SizedBox(width: 12),
                                  Text(
                                    "$currentBrightnessPercentage%",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        letterSpacing: 0.2,
                                        fontFamily: 'Product Sans',
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              )
                            : Container()),
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 1,
              child: GestureDetector(
                onTap: () => showControlsHandler(),
                onDoubleTap: () {
                  if (_controller!.value.isInitialized) {
                    _controller!.seekTo(
                        _controller!.value.position + Duration(seconds: 10));
                    setState(() => showForward = true);
                    Future.delayed(Duration(milliseconds: 250),
                        () => setState(() => showForward = false));
                  }
                },
                onVerticalDragUpdate:
                    MediaQuery.of(context).orientation == Orientation.landscape
                        ? (update) {
                            // handleVolumeGesture(update.primaryDelta!);
                          }
                        : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 250),
                  width: double.infinity,
                  height: double.infinity,
                  color: !showBackdrop
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.3),
                  child: Center(
                    child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 250),
                        reverseDuration: Duration(milliseconds: 500),
                        child: showVolumeUI
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(EvaIcons.volumeUp,
                                      color: Colors.white, size: 32),
                                  SizedBox(width: 12),
                                  Text(
                                    "$currentVolumePercentage%",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        letterSpacing: 0.2,
                                        fontFamily: 'Product Sans',
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              )
                            : Container()),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Player Fast Forward/Backward Animation
        IgnorePointer(
          ignoring: true,
          child: Flex(
            direction: Axis.horizontal,
            children: [
              Flexible(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.all(50),
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 250),
                      child: showReverse
                          ? Icon(Icons.replay_10_outlined,
                              color: Colors.white, size: 40)
                          : Container()),
                ),
              ),
              Flexible(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.all(50),
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 250),
                      child: showForward
                          ? Icon(Icons.forward_10_outlined,
                              color: Colors.white, size: 40)
                          : Container()),
                ),
              )
            ],
          ),
        ),
        // Player controls UI
        AnimatedSwitcher(
            duration: Duration(milliseconds: 600),
            child: showControls
                ? Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Player AppBar
                        Align(
                          alignment: Alignment.topLeft,
                          child: PlayerAppBar(
                            currentQuality: currentQuality!,
                            videoTitle: widget.videoTitle,
                            streams: widget.streams,
                            onBackArrow: () {
                              widget.onBackArrow();
                            },
                            onChangeQuality: () {
                              setState(() => showStreamQualityMenu = true);
                            },
                            // onEnterPipMode: widget.onEnterPipMode,
                          ),
                        ),
                        // Play/Pause Buttons
                        PlayPauseButton(
                          isPlaying: isPlaying!,
                          onPlayPause: () async {
                            if (controller.value.isPlaying) {
                              await controller.pause();
                              isPlaying = false;
                            } else {
                              await controller.play();
                              isPlaying = true;
                            }
                            setState(() {});
                          },
                        ),
                        InkWell(
                          onTap: () async {
                            if (controller.value.isPlaying) {
                              await controller.pause();
                              isPlaying = false;
                            } else {
                              await controller.play();
                              isPlaying = true;
                            }
                            setState(() {});
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Ink(
                            padding: const EdgeInsets.all(16.0),
                            child: isPlaying!
                                ? Icon(
                                    Icons.pause,
                                    size: 32,
                                    color: Colors.white,
                                  )
                                : Icon(
                                    Icons.play_arrow,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: StreamBuilder<int>(
                              stream: StreamCreater(const Duration(seconds: 1),
                                  controller.value.duration.inSeconds),
                              builder: (context, snapshot) {
                                return PlayerProgressBar(
                                  segments: widget.segments,
                                  position: controller.value.position,
                                  duration: controller == null
                                      ? Duration(seconds: 2)
                                      : controller.value.duration,
                                  onSeek: (double newPosition) {
                                    controller.seekTo(
                                        Duration(seconds: newPosition.round()));
                                    setState(() => isSeeking = false);
                                  },
                                  onSeekStart: () {
                                    setState(() => isSeeking = true);
                                  },
                                );
                              }),
                        )
                      ],
                    ),
                  )
                : Container()),
        // Player buffering indicator
        Center(
            child: buffering
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    strokeWidth: 2)
                : Container())
      ],
    );
  }

  static Stream<int> StreamCreater(Duration interval, [int? maxCount]) {
    StreamController<int>? controller;
    Timer? timer;
    int count = 0;

    void increment_count(_) {
      count++;

      if (count == maxCount) {
        timer!.cancel();
        controller!.sink.close();
      } else if (count == 3) {
        controller!.sink.addError('Error !');
      } else if (count < maxCount!) {
        controller!.sink.add(count);
      }
    }

    void startTimer() {
      timer = Timer.periodic(interval, increment_count);
    }

    void stopTimer() {
      if (timer != null) {
        timer!.cancel();
        timer = null;
      }
    }

    controller = StreamController<int>(
        onListen: startTimer,
        onPause: stopTimer,
        onResume: startTimer,
        onCancel: stopTimer);

    return controller.stream;
  }

  Widget _playbackQualityOverlay() {
    List<String> qualities = [];
    widget.streams.forEach((stream) {
      if (stream.formatSuffix.contains('webm'))
        qualities.add(stream.formatSuffix + " • " + stream.resolution);
    });
    return Stack(
      children: [
        Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.black.withOpacity(0.3),
        ),
        Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.3)])),
        ),
        Center(
          child: Container(
            width: 180,
            child: ListView.builder(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: 40),
                itemCount: qualities.length,
                itemBuilder: (context, index) {
                  String quality = qualities[index];
                  return GestureDetector(
                    onTap: () {
                      int index = widget.streams.indexWhere((element) =>
                          element.formatSuffix + " • " + element.resolution ==
                          quality);
                      _controller!.changeVideoUrl(widget.streams[index].url);
                      widget.onQualityChanged!(quality.split("p").first);
                      setState(() => currentQuality = quality);
                      setState(() => showStreamQualityMenu = false);
                      showControlsHandler();
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: EdgeInsets.all(12),
                      child: Container(
                        height: 40,
                         decoration: new BoxDecoration(
                            color: Colors.white30,
                            borderRadius: new BorderRadius.only(
                              bottomLeft: const Radius.circular(30.0),
                              bottomRight: const Radius.circular(30.0),
                              topLeft: const Radius.circular(30.0),
                              topRight: const Radius.circular(30.0),
                            )),
                        child: Center(
                          child: Text(
                            "${quality.split("•").last.trim().split("p").first + "p"}"
                            "${quality.split("p").last.contains("60") ? " • 60 FPS" : ""}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Product Sans',
                                fontSize: 22,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ),
        ),
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
              onPressed: () => setState(() => showStreamQualityMenu = false),
              icon: Icon(Icons.arrow_back_rounded, color: Colors.white)),
        ),
      ],
    );
  }
}
