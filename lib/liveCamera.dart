import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:caption_generator/homePage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

class CameraLive extends StatefulWidget {
  @override
  State<CameraLive> createState() => _CameraLiveState();
}

class _CameraLiveState extends State<CameraLive> {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;

  bool takePhoto = true;
  String resultText = "Fetching Result...";

  Future<void> detectCamera() async {
    cameras = await availableCameras();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController?.dispose();
  }

  @override
  void initState() {
    super.initState();
    detectCamera().then((value) {
      initializeControllers();
    });
  }

  void initializeControllers() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController?.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
      if (takePhoto) {
        const interval = Duration(seconds: 6);
        Timer.periodic(interval, (Timer t) => startCapturingPicture());
      }
    });
  }

  void startCapturingPicture() async {
    if (!takePhoto) {
      return;
    }

    String timeNameforPicture = DateTime.now().microsecondsSinceEpoch.toString();
    final Directory directory = await getApplicationDocumentsDirectory();
    final String dirPath = "${directory.path}/Pictures/flutter_test";
    await Directory(dirPath).create(recursive: true);
    final String filePath = "$dirPath/$timeNameforPicture.png";

    try {
      XFile imageFile = await cameraController!.takePicture();
      File imgFile = File(imageFile.path);
      getResponse(imgFile);
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  Future<Object?> getResponse(File imageFile) async {
    try {
      final typeData = lookupMimeType(imageFile?.path ?? "", headerBytes: [0xFF, 0xD8])?.split("/");

      if (typeData == null) {
        print("Error: Unable to determine file type.");
        return null;
      }

      final imgUploadRequest =
      http.MultipartRequest("POST", Uri.parse("http://max-image-caption-generator-xamurani-dev.apps.sandbox-m2.ll9k.p1.openshiftapps.com/model/predict"));

      final file = await http.MultipartFile.fromPath("image", imageFile.path, contentType: MediaType(typeData[0], typeData[1]));

      imgUploadRequest.fields["ext"] = typeData[1];
      imgUploadRequest.files.add(file);

      final responseUpload = await imgUploadRequest.send();
      final response = await http.Response.fromStream(responseUpload);

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        parseResponse(responseData);
        return responseData;
      } else {
        print("Error: Unexpected status code ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  parseResponse(var response) {
    String result = "";
    var predictions = response["predictions"];

    for (var pred in predictions) {
      var caption = pred["caption"];
      var probability = pred["probability"];
      result = "${result + caption}\n\n";
    }

    setState(() {
      resultText = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined),
          color: Colors.brown.shade200,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
            print("Back button clicked");
            setState(() {
              resultText = "Fetching Result...";
              //loading = true;
            });
          },
        ),
        title: Text(
          'Caption Generator',
          style: GoogleFonts.akronim(
            textStyle: TextStyle(
              color: Colors.brown.shade200,
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.brown.shade900,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/jarvis.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 30.0),
              /*child: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_ios_new_outlined),
                onPressed: () {
                  setState(() {
                    takePhoto = false;
                  });
                  Navigator.pop(context);
                },
              ),*/
            ),
            (cameraController?.value.isInitialized ?? false)
                ? Center(child: createCameraView())
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget createCameraView() {
    var size = MediaQuery.of(context).size.width / 1.2;
    return Column(
      children: [
        Container(
          child: Column(
            children: [
              const SizedBox(height: 30),
              SizedBox(
                width: size,
                height: size,
                child: CameraPreview(cameraController!),
              ),
              const SizedBox(height: 30),
              Text(
                'Prediction is: ',
                textAlign: TextAlign.center,
                style: GoogleFonts.akronim(   //caveat
                  textStyle: TextStyle(
                    color: Colors.brown.shade200,
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                resultText,
                textAlign: TextAlign.center,
                style: GoogleFonts.akronim(   //caveat
                  textStyle: TextStyle(
                    color: Colors.brown.shade100,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
