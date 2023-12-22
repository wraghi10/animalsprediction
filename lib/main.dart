import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = true;
  File? _image; // Updated to allow null
  List<dynamic>? _outputs; // Updated to allow null
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future<void> pickImage() async {
    var image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _loading = true;
      _image = File(image.path);
    });
    classifyImage(_image!); // Non-null assertion as _image can be null
  }

  Future<void> classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      _loading = false;
      _outputs = output;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Animals Prediction'),
      ),
      body: _loading
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image == null
                      ? Container() // You might want to add content here
                      : Container(
                          child: _image != null ? Image.file(_image!) : Container(),
                          height: 500,
                          width: MediaQuery.of(context).size.width - 200,
                        ),
                  SizedBox(
                    height: 20,
                  ),
                  _outputs != null && _outputs!.isNotEmpty
                      ? Text(
                          "${_outputs![0]["label"]}"
                              .replaceAll(RegExp(r'[0-9]'), ''),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                            backgroundColor: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text("Please enter the image for prediction"),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add),
      ),
    );
  }
}
