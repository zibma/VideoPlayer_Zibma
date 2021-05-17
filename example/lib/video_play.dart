import 'package:flutter/material.dart';
import 'package:newpipeextractor_dart/newpipeextractor_dart.dart';
import 'package:newpipeextractor_dart_example/videoPlayer.dart';

class VideoPlay extends StatefulWidget {
  YoutubeVideo _infoItem;

  VideoPlay(this._infoItem);

  @override
  _VideoPlayState createState() => _VideoPlayState();
}

class _VideoPlayState extends State<VideoPlay> {
  double aspectRatio = 16 / 9;
  YoutubeVideo? currentVideo;

  @override
  void initState() {
    super.initState();
    currentVideo = widget._infoItem;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: _videoPlayerWidget(),
        ),
      ),
    );
  }

  Widget _videoPlayerWidget() {
    String videoQuality = '720';
    return StreamManifestPlayer(
      segments: currentVideo!.segments!,
      onAspectRatioInit: (value) => setState(() {
        debugPrint('initialize -> ${value}');
        aspectRatio = value;
      }),
      quality: videoQuality,
      onQualityChanged: (String quality) {
        debugPrint('initialize QualityChanged -> ${quality}');
        videoQuality = quality;
      },
      onBackArrow: (){
        Navigator.pop(context);
      },
      videoTitle: currentVideo?.name ?? "",
      streams: currentVideo!.videoOnlyStreams!.isNotEmpty
          ? currentVideo!.videoOnlyStreams!
          : currentVideo!.videoStreams!,
      audioStream: currentVideo!.videoOnlyStreams!.isNotEmpty
          ? currentVideo!.getAudioStreamWithBestMatchForVideoStream(
              currentVideo!.videoOnlyWithHighestQuality)
          : null,
      isFullscreen: MediaQuery.of(context).orientation == Orientation.landscape
          ? true
          : false,
    );
  }
}
