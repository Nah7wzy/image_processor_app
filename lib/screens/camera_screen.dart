import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_processing_app/screens/preview_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../main.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;

  File? _imageFile;
  // Initial values
  bool _isCameraInitialized = false;
  bool _isRearCameraSelected = true;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  // Current values
  double _currentZoomLevel = 1.0;
  FlashMode? _currentFlashMode;

  List<File> allFileList = [];

  final resolutionPresets = ResolutionPreset.values;

  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

  refreshAlreadyCapturedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> fileList = await directory.list().toList();
    allFileList.clear();
    List<Map<int, dynamic>> fileNames = [];

    fileList.forEach((file) {
      if (file.path.contains('.jpg') || file.path.contains('.mp4')) {
        allFileList.add(File(file.path));

        String name = file.path.split('/').last.split('.').first;
        fileNames.add({0: int.parse(name), 1: file.path.split('/').last});
      }
    });

    if (fileNames.isNotEmpty) {
      final recentFile =
          fileNames.reduce((curr, next) => curr[0] > next[0] ? curr : next);
      String recentFileName = recentFile[1];
      if (recentFileName.contains('.mp4')) {
        _imageFile = null;
      } else {
        _imageFile = File('${directory.path}/$recentFileName');
      }

      setState(() {});
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;

    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print('Error occured while taking picture: $e');
      return null;
    }
  }

  void resetCameraValues() async {
    _currentZoomLevel = 1.0;
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await previousCameraController?.dispose();

    resetCameraValues();

    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
      await Future.wait([
        cameraController
            .getMaxZoomLevel()
            .then((value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((value) => _minAvailableZoom = value),
      ]);

      _currentFlashMode = controller!.value.flashMode;
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  @override
  void initState() {
    // Hide the status bar in Android
    SystemChrome.setEnabledSystemUIOverlays([]);
    // Set and initialize the new camera
    onNewCameraSelected(cameras[0]);
    refreshAlreadyCapturedImages();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isCameraInitialized
            ? Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1 / controller!.value.aspectRatio,
                    child: Stack(
                      children: [
                        controller!.buildPreview(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            8.0,
                            16.0,
                            8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8.0,
                                      right: 8.0,
                                    ),
                                  ),
                                ),
                              ),
                              // Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 8.0, top: 16.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 30,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: _currentZoomLevel,
                                      min: _minAvailableZoom,
                                      max: _maxAvailableZoom,
                                      activeColor: Colors.white,
                                      inactiveColor: Colors.white30,
                                      onChanged: (value) async {
                                        setState(() {
                                          _currentZoomLevel = value;
                                        });
                                        await controller!.setZoomLevel(value);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          _currentZoomLevel.toStringAsFixed(1) +
                                              'x',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(),
                                  InkWell(
                                    onTap: () async {
                                      XFile? rawImage = await takePicture();
                                      File imageFile = File(rawImage!.path);

                                      int currentUnix =
                                          DateTime.now().millisecondsSinceEpoch;

                                      final directory =
                                          await getApplicationDocumentsDirectory();

                                      String fileFormat =
                                          imageFile.path.split('.').last;

                                      print("this is the file format: " +
                                          fileFormat);

                                      await imageFile.copy(
                                        '${directory.path}/$currentUnix.$fileFormat',
                                      );

                                      refreshAlreadyCapturedImages();
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: Colors.white,
                                          size: 80,
                                        ),
                                        Icon(
                                          Icons.circle,
                                          color: Colors.white,
                                          size: 65,
                                        ),
                                        Container(),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _imageFile != null
                                        ? () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    PreviewScreen(
                                                  imageFile: _imageFile!,
                                                  fileList: allFileList,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        image: _imageFile != null
                                            ? DecorationImage(
                                                image: FileImage(_imageFile!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () async {
                                    setState(() {
                                      _currentFlashMode = FlashMode.off;
                                    });
                                    await controller!.setFlashMode(
                                      FlashMode.off,
                                    );
                                  },
                                  child: Icon(
                                    Icons.flash_off,
                                    color: _currentFlashMode == FlashMode.off
                                        ? Colors.amber
                                        : Colors.white,
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    setState(() {
                                      _currentFlashMode = FlashMode.auto;
                                    });
                                    await controller!.setFlashMode(
                                      FlashMode.auto,
                                    );
                                  },
                                  child: Icon(
                                    Icons.flash_auto,
                                    color: _currentFlashMode == FlashMode.auto
                                        ? Colors.amber
                                        : Colors.white,
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    setState(() {
                                      _currentFlashMode = FlashMode.always;
                                    });
                                    await controller!.setFlashMode(
                                      FlashMode.always,
                                    );
                                  },
                                  child: Icon(
                                    Icons.flash_on,
                                    color: _currentFlashMode == FlashMode.always
                                        ? Colors.amber
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Text(
                  'LOADING',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }
}
