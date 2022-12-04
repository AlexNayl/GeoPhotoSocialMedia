import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:group_project/constants.dart';

import 'package:geolocator/geolocator.dart';
import 'package:group_project/models/post.dart';
import 'package:group_project/models/post_model.dart';
import 'package:latlong2/latlong.dart';

class AddPost extends StatefulWidget {
  const AddPost({Key? key}) : super(key: key);

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  String? _title;
  String? _imageURL;
  String? _caption;

  PostModel _model = PostModel();

  @override
  Widget build(BuildContext context) {
    Geolocator.isLocationServiceEnabled().then((value) => null);
    Geolocator.requestPermission().then((value) => null);
    Geolocator.checkPermission().then((LocationPermission permission) {
      //print("Check Location Permission: $permission");
    });

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: "Title:"),
              style: TextStyle(fontSize: 30),
              onChanged: (post_title) {
                _title = post_title;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: "imageURL"),
              style: TextStyle(fontSize: 30),
              onChanged: (post_URL) {
                _imageURL = post_URL;
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: "Caption"),
              style: TextStyle(fontSize: 30),
              onChanged: (cap) {
                _caption = cap;
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addToDb,
        tooltip: "Add",
        child: const Icon(Icons.add),
      ),
    );
  }

  Future _addToDb() async {
    print("Adding a new entry...");
    Position pos = await Geolocator.getCurrentPosition();

    Post post_data = Post(
        title: _title,
        imageURL: _imageURL,
        location: LatLng(pos.latitude, pos.longitude),
        caption: _caption);
    await _model.insertPost(post_data);
  }
}
