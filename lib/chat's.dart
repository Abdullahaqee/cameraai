// import 'dart:io';
// import 'package:flutter/material.dart';
//
// class chat extends StatefulWidget{
//   @override
//   State<chat> createState() => _chatState();
// }
//
// class _chatState extends State<chat> {
//
//
//   final TextEditingController controller = TextEditingController();
//   File? image;
//
//   void onSendmassage() {}
//
//   void selectimage() async {}
//
//   @override
//   Widget build(BuildContext context) {
//    return Scaffold(
//     appBar: AppBar(),
//      body: Column(
//        children: [
//          Expanded(child: ListView())
//        ],
//      ),
//    );
//   }
// }
// Container(
// margin: EdgeInsets.only(top: 35),
// width: 350,
// height: 350,
// child: imagescam == null
// ? Container(
// height: 270,
// width: 360,
// child: Icon(Icons.photo_camera_front),
// color: Colors.blueAccent,
// )
//     : AspectRatio(
// aspectRatio:
// cameraController.value.aspectRatio,
// child: CameraPreview(cameraController),
// ),
// ),