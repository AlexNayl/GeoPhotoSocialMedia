import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:group_project/models/settings_model.dart';
import 'package:group_project/views/map_view.dart';
import 'package:group_project/views/post_data_view.dart';
import 'package:group_project/views/saved_post_view.dart';
import 'package:group_project/views/settings_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  static void setLanguage(BuildContext context, Locale newLocale) async {
    _HomePageState state =
    context.findAncestorStateOfType<_HomePageState>()!;
    state.setLanguage(newLocale);
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController();

  final SettingsModel _settingsModel = SettingsModel();

  int _page = 0;

  void setLanguage(Locale newLocale) {
    FlutterI18n.refresh(context, newLocale).then((value) => setState((){}));
  }

  Future<void> _createPost() async {
    await Navigator.pushNamed(context, "/addPost");
  }

  void navigate(int page) {
    if (page>=0 && page<=4) {
      //Make sure the page exists
      _page = page;
      _controller.animateToPage(
        _page,
        curve: Curves.decelerate,
        duration: const Duration(milliseconds: 500),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _settingsModel.getStringSetting(SettingsModel.settingLanguage)
        .then((value) {
          value??="en-US";
          List<String> lang = value!.split("-");
          setLanguage(Locale(lang[0],lang[1]));
        });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> pageNames = [
      FlutterI18n.translate(context, "map.page"),
      FlutterI18n.translate(context, "stats.page"),
      "", //Page 3 is empty (Just using button for add post)
      FlutterI18n.translate(context, "settings.page"),
      FlutterI18n.translate(context, "saved.page"),
    ];

    final List<Widget> pageIcons = [
      const Icon(Icons.map),
      const Icon(Icons.bar_chart),
      Container(),
      const Icon(Icons.settings),
      const Icon(Icons.bookmarks),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: pageIcons[_page],
        title: Text(pageNames[_page]),
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        controller: _controller,
        children: [
          const MapView(),
          const PostDataView(),
          Container(),
          const SettingsView(),
          const SavedPostView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _page,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: FlutterI18n.translate(context, "map.page"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: FlutterI18n.translate(context, "stats.page"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: FlutterI18n.translate(context, "add.page"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: FlutterI18n.translate(context, "settings.page"),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmarks_outlined),
            activeIcon: Icon(Icons.bookmarks),
            label: FlutterI18n.translate(context, "saved.page"),
          ),
        ],
        onTap: (value) {

            //Add post feature
            ///Important: Make sure this is equal to the index of the 'add' button.
            if (value==2) {
              //Temporarily jump to the empty "page 2" (setstate isn't sufficient to refresh the pageview)
                int temp = _page;
                _controller.jumpToPage(2);
                _createPost().then((value) => setState((){
                  _page = temp;
                  _controller.jumpToPage(temp);
                }));
            } else {
              //Navigate like normal
              setState((){
                navigate(value);
              });

            }
        },
      ),
    );
  }
}
