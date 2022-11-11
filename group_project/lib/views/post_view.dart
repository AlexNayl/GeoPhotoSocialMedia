import 'package:flutter/material.dart';
import 'package:group_project/models/db_utils.dart';

import 'package:group_project/models/post_model.dart';
import 'package:group_project/models/post.dart';
import 'package:group_project/models/saved_model.dart';

class PostView extends StatefulWidget {
  const PostView({Key? key}) : super(key: key);

  @override
  State<PostView> createState() => _PostViewState();
}

class _PostViewState extends State<PostView> {
  final PostModel _postModel = PostModel();
  final SavedModel _savedModel = SavedModel();

  Widget _buildCaptionBox(String? caption) {
    if (caption==null) {
      return Container();
    }
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Text(caption),
      ),
    );
  }

  Widget _buildPost(Post post) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(16.0)),
            child: Image.network(post.imageURL!),
          ),
        ),
        _buildCaptionBox(post.caption!),
      ],
    );
  }

  Future<Map<String, dynamic>> _getPostInfo() async {
    List<Post> allposts = await _postModel.getAllPostsList();
    Post post = allposts[0];
    bool saved = await _savedModel.isPostSaved(null, post.reference!.id);
    bool hidden = await _savedModel.isPostHidden(null, post.reference!.id);
    return {
      'post': post,
      'saved': saved,
      'hidden': hidden,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getPostInfo(),
        builder: (context, snapshot) {
          //If the post hasn't loaded yet...
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.data!.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("No posts found"),
              ),
            );
          }


          //Otherwise, if the post has loaded:

          //Grab the post data
          Post post = snapshot.data!['post'];
          bool hidden = snapshot.data!['hidden'];
          bool saved = snapshot.data!['saved'];

          IconData hideIcon = Icons.visibility_off_outlined;
          if (hidden) {
            hideIcon = Icons.visibility_off;
          }

          IconData saveIcon = Icons.bookmark_border;
          if (saved) {
            saveIcon = Icons.bookmark;
          }

          List<Widget> postActions = [];
          if (!hidden) {
            postActions.add(
              IconButton(
                  onPressed: (){
                    setState(() {
                      if (saved) {
                        _savedModel.unsavePost(null, post);
                      } else {
                        _savedModel.savePost(null, post);
                      }
                    });
                  },
                  tooltip: "Save Post",
                  icon: Icon(saveIcon)
              ),
            );
          }

          postActions.add(
              IconButton(
                onPressed: () {
                  setState(() {
                    if (hidden) {
                      _savedModel.unsavePost(null, post);
                    } else {
                      _savedModel.hidePost(null, post);
                    }
                  });
                },
                tooltip: "Hide Post",
                icon: Icon(hideIcon),
              )
          );

          return Scaffold(
            appBar: AppBar(
              title: Text(post.title!),
              actions: postActions,
            ),
            body: _buildPost(post),
          );
        },
    );
  }
}
