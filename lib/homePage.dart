/*import 'dart:convert';
import 'dart:io';
import 'package:caption_generator/liveCamera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});


  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{

  bool loading = true;
  File image = File('path/to/default/image.jpg');
  //File image;
  String resultText = "Fetching Result...";
  final pickerImage = ImagePicker();

  Future<Object?> getResponse(File imageFile) async {
    try {
      final typeData = lookupMimeType(imageFile?.path ?? "", headerBytes: [0xFF, 0xD8])?.split("/");
      //final typeData = lookupMimeType(imageFile.path, headerBytes: [0xFF, 0xD8])?.split("/");

      if (typeData == null) {
        print("Error: Unable to determine file type.");
        return null;
      }

      final imgUploadRequest = http.MultipartRequest("POST", Uri.parse("http://max-image-caption-generator-xamurani-dev.apps.sandbox-m2.ll9k.p1.openshiftapps.com/model/predict"));

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

  // fun to pick a img from gallery
  pickImageFromGallery() async
  {
    var imageFile = await pickerImage.pickImage(source: ImageSource.gallery);
    if(imageFile != null){
      setState(() {
        image = File(imageFile.path);
        loading = false;
      });
      var res = await getResponse(image);
      //var res = getResponse(image);
    }
  }

  captureImageWithCamera() async
  {
    var imageFile = await pickerImage.pickImage(source: ImageSource.camera);
    if(imageFile != null){
      setState(() {
        image = File(imageFile.path);
        loading = false;
      });

      var res = await getResponse(image);
      //var res = getResponse(image!);
    }
  }


  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/jarvis.jpeg"),
            fit: BoxFit.cover,
          )
        ),
        child: Container(
          padding: EdgeInsets.all(30.0),
          child: Column(
            children: [
              Center(
                child: loading
                //if true - implement/display user interface for picking, capturing or live image,
                ? Container(
                  padding: EdgeInsets.only(top: 140.0),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(30.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                      )
                    ],
                  ),
                  child: Column(
                    children: [

                      SizedBox(height: 15.0,),

                      Container(

                        width: 250.0,
                        child: Image.asset("assets/camera.jpg"),
                      ),

                      SizedBox(height: 50.0,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          // live camera
                          SizedBox.fromSize(
                            size: Size(80, 80),
                            child: ClipOval(
                              child: Material(
                                color: Colors.orange,
                                child: InkWell(
                                  splashColor: Colors.green,
                                  onTap:()
                                  {
                                    print("clicked");
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=> CameraLive()));
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_front, size: 40,),
                                      Text("Live Camera", style: TextStyle(fontSize: 10.0),),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 4.0,),

                          // Pick image from gallery
                          SizedBox.fromSize(
                            size: Size(80, 80),
                            child: ClipOval(
                              child: Material(
                                color: Colors.orange,
                                child: InkWell(
                                  splashColor: Colors.green,
                                  onTap:()
                                  {
                                    pickImageFromGallery();
                                    print("clicked");
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo, size: 40,),
                                      Text("Gallery", style: TextStyle(fontSize: 10.0),),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 4.0,),

                          // Capture Image with Camera
                          SizedBox.fromSize(
                            size: Size(80, 80),
                            child: ClipOval(
                              child: Material(
                                color: Colors.orange,
                                child: InkWell(
                                  splashColor: Colors.green,
                                  onTap:()
                                  {
                                    captureImageWithCamera();
                                    print("clicked");
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt, size: 40,),
                                      Text("Camera", style: TextStyle(fontSize: 10.0),),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),

                      SizedBox(height: 20.0,)

                    ],
                  ),
                )

                // implement or display ui for showing results for which means captions according to img by playing Algo
                : Container(
                  color: Colors.black54,
                  padding: EdgeInsets.only(top: 30.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        height: 200.0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: IconButton(
                                onPressed: (){
                                  print("clicked");
                                  setState(() {
                                    resultText = "Fetching Result...";
                                    loading = true;
                                  });
                                },
                                icon: Icon(Icons.arrow_back_ios_outlined),
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width - 140,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Image.file(image!, fit: BoxFit.fill,),
                              ),
                            )
                          ],
                        ),
                      ),

                      SizedBox(height: 30.0,),

                      Container(
                        child: Text(
                          "Caption Prediction is: ",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.pink, fontSize: 24.0),
                        ),
                      ),

                      SizedBox(height: 30.0,),

                      Container(
                        child: Text(
                          resultText,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                      )

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<File>('image', image));
    properties.add(DiagnosticsProperty<File>('image', image));
    properties.add(DiagnosticsProperty<File>('image', image));
  }
}
 */

import 'dart:convert';
import 'dart:io';

