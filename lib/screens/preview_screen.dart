import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_processing_app/screens/camera_screen.dart';
import 'package:image_processing_app/screens/captures_screen.dart';

class PreviewScreen extends StatelessWidget {
  final File imageFile;
  final List<File> fileList;

  const PreviewScreen({
    required this.imageFile,
    required this.fileList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(),
                    ),
                  );
                },
                child: Text('Go back'),
                style: TextButton.styleFrom(
                  primary: Colors.black,
                  backgroundColor: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text("Upload"),
                style: TextButton.styleFrom(
                  primary: Colors.black,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
          Expanded(
            child: Image.file(imageFile),
          ),
          Container(
            child: Text("Upload this picture"),
          ),
        ],
      ),
    );
  }
}
