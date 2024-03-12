import 'dart:convert';
import 'dart:io';
import 'package:cameraai/api_key.dart';
import 'package:cameraai/splash%20screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_model.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Splashscreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController cameraController;
  late CameraImage? imagescam;
  final FlutterTts flutter = FlutterTts();
  final TextEditingController controller = TextEditingController();
  File? image;
  List<ChatModel> chatlist = [];
  bool isWorking = false;
  String result = '';
  bool showCameraPreview = false;

  speak(String text) async {
    await flutter.setLanguage("en-US");
    await flutter.setPitch(1); // 0.5 to 1.5
    await flutter.speak(text);
  }

  @override
  void initState() {
    super.initState();
    if (cameras != null && cameras!.isNotEmpty) {
      cameraController =
          CameraController(cameras![0], ResolutionPreset.medium);
      cameraController.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  // void onSendMessage() async {
  //   // Your existing code
  // }

  Future<void> takePicture() async {
    try {
      final XFile? picture = await cameraController.takePicture();
      if (picture != null) {
        setState(() {
          image = File(picture.path);
        });
      }
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  void toggleCameraPreview() {
    setState(() {
      showCameraPreview = !showCameraPreview;
    });
  }


  Future<void> startVideoRecording() async {
    try {
      final XFile? video =  await cameraController.startVideoRecording() as XFile?;
      print("Video recording started: ${video?.path}");
    } catch (e) {
      print("Error starting video recording: $e");
    }
  }

  Future<void> stopVideoRecording() async {
    try {
      final XFile? video = await cameraController.stopVideoRecording();
      print("Video recording stopped: ${video?.path}");
    } catch (e) {
      print("Error stopping video recording: $e");
    }
  }

  void onSendmassage() async {
    ChatModel model;

    if (image == null) {
      model = ChatModel(isme: true, massage: controller.text);
    } else {
      final imagebytes = await image!.readAsBytes();
      String base64En = base64Encode(imagebytes);
      model = ChatModel(
        isme: true,
        massage: controller.text,
        base64EncodedImage: base64En,
      );
    }

    chatlist.insert(0, model);

    // Update UI to show the message you sent
    setState(() {});

    final geminiw = await sendrquesttogemini(model);

    // Display each line of the bot's response with a delay
    for (final line in geminiw.massage.split('\n')) {
      final botReply = ChatModel(isme: false, massage: line);
      chatlist.insert(0, botReply);
      // Update UI to show the bot's reply
      setState(() {});
      // Introduce a delay between displaying each line of the bot's response
      await Future.delayed(Duration(seconds: 1));
    }

    // Clear the selected image after sending the message
    setState(() {
      image = null;
    });
  }



  void selectimage() async {
    final picker = await ImagePicker.platform.getImage(source: ImageSource.gallery);

    if (picker != null) {
      setState(() {
        image = File(picker.path);
      });
    }
  }

  Future<ChatModel> sendrquesttogemini(ChatModel model) async {
    String Url = "";
    Map<String, dynamic> body = {};

    if (model.base64EncodedImage == null) {
      Url =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${Geminikey.api_key}";
      body = {
        "contents": [
          {
            "parts": [
              {"text": model.massage},
            ],
          },
        ],
      };
    } else {
      Url =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=${Geminikey.api_key}";

      body = {
        "contents": [
          {
            "parts": [
              {"text": model.massage},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": model.base64EncodedImage,
                }
              }
            ],
          },
        ],
      };
    }

    Uri uri = Uri.parse(Url);
    final result = await http.post(uri,
        headers: {"Content-Type": "application/json"}, body: json.encode(body));

    print(result.body);
    print(result.statusCode);

    final decodeJson = json.decode(result.body);

    String massage = '';

    if (decodeJson != null &&
        decodeJson['candidates'] != null &&
        decodeJson['candidates'].isNotEmpty &&
        decodeJson['candidates'][0]['content'] != null &&
        decodeJson['candidates'][0]['content']['parts'] != null &&
        decodeJson['candidates'][0]['content']['parts'].isNotEmpty &&
        decodeJson['candidates'][0]['content']['parts'][0]['text'] != null) {
      massage = decodeJson['candidates'][0]['content']['parts'][0]['text'];
    } else {
      massage = "Message not found"; // Or any default message you want to set
    }

    ChatModel geminiw = ChatModel(isme: false, massage: massage);
    return geminiw;
  }


  void saveChat() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(),
      body: Column(
        children: [
          if (showCameraPreview)
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (cameraController.value.isInitialized)
                  CameraPreview(cameraController),
                // Add other widgets on top of the camera preview if needed
              ],
            ),
          ),
          if (image != null) Image.file(image!),
          Expanded(
            child: Visibility(
              visible: showCameraPreview,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Adjust alignment as needed
                children: [
                  SizedBox(
                    child: ElevatedButton(
                      onPressed: takePicture,
                      child: Text("Take Picture"),
                    ),
                  ),
                  SizedBox(
                    child: ElevatedButton(
                      onPressed: startVideoRecording,
                      child: Text('start Recording'),
                    ),
                  ),
                  SizedBox(
                    child: ElevatedButton(
                      onPressed: stopVideoRecording,// Add functionality for video recording
                      child: Text('Stop Recodring'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: chatlist.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(chatlist[index].isme ? 'ME' : 'boys'),
                  subtitle: Column(
                    crossAxisAlignment: chatlist[index].isme
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (chatlist[index].base64EncodedImage != null)
                        Image.memory(
                          base64Decode(chatlist[index].base64EncodedImage!),
                          height: 150, // Adjust the height as needed
                        ),
                      Text(chatlist[index].massage),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 10,
          ),
          if (image != null)
            Image.file(
              image!,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    selectimage();
                  },
                  icon: Icon(Icons.upload_file),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      prefixIcon: IconButton(onPressed: () => toggleCameraPreview(), icon: Icon(Icons.camera),),
                      suffixIcon: IconButton(
                        onPressed: () => speak(controller.text),
                        icon: Icon(Icons.speaker),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    try {
                      if (controller.text.isNotEmpty) {
                        onSendmassage();
                        controller.text = '';
                      }
                    } catch (e) {
                      print("Error sending message: $e");
                    }
                  },
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10,
          )
        ],
      ),
    );
  }
}
