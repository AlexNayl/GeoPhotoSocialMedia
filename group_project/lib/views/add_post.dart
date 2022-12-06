import 'dart:math';

import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:group_project/camera/camera.dart';
import 'package:group_project/constants.dart';

import 'package:group_project/models/saved_model.dart';
import 'package:group_project/models/settings_model.dart';

import 'package:geolocator/geolocator.dart';
import 'package:group_project/models/post.dart';
import 'package:group_project/models/post_model.dart';
import 'package:latlong2/latlong.dart';

import 'dart:io';
import 'dart:async';

import "package:uuid/uuid.dart";

class AddPost extends StatefulWidget {
  const AddPost({Key? key}) : super(key: key);

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  String? _title;
  String? _imageURL;
  String? _caption;

  String? _imagePath;

  int? _dateTime;

  final _formKey = GlobalKey<FormState>();

  final PostModel _model = PostModel();
  final SavedModel _savedMode = SavedModel();
  final SettingsModel _settingsModel = SettingsModel();

  bool isBusy = false;

  @override
  void initState() {
    super.initState();

    takepic().then((value) {
      if (!value) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    Geolocator.isLocationServiceEnabled().then((value) => null);
    Geolocator.requestPermission().then((value) => null);
    Geolocator.checkPermission().then((value) => null);

    if (isBusy) {
      return Scaffold(
        appBar: AppBar(
          title: Text(FlutterI18n.translate(context, "add.page")),
        ),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 10,),
                Text(FlutterI18n.translate(context, "add.uploading"))
              ],
            )
        ),
      );

    }

    final double sizeToFit = min(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);



    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, "add.page")),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(30),
          children: [
            ElevatedButton(
                onPressed: takepic,
                child: Text(FlutterI18n.translate(context, "add.retakePhoto"))
            ),
            SizedBox(
                child: _imagePath != null
                    ? Image.file(File(_imagePath!), fit: BoxFit.scaleDown, width: sizeToFit, height: sizeToFit,)
                    : //Text("Yes pic"):
                Center(child: Text("Error: No photo?")) //Image.file(File(widget.imagePath!)),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: FlutterI18n.translate(context, "add.title")
                    ),
                    style: const TextStyle(fontSize: 24),
                    maxLength: 20,
                    validator: (value) {
                      if (value!=null) {
                        if (value.length<3) {
                          return FlutterI18n.translate(context, "add.titleTooShort");
                        }
                      }
                      return null;
                    },
                    onSaved: (value){
                      _title = value;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                        labelText: FlutterI18n.translate(context, "add.caption"),
                    ),
                    validator: (value) {
                      return null;
                    },
                    onSaved: (value){
                      _caption = value;
                    },
                  ),
                  const SizedBox(height: 30,),
                  ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _postButtonPress();
                        }

                      },
                      child: Text(FlutterI18n.translate(context, "add.upload")),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _postButtonPress() {
    _userConfirmation().then(
            (value) {
          if (value==true) {
            setState(() {
              isBusy=true;
              _addToDb().then((value) {
                if (value = true) { // snackbar to tell user the post is created
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                          FlutterI18n.translate(context, "add.uploadSuccess"),
                          style: const TextStyle(fontSize: 14),
                        )),
                  );
                  Navigator.of(context).pop();
                } else {
                  setState(() {
                    isBusy=false;
                  });
                }
              });
            });
          } else {
            //Do nothing
          }
        }
    );
  }

  Future<bool> _addToDb() async {
    print("Adding a new entry...");

    Position pos = await Geolocator.getCurrentPosition();
    final uuid = Uuid();
    _imageURL = await uploadPhoto(uuid.v1(), File(_imagePath!));
    if (_imageURL != null) {
      print("Image upload successful!");
      Post post_data = Post(
          title: _title,
          imageURL: _imageURL,
          dateTime: _dateTime,
          location: LatLng(pos.latitude, pos.longitude),
          caption: _caption);

      await _model.insertPost(post_data);

      var ref = await _model.insertPost(post_data);

      bool saveOnPost = await _settingsModel.getBoolSetting(SettingsModel.settingAutoSave)??true;
      if (saveOnPost) {
        post_data.reference = ref;
        await _savedMode.savePost(null, post_data);
      }

      return true;
    } else {
      print("Failed to upload image!");
      return false;
    }
  }

// this method is used to confirm information inputed by the user before creating the post
  Future<bool> _userConfirmation() async {
    bool confirmation = await showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text(FlutterI18n.translate(context, "add.postConfirm.title")),
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(FlutterI18n.translate(context, "add.postConfirm.text")),
              ),
              SimpleDialogOption(
                child: Text(FlutterI18n.translate(context, "add.postConfirm.yes")),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              SimpleDialogOption(
                child: Text(FlutterI18n.translate(context, "add.postConfirm.no")),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          );
        });
    print("User confirmation of post: $confirmation");

    return confirmation;
  }

  Future<String?> uploadPhoto(String name, File file) async {
    final storageRef = FirebaseStorage.instance.ref();
    final photoRef = storageRef.child("images/$name.jpg");

    try {
      await photoRef.putFile(file);

      return photoRef.getDownloadURL();
    } catch (e) {
      print(e);
    }
  }

  Future<bool> takepic() async {
    WidgetsFlutterBinding.ensureInitialized();
    //get a list of all cameras on the device
    final cameras = await availableCameras();

    _dateTime = DateTime.now().millisecondsSinceEpoch;

    var result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
            return Camera(cameras: cameras);
          }
        ),
    );

    if (result != null && result is String) {
      setState(() {
        _imagePath = result;
      });
      return true;
    }

    if (_imagePath==null) {
      return false;
    }

    return true;

  }
}
