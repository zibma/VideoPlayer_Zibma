import 'package:flutter/material.dart';
import 'package:newpipeextractor_dart/extractors/videos.dart';
import 'package:newpipeextractor_dart/newpipeextractor_dart.dart';
import 'package:newpipeextractor_dart_example/video_play.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  dynamic _infoItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // String url = "https://www.youtube.com/watch?v=0Y_xhvk7_3I";
          String url = "https://www.youtube.com/watch?v=2IlzAP9ibT0";
          VideoExtractor.getStream(url).then((YoutubeVideo value) {
            print(" info.segments.length>>>${value.url}");
            print(" info.segments.length>>>${value.id}");
            print(" info.segments.length>>>${value.name}");
            print(" info.segments.length>>>${value.uploaderName}");
            print(" info.segments.length>>>${value.uploaderUrl}");
            print(" info.segments.length>>>${value.uploadDate}");
            print(" info.segments.length>>>${value.length}");
            print(" info.segments.length>>>${value.viewCount}");

            _infoItem = new StreamInfoItem(
                value.url,
                value.id,
                value.name,
                value.uploaderName,
                value.uploaderUrl,
                value.uploadDate,
                value.uploadDate,
                value.length,
                value.viewCount);

            // Provider.of<VideoPageProvider>(context,listen: false).infoItems(_infoItem);

            Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) => new VideoPlay(value)));
          });
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
