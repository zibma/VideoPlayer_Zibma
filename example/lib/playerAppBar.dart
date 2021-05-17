import 'package:flutter/material.dart';

class PlayerAppBar extends StatelessWidget {
  final List<dynamic> streams;
  final String videoTitle;
  final Function onChangeQuality;
  final Function onBackArrow;
  final String currentQuality;

  PlayerAppBar({
    required this.streams,
    required this.videoTitle,
    required this.onChangeQuality,
    required this.onBackArrow,
    required this.currentQuality,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              onBackArrow();
            },
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "$videoTitle",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Product Sans',
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChangeQuality(),
            child: Container(
                padding: EdgeInsets.all(4),
                color: Colors.transparent,
                child: Text(
                  ("${currentQuality.split('p').first + "p"}"
                          .split('•')
                          .last
                          .trim() +
                      "${currentQuality.split('p').last.contains("60") ? " • 60 FPS" : ""}"),
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Product Sans'),
                )),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}