import 'package:caption_generator/liveCamera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = true;
  File image = File('path/to/default/image.jpg');
  String resultText = "Fetching Result...";
  final pickerImage = ImagePicker();

  Future<Object?> getResponse(File imageFile) async {
    try {
      final typeData =
          lookupMimeType(imageFile?.path ?? "", headerBytes: [0xFF, 0xD8])
              ?.split("/");

      if (typeData == null) {
        print("Error: Unable to determine file type.");
        return null;
      }

      final imgUploadRequest = http.MultipartRequest(
        "POST",
        Uri.parse(
            "http://max-image-caption-generator-xamurani-dev.apps.sandbox-m2.ll9k.p1.openshiftapps.com/model/predict"),
      );

      final file = await http.MultipartFile.fromPath(
        "image",
        imageFile.path,
        contentType: MediaType(typeData[0], typeData[1]),
      );

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

  pickImageFromGallery() async {
    var imageFile = await pickerImage.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      setState(() {
        image = File(imageFile.path);
        loading = false;
      });
      await getResponse(image);
    }
  }

  captureImageWithCamera() async {
    var imageFile = await pickerImage.pickImage(source: ImageSource.camera);
    if (imageFile != null) {
      setState(() {
        image = File(imageFile.path);
        loading = false;
      });

      await getResponse(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_outlined),
          color: Colors.brown.shade200,
          onPressed: () {
            print("Back button clicked");
            setState(() {
              resultText = "Fetching Result...";
              loading = true;
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
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/jarvis.jpeg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: [
                Center(
                  child: loading
                      ? Container(
                          padding: const EdgeInsets.only(top: 10.0),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(30.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 15.0,
                              ),
                              Container(
                                width: 300.0,
                                height: 500.0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Image.asset(
                                    "assets/camera.jpg",
                                    fit: BoxFit.cover,
                                    color: const Color.fromRGBO(
                                        255, 255, 255, 0.5),
                                    colorBlendMode: BlendMode.modulate,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 30.0,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox.fromSize(
                                    size: Size(80, 80),
                                    child: ClipOval(
                                      child: Material(
                                        color: Colors.brown.shade600,
                                        child: InkWell(
                                          splashColor: Colors.brown.shade500,
                                          onTap: () {
                                            print("clicked");
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      CameraLive()),
                                            );
                                          },
                                          child: buildOptionButton(
                                              Icons.camera_front,
                                              "Live Camera"),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4.0),
                                  SizedBox.fromSize(
                                    size: Size(80, 80),
                                    child: ClipOval(
                                      child: Material(
                                        color: Colors.brown.shade600,
                                        child: InkWell(
                                          splashColor: Colors.brown.shade500,
                                          onTap: () {
                                            pickImageFromGallery();
                                            print("clicked");
                                          },
                                          child: buildOptionButton(
                                              Icons.photo, "Gallery"),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4.0),
                                  SizedBox.fromSize(
                                    size: Size(80, 80),
                                    child: ClipOval(
                                      child: Material(
                                        color: Colors.brown.shade600,
                                        child: InkWell(
                                          splashColor: Colors.brown.shade500,
                                          onTap: () {
                                            captureImageWithCamera();
                                            print("clicked");
                                          },
                                          child: buildOptionButton(
                                              Icons.camera_alt, "Camera"),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.0),
                            ],
                          ),
                        )
                      // gallery screen
                      : Container(
                          padding: EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(30.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                              ),
                            ],
                          ),
                          //padding: EdgeInsets.only(top: 30.0),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                height: 290.0,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /*IconButton(
                                      onPressed: () {
                                        print("clicked");
                                        setState(() {
                                          resultText = "Fetching Result...";
                                          loading = true;
                                        });
                                      },

                                      icon: const Icon(
                                          Icons.arrow_back_ios_outlined),
                                      color: Colors.white,
                                    ), */
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width -
                                          140,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        child: Image.file(
                                          image!,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              Container(
                                child: Text(
                                  'Prediction is: ',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.akronim(
                                    //caveat
                                    textStyle: TextStyle(
                                      color: Colors.brown.shade200,
                                      fontSize: 28.0,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          offset: const Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30.0),
                              Container(
                                child: Text(
                                  resultText,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.akronim(
                                    //caveat
                                    textStyle: TextStyle(
                                      color: Colors.brown.shade100,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.5),
                                          offset: const Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<File>('image', image));
    properties.add(DiagnosticsProperty<File>('image', image));
    properties.add(DiagnosticsProperty<File>('image', image));
  }

  Widget buildOptionButton(IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 40,
          color: Colors.brown.shade100,
        ),
        //Text(label, style: const TextStyle(fontSize: 10.0)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.akronim(
            //caveat
            textStyle: TextStyle(
              color: Colors.brown.shade100,
              fontSize: 10.0,
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
    );
  }
}
