import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import './redux/index.dart';
import './redux/playController/action.dart' as playController;

import './pages/Recommend/index.dart';
import './pages/Rank/index.dart';
import './pages/Search/index.dart';
import './pages/MySong/index.dart';

import './components/customBottomNavigationBar.dart';
import './components/toast.dart';
import './utils/tools.dart';

class MyApp extends StatefulWidget {
  final Store<AppState> store;
  MyApp(this.store);
  @override
  MyAppState createState() => new MyAppState(this.store);
}

// AutomaticKeepAliveClientMixin：keep tab pages alive
class MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  Store<AppState> store;
  MyAppState(this.store);
  TabController _tabController;
  List<Widget> _body = [new Recommend(), new CollectSongList(), new Rank()];
  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(length: 3, vsync: this)
      ..addListener(tabIndexChange);
    _tabController.animation.addListener(tabIndexChange);
    var playControllerState = this.store.state.playControllerState;
    playControllerState.audioPlayer.onAudioPositionChanged.listen((d) {
      Map progressMap = {};
      progressMap['type'] = playController.Actions.changeProgress;
      progressMap['payload'] = d;
      this.store.dispatch(progressMap);
      /*
      自动切换下一曲功能
      当前播放歌曲长度等于当前播放进度
      精确度：秒
      */
      if (stringDurationToDouble(d.toString().substring(2, 7)) == 
      stringDurationToDouble(playControllerState.duration.toString().substring(2, 7))) {
          this.store.dispatch(playController.playeNextSong);
        }  
    });
  }

  void tabIndexChange () {
    if (_tabController.indexIsChanging) {
      this.setState(() {
        tabIndex = _tabController.index;
      });
    }
  }

  List<Widget> createTabs (List<String> titles) {
    List<Widget> tabs = [];
    for (int i = 0;i < titles.length;i ++) {
      tabs.add(Text(
        titles[i],
        style: TextStyle(
          color: Colors.black87,
          fontWeight: tabIndex == i ? FontWeight.bold : FontWeight.normal,
          fontSize: tabIndex == i ? 14 : 13
        ),
        maxLines: 1
      ));
    }
    return tabs;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return StoreProvider(
        store: store,
        child: MaterialApp(
          title: 'Easy_Music',
          home: Scaffold(
              backgroundColor: Colors.white,
              // todo：left drawer content
              drawer: Drawer(
                child: Text('data'),
              ),
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: AppBar(
                  bottomOpacity: 1,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  leading: Builder(
                    builder: (BuildContext context) {
                      return IconButton(
                        icon: Icon(Icons.menu),
                        color: Colors.black54,
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    },
                  ),
                  title: Container(
                    margin: EdgeInsets.only(top: 3),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      tabs: createTabs(['发现音乐', '我的音乐', '排行榜'])
                    )
                  ),
                  actions: <Widget>[
                    SearchButton()
                  ],
                ),
              ),
              body: StoreConnector<AppState, dynamic>(
                  converter: (store) => store.state,
                  builder: (BuildContext context, state) {
                    return Stack(
                      children: <Widget>[
                        TabBarView(
                          controller: _tabController,
                          children: _body,
                        ),
                        state.commonState.isRequesting
                            ? Container(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                                color: Color.fromRGBO(0, 0, 0, 0.1),
                                child: SpinKitDoubleBounce(
                                  color: Colors.red[300],
                                ),
                              )
                            : Container(),
                        state.commonState.toastStatus
                            ? Toast(state.commonState.toastMessage)
                            : Container()
                      ],
                    );
                  }),
              bottomNavigationBar: CustomBottomNavigationBar()),
        ));
  }

  @override
  bool get wantKeepAlive => true;
}

class SearchButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: IconButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => Search()));
        },
        icon: Icon(
          Icons.search,
          size: 22,
          color: Colors.black54,
        )
      )
    );
  }
}
